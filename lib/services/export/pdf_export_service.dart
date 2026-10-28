import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/report_models.dart';

class PdfExportService {
  PdfExportService._();

  static Future<File> exportSalesReport({
    required DailyReport report,
    required List<TopProduct> topProducts,
    required String storeName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Center(
            child: pw.Text(storeName,
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text('LAPORAN PENJUALAN HARIAN',
                style: const pw.TextStyle(fontSize: 16)),
          ),
          pw.Center(
            child: pw.Text(DateFormatter.formatDate(report.date),
                style:
                    const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
          ),
          pw.SizedBox(height: 20),

          _summaryCard(report),
          pw.SizedBox(height: 24),

          pw.Text('10 PRODUK TERLARIS',
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            headers: ['Produk', 'Terjual', 'Omzet', 'Profit'],
            data: topProducts
                .map((p) => [
                      p.name,
                      '${p.totalSold}',
                      CurrencyFormatter.format(p.totalRevenue),
                      CurrencyFormatter.format(p.totalProfit),
                    ])
                .toList(),
          ),

          pw.SizedBox(height: 40),
          pw.Center(
            child: pw.Text(
              'Dicetak: ${DateFormatter.formatDateTime(DateTime.now())}',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ),
        ],
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final file = File(
        '${output.path}/laporan_penjualan_${DateFormatter.fileSafeDate(report.date)}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _summaryCard(DailyReport r) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('RINGKASAN',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          _row('Total Transaksi', '${r.transactionCount} transaksi'),
          _row('Total Omzet', CurrencyFormatter.format(r.totalRevenue)),
          _row('Total Diskon', CurrencyFormatter.format(r.totalDiscount)),
          _row('Total PPN', CurrencyFormatter.format(r.totalTax)),
          pw.Divider(color: PdfColors.blue200),
          _row('Rata-rata/Transaksi',
              CurrencyFormatter.format(r.averageTransactionValue)),
          _row('Profit Bersih', CurrencyFormatter.format(r.netProfit),
              bold: true),
        ],
      ),
    );
  }

  static pw.Widget _row(String label, String value, {bool bold = false}) {
    final style =
        bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }
}
