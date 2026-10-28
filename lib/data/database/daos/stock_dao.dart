part of '../app_database.dart';

/// Exception untuk masalah stok.
class StockException implements Exception {
  final String message;
  StockException(this.message);
  @override
  String toString() => 'StockException: $message';
}

class InsufficientStockException extends StockException {
  InsufficientStockException(super.message);
}

/// Request pengurangan stok untuk satu produk.
class StockDeductionRequest {
  final int productId;
  final int quantity;
  const StockDeductionRequest({
    required this.productId,
    required this.quantity,
  });
}

@DriftAccessor(tables: [Products, StockLogs])
class StockDao extends DatabaseAccessor<AppDatabase> with _$StockDaoMixin {
  StockDao(super.db);

  /// Mengurangi stok produk secara ATOMIC (dalam satu SQLite transaction).
  ///
  /// Alur:
  /// 1. SELECT produk dalam transaction (pessimistic lock)
  /// 2. Validasi stok cukup
  /// 3. UPDATE stok (decrement)
  /// 4. INSERT stock_log (audit trail)
  ///
  /// Jika ada error, seluruh transaction di-rollback.
  Future<bool> deductStockAtomic({
    required int productId,
    required int quantity,
    required int transactionId,
  }) async {
    return transaction(() async {
      final product = await (select(products)
            ..where((p) => p.id.equals(productId))
            ..limit(1))
          .getSingleOrNull();

      if (product == null) {
        throw StockException('Produk tidak ditemukan: ID $productId');
      }

      if (product.stockQuantity < quantity) {
        throw InsufficientStockException(
          'Stok tidak cukup untuk ${product.name}. '
          'Tersedia: ${product.stockQuantity}, Dibutuhkan: $quantity',
        );
      }

      final previousStock = product.stockQuantity;
      final newStock = previousStock - quantity;

      await (update(products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(
          stockQuantity: Value(newStock),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await into(stockLogs).insert(StockLogsCompanion.insert(
        productId: productId,
        changeType: 'sale',
        quantityChange: -quantity,
        previousStock: previousStock,
        newStock: newStock,
        referenceId: Value(transactionId),
        referenceType: const Value('transaction'),
        notes: Value('Penjualan - Transaksi #$transactionId'),
        createdAt: Value(DateTime.now()),
      ));

      return true;
    });
  }

  /// Mengembalikan stok (untuk pembatalan transaksi) secara atomic.
  Future<bool> restoreStockAtomic({
    required int productId,
    required int quantity,
    required int referenceId,
    String? reason,
  }) {
    return transaction(() async {
      final product = await (select(products)
            ..where((p) => p.id.equals(productId))
            ..limit(1))
          .getSingleOrNull();
      if (product == null) {
        throw StockException('Produk tidak ditemukan: ID $productId');
      }

      final previousStock = product.stockQuantity;
      final newStock = previousStock + quantity;

      await (update(products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(
          stockQuantity: Value(newStock),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await into(stockLogs).insert(StockLogsCompanion.insert(
        productId: productId,
        changeType: 'return',
        quantityChange: quantity,
        previousStock: previousStock,
        newStock: newStock,
        referenceId: Value(referenceId),
        referenceType: const Value('transaction'),
        notes: Value(reason ?? 'Pengembalian stok'),
        createdAt: Value(DateTime.now()),
      ));

      return true;
    });
  }

  /// Bulk stock deduction untuk checkout multi-item.
  /// Semua item harus berhasil, atau SEMUA di-rollback.
  Future<void> bulkDeductStock({
    required List<StockDeductionRequest> items,
    required int transactionId,
  }) {
    return transaction(() async {
      for (final item in items) {
        await deductStockAtomic(
          productId: item.productId,
          quantity: item.quantity,
          transactionId: transactionId,
        );
      }
    });
  }

  /// Penyesuaian stok manual (stok opname / restock).
  Future<void> adjustStock({
    required int productId,
    required int newStock,
    required String changeType,
    String? notes,
  }) async {
    await transaction(() async {
      final product = await (select(products)
            ..where((p) => p.id.equals(productId))
            ..limit(1))
          .getSingleOrNull();
      if (product == null) {
        throw StockException('Produk tidak ditemukan: ID $productId');
      }

      final currentStock = product.stockQuantity;
      final delta = newStock - currentStock;

      await (update(products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(
          stockQuantity: Value(newStock),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await into(stockLogs).insert(StockLogsCompanion.insert(
        productId: productId,
        changeType: changeType,
        quantityChange: delta,
        previousStock: currentStock,
        newStock: newStock,
        referenceType: const Value('manual_adjustment'),
        notes: Value(notes ?? 'Penyesuaian manual'),
        createdAt: Value(DateTime.now()),
      ));
    });
  }

  /// Riwayat stok untuk satu produk.
  Future<List<StockLog>> getStockHistory(int productId, {int limit = 100}) {
    return (select(stockLogs)
          ..where((l) => l.productId.equals(productId))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
          ..limit(limit))
        .get();
  }
}
