part of '../app_database.dart';

@DriftAccessor(tables: [Transactions, TransactionItems])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Future<Transaction?> getTransactionById(int id) {
    return (select(transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<TransactionItem>> getItemsForTransaction(int transactionId) {
    return (select(transactionItems)
          ..where((ti) => ti.transactionId.equals(transactionId)))
        .get();
  }

  Stream<List<Transaction>> watchRecentTransactions({int limit = 50}) {
    final query = select(transactions)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    return query.watch();
  }

  Future<List<Transaction>> getTransactionsBetween(
    DateTime start,
    DateTime end, {
    int limit = 1000,
  }) {
    return (select(transactions)
          ..where((t) =>
              t.createdAt.isBetweenValues(start, end) &
              t.status.equals('completed'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }
}
