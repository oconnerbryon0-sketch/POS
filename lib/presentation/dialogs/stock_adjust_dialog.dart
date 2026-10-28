import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/database_constants.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/product_provider.dart';

class StockAdjustDialog extends ConsumerStatefulWidget {
  final Product product;
  const StockAdjustDialog({super.key, required this.product});

  @override
  ConsumerState<StockAdjustDialog> createState() => _StockAdjustDialogState();
}

class _StockAdjustDialogState extends ConsumerState<StockAdjustDialog> {
  late final TextEditingController _newStock;
  final TextEditingController _notes = TextEditingController();
  String _changeType = DbConstants.stockChangeAdjustment;

  @override
  void initState() {
    super.initState();
    _newStock =
        TextEditingController(text: widget.product.stockQuantity.toString());
  }

  @override
  void dispose() {
    _newStock.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newStock = int.tryParse(_newStock.text.trim());
    if (newStock == null || newStock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Stok harus angka valid'),
          backgroundColor: AppColors.danger));
      return;
    }

    final repo = ref.read(productRepositoryProvider);
    try {
      await repo.adjustStock(
        productId: widget.product.id,
        newStock: newStock,
        changeType: _changeType,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      ref.invalidate(productListProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Stok diperbarui'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final delta =
        (int.tryParse(_newStock.text.trim()) ?? 0) - p.stockQuantity;

    return AlertDialog(
      title: Text('Stok Opname - ${p.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stok saat ini: ${p.stockQuantity} ${p.unit}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 16),
            TextField(
              controller: _newStock,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stok baru'),
            ),
            const SizedBox(height: 8),
            Text(
              delta == 0
                  ? 'Tidak ada perubahan'
                  : (delta > 0
                      ? 'Tambah +$delta ${p.unit}'
                      : 'Kurang $delta ${p.unit}'),
              style: TextStyle(
                color: delta >= 0 ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Jenis Penyesuaian',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _typeChip('adjustment', 'Stok Opname'),
                _typeChip('restock', 'Restock'),
                _typeChip('damage', 'Rusak'),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)', hintText: 'Contoh: opname bulanan'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }

  Widget _typeChip(String type, String label) {
    final selected = _changeType == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _changeType = type),
    );
  }
}
