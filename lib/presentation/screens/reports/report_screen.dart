import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/report_provider.dart';
import '../../../services/export/excel_export_service.dart';
import '../../../services/export/file_export_helper.dart';
import '../../../services/export/pdf_export_service.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  bool _isExporting = false;

  Future<void> _exportPdf() async {
    final reportRepo = ref.read(reportRepositoryProvider);
    final report = await reportRepo.getDailyReport(DateTime.now());
    final top = await reportRepo.getTopProducts(limit: 10);

    setState(() => _isExporting = true);
    try {
      final file = await PdfExportService.exportSalesReport(
        report: report,
        topProducts: top,
        storeName: AppStrings.appName,
      );
      _showExportResult('PDF berhasil dibuat', file.path, file: file);
    } catch (e) {
      _showExportError(e);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportExcel() async {
    final reportRepo = ref.read(reportRepositoryProvider);
    final report = await reportRepo.getDailyReport(DateTime.now());
    final top = await reportRepo.getTopProducts(limit: 10);
    final cats = await reportRepo.getCategorySales();

    setState(() => _isExporting = true);
    try {
      final file = await ExcelExportService.exportSalesReport(
        report: report,
        topProducts: top,
        categorySales: cats,
        storeName: AppStrings.appName,
      );
      _showExportResult('Excel berhasil dibuat', file.path, file: file);
    } catch (e) {
      _showExportError(e);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showExportResult(String message, String path, {dynamic file}) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 48),
              const SizedBox(height: 12),
              Text(message,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(path,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (file != null) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Buka'),
                      onPressed: () => FileExportHelper.openFile(file),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Bagikan'),
                      onPressed: () => FileExportHelper.shareFile(file),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export gagal: $e'), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(dailyReportProvider);
    final topAsync = ref.watch(topProductsProvider);
    final catAsync = ref.watch(categorySalesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.danger),
            onPressed: _isExporting ? null : _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.grid_on, color: AppColors.success),
            onPressed: _isExporting ? null : _exportExcel,
          ),
        ],
      ),
      body: _isExporting
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _reportSummary(reportAsync),
                const SizedBox(height: 20),
                const Text('Produk Terlaris',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _topProducts(topAsync),
                const SizedBox(height: 20),
                const Text('Penjualan per Kategori',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _categorySales(catAsync),
              ],
            ),
    );
  }

  Widget _reportSummary(AsyncValue reportAsync) {
    return reportAsync.when(
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))),
      error: (e, _) => Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Error: $e'))),
      data: (report) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ringkasan Hari Ini',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Divider(),
              _row('Total Transaksi', '${report.transactionCount}'),
              _row('Total Omzet', CurrencyFormatter.format(report.totalRevenue)),
              _row('Total Diskon', CurrencyFormatter.format(report.totalDiscount)),
              _row('Total PPN', CurrencyFormatter.format(report.totalTax)),
              _row('Rata-rata', CurrencyFormatter.format(report.averageTransactionValue)),
              const Divider(),
              _row(
                'Profit Bersih',
                CurrencyFormatter.format(report.netProfit),
                bold: true,
                color: AppColors.success,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: bold ? 16 : 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 16 : 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color)),
        ],
      ),
    );
  }

  Widget _topProducts(AsyncValue topAsync) {
    return topAsync.when(
      loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('Error: $e'),
      data: (products) => Card(
        child: Column(
          children: products.isEmpty
              ? const [ListTile(title: Text('Belum ada data'))]
              : List.generate(products.length, (i) {
                  final p = products[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                      child: Text('${i + 1}',
                          style: const TextStyle(color: AppColors.primary)),
                    ),
                    title: Text(p.name),
                    subtitle: Text('Terjual ${p.totalSold}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: Text(CurrencyFormatter.format(p.totalRevenue),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }),
        ),
      ),
    );
  }

  Widget _categorySales(AsyncValue catAsync) {
    return catAsync.when(
      loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('Error: $e'),
      data: (cats) => Card(
        child: Column(
          children: cats.isEmpty
              ? const [ListTile(title: Text('Belum ada data'))]
              : List.generate(cats.length, (i) {
                  final c = cats[i];
                  return ListTile(
                    title: Text(c.categoryName),
                    subtitle: Text('Terjual ${c.totalSold}'),
                    trailing: Text(CurrencyFormatter.format(c.totalRevenue)),
                  );
                }),
        ),
      ),
    );
  }
}
