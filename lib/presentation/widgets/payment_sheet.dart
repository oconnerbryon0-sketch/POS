import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class PaymentSheet extends StatefulWidget {
  final double grandTotal;
  final Function(double amountPaid) onConfirm;

  const PaymentSheet({
    super.key,
    required this.grandTotal,
    required this.onConfirm,
  });

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  final TextEditingController _amountController = TextEditingController();
  double _change = 0;
  final List<double> _quickAmounts = [50000, 100000, 200000, 500000];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculateChange);
  }

  void _calculateChange() {
    final amount = _parseAmount(_amountController.text);
    setState(() {
      _change = amount - widget.grandTotal;
    });
  }

  double _parseAmount(String text) {
    return double.tryParse(text.replaceAll('.', '').trim()) ?? 0;
  }

  void _selectQuickAmount(double amount) {
    _amountController.text =
        CurrencyFormatter.formatNoSymbol(amount);
  }

  @override
  Widget build(BuildContext context) {
    final canPay = _change >= 0;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Total Pembayaran',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(widget.grandTotal),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            ],
            style: const TextStyle(fontSize: 24),
            decoration: InputDecoration(
              labelText: 'Bayar',
              prefixText: 'Rp ',
              prefixStyle:
                  TextStyle(fontSize: 20, color: Colors.grey.shade600),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            children: _quickAmounts
                .where((a) => a >= widget.grandTotal)
                .map((amount) => ActionChip(
                      label:
                          Text(CurrencyFormatter.format(amount)),
                      onPressed: () => _selectQuickAmount(amount),
                      backgroundColor: AppColors.primaryLight.withOpacity(0.15),
                      labelStyle: const TextStyle(color: AppColors.primaryDark),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: canPay
                  ? AppColors.successLight
                  : AppColors.dangerLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  canPay ? 'Kembalian:' : 'Kurang Bayar:',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: canPay
                          ? AppColors.success
                          : AppColors.danger),
                ),
                Text(
                  CurrencyFormatter.format(_change.abs()),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: canPay ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: canPay
                  ? () {
                      widget.onConfirm(
                          _parseAmount(_amountController.text));
                    }
                  : null,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text('Konfirmasi Pembayaran',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
