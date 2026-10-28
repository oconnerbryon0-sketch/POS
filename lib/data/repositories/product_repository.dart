import 'package:drift/drift.dart';

import '../database/app_database.dart';

class ProductRepository {
  final AppDatabase _db;
  final ProductDao _productDao;
  final StockDao _stockDao;

  ProductRepository(this._db, this._productDao, this._stockDao);

  Stream<List<Product>> watchProducts({int limit = 200}) {
    return _productDao.watchAllProducts(limit: limit);
  }

  Future<Product?> getById(int id) => _productDao.getProductById(id);

  Future<Product?> getByBarcode(String barcode) =>
      _productDao.getProductByBarcode(barcode);

  Future<List<Product>> search(String query, {int limit = 50}) =>
      _productDao.searchProducts(query, limit: limit);

  Future<List<Category>> getCategories() => _productDao.getAllCategories();

  Future<int> createProduct({
    required String name,
    int? categoryId,
    String? barcode,
    String? sku,
    required int price,
    required int costPrice,
    required int stockQuantity,
    int minStock = 5,
    String unit = 'pcs',
    String? imagePath,
  }) {
    return _productDao.insertProduct(ProductsCompanion.insert(
      name: name,
      categoryId: Value(categoryId),
      barcode: Value(barcode),
      sku: Value(sku),
      price: Value(price),
      costPrice: Value(costPrice),
      stockQuantity: Value(stockQuantity),
      minStock: Value(minStock),
      unit: Value(unit),
      imagePath: Value(imagePath),
    ));
  }

  Future<int> updateProduct(
    int id,
    ProductsCompanion data,
  ) {
    return _productDao.updateProduct(id, data);
  }

  Future<int> deleteProduct(int id) => _productDao.deleteProduct(id);

  Future<int> createCategory({
    required String name,
    String? description,
    String iconName = 'category_default',
  }) {
    return _db.into(_db.categories).insert(CategoriesCompanion.insert(
          name: name,
          description: Value(description),
          iconName: Value(iconName),
        ));
  }

  Future<int> updateCategory(int id, CategoriesCompanion data) {
    return (_db.update(_db.categories)..where((c) => c.id.equals(id)))
        .write(data.copyWith(updatedAt: Value(DateTime.now())));
  }

  Future<int> deleteCategory(int id) {
    return (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
  }

  Future<void> adjustStock({
    required int productId,
    required int newStock,
    required String changeType,
    String? notes,
  }) {
    return _stockDao.adjustStock(
      productId: productId,
      newStock: newStock,
      changeType: changeType,
      notes: notes,
    );
  }
}
