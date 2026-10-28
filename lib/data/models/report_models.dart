/// Model hasil proses checkout.
class TransactionResult {
  final int transactionId;
  final String transactionNumber;
  final double totalAmount;
  final double changeAmount;

  const TransactionResult({
    required this.transactionId,
    required this.transactionNumber,
    required this.totalAmount,
    required this.changeAmount,
  });
}

/// Ringkasan laporan harian.
class DailyReport {
  final DateTime date;
  final double totalRevenue;
  final double totalDiscount;
  final double totalTax;
  final double netProfit;
  final int transactionCount;
  final double averageTransactionValue;

  const DailyReport({
    required this.date,
    required this.totalRevenue,
    required this.totalDiscount,
    required this.totalTax,
    required this.netProfit,
    required this.transactionCount,
    required this.averageTransactionValue,
  });

  factory DailyReport.empty(DateTime date) => DailyReport(
        date: date,
        totalRevenue: 0,
        totalDiscount: 0,
        totalTax: 0,
        netProfit: 0,
        transactionCount: 0,
        averageTransactionValue: 0,
      );
}

/// Produk terlaris.
class TopProduct {
  final int productId;
  final String name;
  final String? barcode;
  final int totalSold;
  final double totalRevenue;
  final double totalProfit;

  const TopProduct({
    required this.productId,
    required this.name,
    this.barcode,
    required this.totalSold,
    required this.totalRevenue,
    required this.totalProfit,
  });
}

/// Penjualan per kategori.
class CategorySales {
  final String categoryName;
  final int totalSold;
  final double totalRevenue;

  const CategorySales({
    required this.categoryName,
    required this.totalSold,
    required this.totalRevenue,
  });
}
