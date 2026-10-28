import 'package:drift/drift.dart';
import 'products_table.dart';

class StockLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get changeType => text()();
  IntColumn get quantityChange => integer()();
  IntColumn get previousStock => integer()();
  IntColumn get newStock => integer()();
  IntColumn get referenceId => integer().nullable()();
  TextColumn get referenceType => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
