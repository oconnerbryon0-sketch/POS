import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/repositories/product_repository.dart';
import 'database_providers.dart';

final productListProvider =
    StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchProducts();
});

class ProductSearchNotifier
    extends StateNotifier<AsyncValue<List<Product>>> {
  final ProductRepository _repo;
  ProductSearchNotifier(this._repo) : super(const AsyncValue.loading());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(
        () => _repo.watchProducts().first,
      );
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.search(query));
  }
}

final productSearchProvider =
    StateNotifierProvider<ProductSearchNotifier, AsyncValue<List<Product>>>(
        (ref) => ProductSearchNotifier(ref.watch(productRepositoryProvider)));

class CategoryListNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final ProductRepository _repo;
  CategoryListNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.getCategories);
  }
}

final categoryListProvider =
    StateNotifierProvider<CategoryListNotifier, AsyncValue<List<Category>>>(
        (ref) => CategoryListNotifier(ref.watch(productRepositoryProvider)));
