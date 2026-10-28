import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/report_models.dart';

class ExcelExportService {
  ExcelExportService._();

  static Future<File> exportSalesReport({
    required DailyReport report,
    required List<TopProduct> topProducts,
    required List<CategorySales> categorySales,
    required String storeName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Laporan Penjualan'];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      fontSize: 12,
    );

    var row = 0;

    // Judul
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue(storeName)
      ..cellStyle = CellStyle(bold: true, fontSize: 16);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row),
    );
    row++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue(
          'Laporan Penjualan - ${DateFormatter.formatDate(report.date)}')
      ..cellStyle = CellStyle(fontSize: 11);
    row += 2;

    // Ringkasan
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('RINGKASAN')
      ..cellStyle = CellStyle(bold: true, fontSize: 12);
    row++;

    final summary = {
      'Total Transaksi': '${report.transactionCount}',
      'Total Omzet': CurrencyFormatter.format(report.totalRevenue),
      'Total Diskon': CurrencyFormatter.format(report.totalDiscount),
      'Total PPN': CurrencyFormatter.format(report.totalTax),
      'Profit Bersih': CurrencyFormatter.format(report.netProfit),
      'Rata-rata / Transaksi':
          CurrencyFormatter.format(report.averageTransactionValue),
    };
    summary.forEach((k, v) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        ..value = TextCellValue(k);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
        ..value = TextCellValue(v);
      row++;
    });
    row++;

    _writeTable(
      sheet,
      startRow: row,
      title: '10 PRODUK TERLARIS',
      headers: ['No', 'Nama Produk', 'Barcode', 'Terjual', 'Omzet', 'Profit'],
      rows: topProducts
          .map((p) => [
                IntCellValue(topProducts.indexOf(p) + 1),
                TextCellValue(p.name),
                TextCellValue(p.barcode ?? '-'),
                IntCellValue(p.totalSold),
                TextCellValue(CurrencyFormatter.format(p.totalRevenue)),
                TextCellValue(CurrencyFormatter.format(p.totalProfit)),
              ])
          .toList(),
      headerStyle: headerStyle,
    );

    // Kategori
    row += topProducts.length + 4;
    _writeTable(
      sheet,
      startRow: row,
      title: 'PENJUALAN PER KATEGORI',
      headers: ['Kategori', 'Total Terjual', 'Total Omzet'],
      rows: categorySales
          .map((c) => [
                TextCellValue(c.categoryName),
                IntCellValue(c.totalSold),
                TextCellValue(CurrencyFormatter.format(c.totalRevenue)),
              ])
          .toList(),
      headerStyle: headerStyle,
    );

    sheet.setColumnWidth(0, 20);
    sheet.setColumnWidth(1, 30);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 12);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 18);

    final output = await getApplicationDocumentsDirectory();
    final file = File(
        '${output.path}/laporan_penjualan_${DateFormatter.fileSafeDate(report.date)}.xlsx');
    final List<int>? fileBytes = excel.save(fileName: file.path.split('\\').last);
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
    }
    return file;
  }

  static void _writeTable(
    Sheet sheet, {
    required int startRow,
    required String title,
    required List<String> headers,
    required List<List<CellValue?>> rows,
    required CellStyle headerStyle,
  }) {
    var row = startRow;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue(title)
      ..cellStyle = CellStyle(bold: true, fontSize: 12);
    row++;

    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
        ..value = TextCellValue(headers[i])
        ..cellStyle = headerStyle;
    }
    row++;

    for (final data in rows) {
      for (int i = 0; i < data.length; i++) {
        sheet.cell(
                CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
            .value = data[i];
      }
      row++;
    }
  }
}
