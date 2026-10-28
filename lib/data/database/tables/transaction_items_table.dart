import 'package:drift/drift.dart';
import 'transactions_table.dart';
import 'products_table.dart';

class TransactionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId =>
      integer().references(Transactions, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer()();
  IntColumn get unitPrice => integer()();
  IntColumn get costPrice => integer()();
  TextColumn get discountType =>
      text().withDefault(const Constant('none'))();
  IntColumn get discountValue => integer().withDefault(const Constant(0))();
  IntColumn get subtotal => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
