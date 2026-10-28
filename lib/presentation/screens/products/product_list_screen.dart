import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/product_provider.dart';
import '../../dialogs/product_form_dialog.dart';
import '../../dialogs/stock_adjust_dialog.dart';
import 'category_list_screen.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Kategori',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CategoryListScreen()),
              );
              ref.invalidate(productListProvider);
              ref.invalidate(categoryListProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddProduct(context, ref),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('Belum ada produk'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _ProductTile(product: products[index], ref: ref),
          );
        },
      ),
    );
  }

  void _showAddProduct(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => const ProductFormDialog(),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final WidgetRef ref;
  const _ProductTile({required this.product, required this.ref});

  @override
  Widget build(BuildContext context) {
    final lowStock = product.stockQuantity <= product.minStock;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight.withOpacity(0.2),
          child: const Icon(Icons.inventory_2, color: AppColors.primary),
        ),
        title: Text(product.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.barcode != null && product.barcode!.isNotEmpty)
              Text('SKU: ${product.barcode}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            Text(
              'Stok: ${product.stockQuantity} ${product.unit}',
              style: TextStyle(
                fontSize: 13,
                color: product.stockQuantity <= 0
                    ? AppColors.danger
                    : (lowStock ? AppColors.warning : AppColors.textSecondary),
                fontWeight:
                    lowStock ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(product.price),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                Text('HP: ${CurrencyFormatter.format(product.costPrice)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.add_box_outlined, color: AppColors.success),
              tooltip: 'Stok Opname',
              onPressed: () => showDialog(
                context: context,
                builder: (_) => StockAdjustDialog(product: product),
              ),
            ),
          ],
        ),
        onTap: () => showDialog(
          context: context,
          builder: (_) => ProductFormDialog(product: product),
        ),
      ),
    );
  }
}
