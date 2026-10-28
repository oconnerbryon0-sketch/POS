import 'package:drift/drift.dart';

import '../../core/utils/transaction_helper.dart';
import '../database/app_database.dart';
import '../models/cart_item.dart';
import '../models/report_models.dart';

class TransactionRepository {
  final AppDatabase _db;
  final TransactionDao _transactionDao;
  final StockDao _stockDao;

  TransactionRepository(this._db, this._transactionDao, this._stockDao);

  /// Proses checkout: membuat transaksi + kurangi stok secara ATOMIC.
  ///
  /// Seluruh operasi dijalankan dalam satu SQLite transaction sehingga
  /// jika ada item yang gagal (stok tidak cukup), SEMUA di-rollback.
  Future<TransactionResult> processCheckout({
    required List<CartItem> items,
    required int paymentMethodId,
    required double amountPaid,
    double taxRate = 0.11,
    int discountType = 0, // 0=none, 1=percentage, 2=fixed
    double discountValue = 0,
    String? notes,
  }) async {
    return _db.transaction(() async {
      if (items.isEmpty) {
        throw StateError('Keranjang kosong');
      }

      final transactionNumber = TransactionHelper.generateNumber(null);

      // Hitung total
      final subtotal = items.fold<double>(0, (s, i) => s + i.subtotal);
      double discountAmount = 0;
      if (discountType == 1) {
        discountAmount = subtotal * (discountValue / 100);
      } else if (discountType == 2) {
        discountAmount = discountValue;
      }
      final discountedSubtotal = subtotal - discountAmount;
      final taxAmount = discountedSubtotal * taxRate;
      final totalAmount = discountedSubtotal + taxAmount;

      // Insert transaksi
      final transactionId =
          await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
        transactionNumber: transactionNumber,
        subtotal: Value(subtotal.round()),
        taxAmount: Value(taxAmount.round()),
        discountAmount: Value(discountAmount.round()),
        totalAmount: Value(totalAmount.round()),
        paymentMethodId: Value(paymentMethodId),
        amountPaid: Value(amountPaid.round()),
        changeAmount: Value((amountPaid - totalAmount).round()),
        status: const Value('completed'),
        notes: Value(notes),
      ));

      // Insert items + kurangi stok atomic
      for (final item in items) {
        await _db.into(_db.transactionItems).insert(
              TransactionItemsCompanion.insert(
                transactionId: transactionId,
                productId: item.productId,
                quantity: item.quantity,
                unitPrice: item.unitPrice.round(),
                costPrice: item.costPrice.round(),
                discountType: Value(_discountTypeToString(item.discountType)),
                discountValue: Value(item.discountValue.round()),
                subtotal: item.finalSubtotal.round(),
              ),
            );

        await _stockDao.deductStockAtomic(
          productId: item.productId,
          quantity: item.quantity,
          transactionId: transactionId,
        );
      }

      // Enqueue sync record (future cloud sync)
      await _db.into(_db.syncQueues).insert(SyncQueuesCompanion.insert(
            entityType: 'transaction',
            entityId: transactionId,
            actionType: 'create',
            payload: Value('{"transactionNumber":"$transactionNumber"}'),
          ));

      return TransactionResult(
        transactionId: transactionId,
        transactionNumber: transactionNumber,
        totalAmount: totalAmount,
        changeAmount: amountPaid - totalAmount,
      );
    });
  }

  Future<Transaction?> getById(int id) => _transactionDao.getTransactionById(id);

  Stream<List<Transaction>> watchRecent({int limit = 50}) =>
      _transactionDao.watchRecentTransactions(limit: limit);

  Future<List<TransactionItem>> getItems(int transactionId) =>
      _transactionDao.getItemsForTransaction(transactionId);

  Future<List<Transaction>> getBetween(DateTime start, DateTime end) =>
      _transactionDao.getTransactionsBetween(start, end);

  /// Membatalkan transaksi (void): ubah status jadi 'cancelled' dan
  /// kembalikan stok setiap item secara ATOMIC (semua atau batal).
  ///
  /// Hanya bisa membatalkan transaksi yang belum dibatalkan.
  Future<void> voidTransaction(int transactionId, {String? reason}) async {
    await _db.transaction(() async {
      final tx = await _transactionDao.getTransactionById(transactionId);
      if (tx == null) {
        throw StateError('Transaksi tidak ditemukan');
      }
      if (tx.status == 'cancelled') {
        throw StateError('Transaksi sudah dibatalkan');
      }

      // Ubah status
      await (_db.update(_db.transactions)..where((t) => t.id.equals(transactionId)))
          .write(TransactionsCompanion(
        status: const Value('cancelled'),
        notes: Value(reason ?? 'Transaksi dibatalkan'),
        updatedAt: Value(DateTime.now()),
      ));

      // Kembalikan stok per item secara atomic
      final items = await _transactionDao.getItemsForTransaction(transactionId);
      for (final item in items) {
        await _stockDao.restoreStockAtomic(
          productId: item.productId,
          quantity: item.quantity,
          referenceId: transactionId,
          reason: reason ?? 'Void transaksi',
        );
      }

      // Enqueue sync record
      await _db.into(_db.syncQueues).insert(SyncQueuesCompanion.insert(
            entityType: 'transaction',
            entityId: transactionId,
            actionType: 'void',
          ));
    });
  }

  String _discountTypeToString(int type) {
    switch (type) {
      case 1:
        return 'percentage';
      case 2:
        return 'fixed';
      default:
        return 'none';
    }
  }
}
