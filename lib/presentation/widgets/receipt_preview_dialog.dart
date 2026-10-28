import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/printer_provider.dart';
import '../../services/printer/esc_pos_generator.dart';

class ReceiptPreviewDialog extends ConsumerWidget {
  final ReceiptData receipt;
  const ReceiptPreviewDialog({super.key, required this.receipt});

  /// Menampilkan dialog preview struk dan mencetak jika diminta.
  static Future<void> show(
    BuildContext context, {
    required ReceiptData receipt,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ReceiptPreviewDialog(receipt: receipt),
    );
  }

  Future<void> _print(BuildContext context, WidgetRef ref) async {
    final printer = ref.read(printerProvider.notifier);
    if (!(await printer.isConnected)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Printer belum terhubung. Hubungkan di menu Pengaturan.'),
            backgroundColor: AppColors.danger));
      }
      return;
    }
    try {
      await printer.printReceipt(receipt);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Struk dicetak'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal cetak: $e'),
            backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(printerProvider.select((s) => s.isConnected));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Preview Struk',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: _receiptView(context),
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _print(context, ref),
                    child: const Text('Cetak'),
                  ),
                ),
                const SizedBox(width: 8),
                if (!connected)
                  const Expanded(
                    child: Chip(
                      avatar: Icon(Icons.bluetooth_disabled, size: 16),
                      label: Text('Offline'),
                      backgroundColor: AppColors.warningLight,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptView(BuildContext context) {
    final w = 30;
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(receipt.storeName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold)),
          if (receipt.storeAddress != null)
            Text(receipt.storeAddress!, textAlign: TextAlign.center),
          _sep(w),
          _left('No. ${receipt.transactionNumber}'),
          _left('Tgl: ${_dt(receipt.dateTime)}'),
          _left('Kasir: ${receipt.cashier}'),
          _sep(w),
          for (final item in receipt.items) ...[
            _left('${item.name}  x${item.quantity}'),
            _left(_twoCols(CurrencyFormatter.format(item.unitPrice),
                CurrencyFormatter.format(item.subtotal), w)),
          ],
          _sep(w),
          _left(_twoCols('Subtotal:',
              CurrencyFormatter.format(receipt.subtotal), w)),
          if (receipt.discount > 0)
            _left(_twoCols('Diskon:',
                '-${CurrencyFormatter.format(receipt.discount)}', w)),
          _left(_twoCols('${receipt.taxLabel}:',
              CurrencyFormatter.format(receipt.tax), w)),
          _left(
              _twoCols('TOTAL:', CurrencyFormatter.format(receipt.grandTotal),
                  w),
              bold: true),
          _sep(w),
          _left('Metode: ${receipt.paymentMethod}'),
          _left(_twoCols(
              'Bayar:', CurrencyFormatter.format(receipt.amountPaid), w)),
          if (receipt.change > 0)
            _left(_twoCols(
                    'Kembali:', CurrencyFormatter.format(receipt.change), w),
                bold: true),
          _sep(w),
          _center('Terima kasih atas kunjungan Anda'),
          _center('Barang yang sudah dibeli tidak dapat dikembalikan'),
        ],
      ),
    );
  }

  Widget _sep(int w) => Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Text('-' * w, style: const TextStyle(fontSize: 10)),
      );

  Widget _left(String text, {bool bold = false}) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            textAlign: TextAlign.left,
            style: TextStyle(
                fontSize: 11, fontWeight: bold ? FontWeight.bold : null)),
      );

  Widget _center(String text) => Text(text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 10));

  String _twoCols(String left, String right, int w) {
    final used = left.length + right.length + 1;
    final dots = w - used;
    if (dots <= 0) return '$left $right';
    return '$left${'.' * dots}$right';
  }

  String _dt(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }
}
