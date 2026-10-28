import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/report_models.dart';
import '../../../providers/report_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(dailyReportProvider);
    final topAsync = ref.watch(topProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dailyReportProvider.notifier).refresh();
              ref.read(topProductsProvider.notifier).load();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyReportProvider);
          ref.invalidate(topProductsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TodayReportCard(reportAsync),
            const SizedBox(height: 20),
            const Text('Produk Terlaris',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _TopProductsList(topAsync),
          ],
        ),
      ),
    );
  }
}

class _TodayReportCard extends ConsumerWidget {
  final AsyncValue<DailyReport> reportAsync;
  const _TodayReportCard(this.reportAsync);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return reportAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.danger)),
        ),
      ),
      data: (report) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Omzet Hari Ini',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(report.totalRevenue),
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Transaksi',
                        value: '${report.transactionCount}',
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        label: 'Profit Bersih',
                        value: CurrencyFormatter.formatShort(report.netProfit),
                        color: AppColors.success,
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        label: 'Rata-rata',
                        value: CurrencyFormatter.formatShort(
                            report.averageTransactionValue),
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }
}

class _TopProductsList extends ConsumerWidget {
  final AsyncValue<List<TopProduct>> topAsync;
  const _TopProductsList(this.topAsync);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return topAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (products) {
        if (products.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Belum ada penjualan',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          );
        }
        return Card(
          child: Column(
            children: List.generate(products.length, (index) {
              final p = products[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                  child: Text('${index + 1}',
                      style: const TextStyle(color: AppColors.primary)),
                ),
                title: Text(p.name),
                subtitle: Text('Terjual ${p.totalSold}',
                    style: const TextStyle(color: AppColors.textSecondary)),
                trailing: Text(
                  CurrencyFormatter.format(p.totalRevenue),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
