import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/product_provider.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  Future<void> _addCategory(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Kategori'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (added == true) {
      final repo = ref.read(productRepositoryProvider);
      try {
        await repo.createCategory(name: controller.text.trim());
        ref.invalidate(categoryListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Kategori ditambahkan'),
              backgroundColor: AppColors.success));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Gagal: $e'),
              backgroundColor: AppColors.danger));
        }
      }
    }
    controller.dispose();
  }

  Future<void> _renameCategory(
      BuildContext context, WidgetRef ref, Category category) async {
    final controller = TextEditingController(text: category.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ubah Kategori'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final repo = ref.read(productRepositoryProvider);
      try {
        await repo.updateCategory(
          category.id,
          CategoriesCompanion(
            name: Value(controller.text.trim()),
          ),
        );
        ref.invalidate(categoryListProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Gagal: $e'),
              backgroundColor: AppColors.danger));
        }
      }
    }
    controller.dispose();
  }

  Future<void> _deleteCategory(
      BuildContext context, WidgetRef ref, Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text(
            'Hapus kategori "${category.name}"? Produk di dalamnya akan menjadi "Tanpa Kategori".'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      try {
        // Set produk di kategori ini menjadi tanpa kategori, lalu hapus kategori.
        await db.transaction(() async {
          await (db.update(db.products)..where((p) => p.categoryId.equals(category.id)))
              .write(ProductsCompanion(categoryId: const Value<int?>(null)));
          await (db.delete(db.categories)..where((c) => c.id.equals(category.id)))
              .go();
        });
        ref.invalidate(categoryListProvider);
        ref.invalidate(productListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Kategori dihapus'),
              backgroundColor: AppColors.success));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Gagal: $e'),
              backgroundColor: AppColors.danger));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Kategori',
            onPressed: () => _addCategory(context, ref),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
                child: Text('Belum ada kategori, ketuk + untuk menambah'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final c = categories[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                    child: const Icon(Icons.category,
                        color: AppColors.primary),
                  ),
                  title: Text(c.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _renameCategory(context, ref, c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.danger),
                        onPressed: () => _deleteCategory(context, ref, c),
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
