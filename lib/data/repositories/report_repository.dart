import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/report_models.dart';

class ReportRepository {
  final AppDatabase _db;
  final TransactionDao _transactionDao;

  ReportRepository(this._db, this._transactionDao);

  /// Laporan omzet/profit harian.
  Future<DailyReport> getDailyReport(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final txs = await _transactionDao.getTransactionsBetween(
      startOfDay,
      endOfDay,
    );
    if (txs.isEmpty) {
      return DailyReport.empty(date);
    }

    final totalRevenue =
        txs.fold<double>(0, (s, t) => s + t.totalAmount);
    final totalDiscount =
        txs.fold<double>(0, (s, t) => s + t.discountAmount);
    final totalTax = txs.fold<double>(0, (s, t) => s + t.taxAmount);

    // Hitung profit bersih dari items
    double totalCost = 0;
    double grossRevenue = 0;
    for (final tx in txs) {
      final items = await _transactionDao.getItemsForTransaction(tx.id);
      for (final item in items) {
        totalCost += item.costPrice * item.quantity;
        grossRevenue += item.subtotal;
      }
    }
    final netProfit = grossRevenue - totalCost - totalDiscount;

    return DailyReport(
      date: date,
      totalRevenue: totalRevenue,
      totalDiscount: totalDiscount,
      totalTax: totalTax,
      netProfit: netProfit,
      transactionCount: txs.length,
      averageTransactionValue:
          txs.isNotEmpty ? totalRevenue / txs.length : 0,
    );
  }

  /// Produk terlaris dalam rentang waktu.
  Future<List<TopProduct>> getTopProducts({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    final rows = await _db.customSelect(
      'SELECT '
      '  p.id as product_id, '
      '  p.name as product_name, '
      '  p.barcode as product_barcode, '
      '  SUM(ti.quantity) as total_sold, '
      '  SUM(ti.subtotal) as total_revenue, '
      '  SUM((ti.unit_price - ti.cost_price) * ti.quantity) as total_profit '
      'FROM transaction_items ti '
      'JOIN products p ON ti.product_id = p.id '
      'JOIN transactions t ON ti.transaction_id = t.id '
      'WHERE t.created_at >= :start AND t.created_at < :end '
      'AND t.status = :status '
      'GROUP BY p.id '
      'ORDER BY total_sold DESC '
      'LIMIT :limit',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
        Variable.withString('completed'),
        Variable.withInt(limit),
      ],
      readsFrom: {_db.transactionItems, _db.products, _db.transactions},
    ).get();

    return rows
        .map((r) => TopProduct(
              productId: r.read<int>('product_id'),
              name: r.read<String>('product_name'),
              barcode: r.read<String?>('product_barcode'),
              totalSold: r.read<int>('total_sold'),
              totalRevenue: r.read<int>('total_revenue').toDouble(),
              totalProfit: r.read<int>('total_profit').toDouble(),
            ))
        .toList();
  }

  /// Penjualan per kategori.
  Future<List<CategorySales>> getCategorySales({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    final rows = await _db.customSelect(
      'SELECT '
      '  c.name as category_name, '
      '  SUM(ti.quantity) as total_sold, '
      '  SUM(ti.subtotal) as total_revenue '
      'FROM transaction_items ti '
      'JOIN products p ON ti.product_id = p.id '
      'JOIN categories c ON p.category_id = c.id '
      'JOIN transactions t ON ti.transaction_id = t.id '
      'WHERE t.created_at >= :start AND t.created_at < :end '
      'AND t.status = :status '
      'GROUP BY c.id '
      'ORDER BY total_revenue DESC',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
        Variable.withString('completed'),
      ],
      readsFrom: {
        _db.transactionItems,
        _db.products,
        _db.categories,
        _db.transactions,
      },
    ).get();

    return rows
        .map((r) => CategorySales(
              categoryName: r.read<String>('category_name'),
              totalSold: r.read<int>('total_sold'),
              totalRevenue: r.read<int>('total_revenue').toDouble(),
            ))
        .toList();
  }

  /// Daftar metode pembayaran aktif.
  Future<List<PaymentMethod>> getPaymentMethods() async {
    final query = _db.select(_db.paymentMethods)
      ..where((m) => m.isActive.equals(true))
      ..orderBy([(m) => OrderingTerm.asc(m.sortOrder)]);
    return query.get();
  }
}
