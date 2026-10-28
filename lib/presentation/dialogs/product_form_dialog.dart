import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../core/constants/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/product_provider.dart';

class ProductFormDialog extends ConsumerStatefulWidget {
  final Product? product;
  const ProductFormDialog({super.key, this.product});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _barcode;
  late final TextEditingController _price;
  late final TextEditingController _costPrice;
  late final TextEditingController _stock;
  late final TextEditingController _minStock;

  int? _categoryId;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _price = TextEditingController(text: p?.price.toString() ?? '');
    _costPrice = TextEditingController(text: p?.costPrice.toString() ?? '');
    _stock = TextEditingController(text: p?.stockQuantity.toString() ?? '0');
    _minStock =
        TextEditingController(text: p?.minStock.toString() ?? '5');
    _categoryId = p?.categoryId;
  }

  @override
  void dispose() {
    _name.dispose();
    _barcode.dispose();
    _price.dispose();
    _costPrice.dispose();
    _stock.dispose();
    _minStock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(productRepositoryProvider);
    final isEdit = widget.product != null;

    try {
      final name = _name.text.trim();
      final price = int.parse(_price.text.trim());
      final cost = int.tryParse(_costPrice.text.trim()) ?? 0;
      final stock = int.tryParse(_stock.text.trim()) ?? 0;
      final minStock = int.tryParse(_minStock.text.trim()) ?? 5;

      if (isEdit) {
        await repo.updateProduct(widget.product!.id, ProductsCompanion(
          name: Value(name),
          barcode: Value(_barcode.text.trim().isEmpty
              ? null
              : _barcode.text.trim()),
          categoryId: Value(_categoryId),
          price: Value(price),
          costPrice: Value(cost),
          minStock: Value(minStock),
        ));
      } else {
        await repo.createProduct(
          name: name,
          barcode: _barcode.text.trim().isEmpty
              ? null
              : _barcode.text.trim(),
          categoryId: _categoryId,
          price: price,
          costPrice: cost,
          stockQuantity: stock,
          minStock: minStock,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Produk disimpan'),
            backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    final categoriesAsync = ref.watch(categoryListProvider);
    return AlertDialog(
      title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Gagal memuat kategori: $e'),
                data: (categories) => DropdownButtonFormField<int?>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tanpa Kategori'),
                    ),
                    ...categories.map(
                      (c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barcode,
                decoration:
                    const InputDecoration(labelText: 'Barcode / SKU (opsional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Harga Jual (Rp)'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                  if (int.tryParse(v.trim()) == null) return 'Angka tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costPrice,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Harga Modal (Rp)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Stok Awal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minStock,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Min. Stok'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        ElevatedButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}
