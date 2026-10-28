import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/report_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../services/printer/receipt_builder.dart';
import '../../widgets/receipt_preview_dialog.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  Future<void> _void(Transaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Transaksi'),
        content: Text(
            'Batalkan transaksi ${tx.transactionNumber}? Stok akan dikembalikan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(transactionRepositoryProvider);
    try {
      await repo.voidTransaction(tx.id);
      ref.invalidate(transactionListProvider);
      ref.invalidate(dailyReportProvider);
      ref.invalidate(topProductsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Transaksi dibatalkan, stok dikembalikan'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal void: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _reprint(Transaction tx) async {
    final repo = ref.read(transactionRepositoryProvider);
    try {
      final items = await repo.getItems(tx.id);
      final paymentMethods = await ref.read(paymentMethodsProvider.future);
      PaymentMethod? method;
      for (final m in paymentMethods) {
        if (m.id == tx.paymentMethodId) {
          method = m;
          break;
        }
      }
      final productRepo = ref.read(productRepositoryProvider);

      // Resolve nama produk untuk semua item sekaligus.
      final nameMap = <int, String>{};
      for (final item in items) {
        final p = await productRepo.getById(item.productId);
        nameMap[item.productId] = p?.name ?? 'Produk #${item.productId}';
      }

      final receipt = ReceiptBuilder.buildFromStored(
        transaction: tx,
        items: items,
        paymentMethodName: method?.name ?? 'Tunai',
        storeName: AppStrings.appName,
        productNameResolver: (id) => nameMap[id] ?? 'Produk #$id',
      );

      if (mounted) {
        await ReceiptPreviewDialog.show(context, receipt: receipt);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal cetak ulang: $e'),
            backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final txsAsync = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: txsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text('Belum ada transaksi'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isVoid = tx.status == 'cancelled';
              return Card(
                color: isVoid ? Colors.grey.shade200 : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isVoid
                        ? AppColors.dangerLight
                        : AppColors.successLight,
                    child: Icon(
                      isVoid ? Icons.undo : Icons.receipt_long,
                      color:
                          isVoid ? AppColors.danger : AppColors.success,
                    ),
                  ),
                  title: Text(
                    tx.transactionNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration:
                          isVoid ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(
                    '${DateFormatter.formatDateTime(tx.createdAt)}'
                    '${isVoid ? '\nVOID' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isVoid
                          ? AppColors.danger
                          : AppColors.textSecondary,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(tx.totalAmount),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isVoid)
                            IconButton(
                              icon: const Icon(Icons.undo,
                                  size: 18, color: AppColors.danger),
                              tooltip: 'Batalkan (Void)',
                              onPressed: () => _void(tx),
                            ),
                          IconButton(
                            icon: const Icon(Icons.print,
                                size: 18, color: AppColors.primary),
                            tooltip: 'Cetak Ulang',
                            onPressed: () => _reprint(tx),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
