part of '../app_database.dart';

@DriftAccessor(tables: [Products, Categories])
class ProductDao extends DatabaseAccessor<AppDatabase>
    with _$ProductDaoMixin {
  ProductDao(super.db);

  // ========================
  // QUERIES
  // ========================

  Stream<List<Product>> watchAllProducts({int limit = 200}) {
    final query = select(products)
      ..where((p) => p.isActive.equals(true))
      ..orderBy([(p) => OrderingTerm.asc(p.name)])
      ..limit(limit);
    return query.watch();
  }

  Future<Product?> getProductById(int id) {
    return (select(products)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Product?> getProductByBarcode(String barcode) {
    return (select(products)..where((p) => p.barcode.equals(barcode)))
        .getSingleOrNull();
  }

  /// Pencarian produk cepat dengan prioritas hasil.
  /// 1. Barcode/SKU exact match (0)
  /// 2. Nama prefix (1)
  /// 3. Nama mengandung query (2)
  Future<List<Product>> searchProducts(
    String query, {
    int limit = 50,
  }) async {
    final q = query.trim();
    if (q.isEmpty) {
      return (select(products)
            ..where((p) => p.isActive.equals(true))
            ..orderBy([(p) => OrderingTerm.asc(p.name)])
            ..limit(limit))
          .get();
    }

    final rows = await customSelect(
      'SELECT p.id, p.category_id, p.name, p.barcode, p.sku, '
      'p.price, p.cost_price, p.stock_quantity, p.min_stock, '
      'p.unit, p.image_path, p.is_active, p.created_at, p.updated_at '
      'FROM products p '
      'WHERE p.is_active = 1 '
      'AND (p.name LIKE :contains '
      '  OR p.barcode = :exact OR p.sku = :exact '
      '  OR p.name LIKE :prefix) '
      'ORDER BY '
      '  CASE WHEN p.barcode = :exact THEN 0 '
      '       WHEN p.sku = :exact THEN 1 '
      '       WHEN p.name LIKE :prefix THEN 2 '
      '       ELSE 3 END, '
      '  p.name ASC '
      'LIMIT :limit',
      variables: [
        Variable.withString('%$q%'),
        Variable.withString(q),
        Variable.withString(q),
        Variable.withString('$q%'),
        Variable.withString(q),
        Variable.withString(q),
        Variable.withString('$q%'),
        Variable.withInt(limit),
      ],
      readsFrom: {products},
    ).get();

    return rows.map(_productFromRow).toList();
  }

  // ========================
  // WRITE OPERATIONS
  // ========================

  Future<int> insertProduct(ProductsCompanion data) {
    return into(products).insert(data);
  }

  Future<int> updateProduct(int id, ProductsCompanion data) {
    return (update(products)..where((p) => p.id.equals(id)))
        .write(data.copyWith(updatedAt: Value(DateTime.now())));
  }

  Future<int> deleteProduct(int id) {
    return (delete(products)..where((p) => p.id.equals(id))).go();
  }

  // ========================
  // CATEGORIES
  // ========================

  Future<List<Category>> getAllCategories() {
    return (select(categories)
          ..where((c) => c.isActive.equals(true))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }

  // ========================
  // MAPPING
  // ========================

  Product _productFromRow(QueryRow row) {
    // Kamus kolom products manual (cepat, tidak bergantung pada generated)
    final id = row.read<int>('id');
    final categoryId = row.read<int?>('category_id');
    final name = row.read<String>('name');
    final barcode = row.read<String?>('barcode');
    final sku = row.read<String?>('sku');
    final price = row.read<int>('price');
    final costPrice = row.read<int>('cost_price');
    final stockQuantity = row.read<int>('stock_quantity');
    final minStock = row.read<int>('min_stock');
    final unit = row.read<String>('unit');
    final imagePath = row.read<String?>('image_path');
    final isActiveInt = row.read<int>('is_active');
    final isActive = isActiveInt == 1;
    final createdAt = row.read<DateTime>('created_at');
    final updatedAt = row.read<DateTime>('updated_at');

    return Product(
      id: id,
      categoryId: categoryId,
      name: name,
      barcode: barcode,
      sku: sku,
      price: price,
      costPrice: costPrice,
      stockQuantity: stockQuantity,
      minStock: minStock,
      unit: unit,
      imagePath: imagePath,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
