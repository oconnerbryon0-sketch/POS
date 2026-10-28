import 'package:drift/drift.dart';
import 'categories_table.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId =>
      integer().references(Categories, #id).nullable()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get barcode => text().nullable()();
  TextColumn get sku => text().nullable()();
  IntColumn get price => integer().withDefault(const Constant(0))();
  IntColumn get costPrice => integer().withDefault(const Constant(0))();
  IntColumn get stockQuantity => integer().withDefault(const Constant(0))();
  IntColumn get minStock => integer().withDefault(const Constant(5))();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {barcode},
        {sku},
      ];
}
