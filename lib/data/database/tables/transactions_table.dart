import 'package:drift/drift.dart';
import 'payment_methods_table.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transactionNumber => text().unique()();
  IntColumn get subtotal => integer().withDefault(const Constant(0))();
  IntColumn get taxAmount => integer().withDefault(const Constant(0))();
  IntColumn get discountAmount => integer().withDefault(const Constant(0))();
  IntColumn get totalAmount => integer().withDefault(const Constant(0))();
  IntColumn get paymentMethodId =>
      integer().references(PaymentMethods, #id).nullable()();
  IntColumn get amountPaid => integer().withDefault(const Constant(0))();
  IntColumn get changeAmount => integer().withDefault(const Constant(0))();
  TextColumn get status =>
      text().withDefault(const Constant('completed'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}
