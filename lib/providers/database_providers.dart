import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/report_repository.dart';
import '../data/repositories/transaction_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final productDaoProvider = Provider<ProductDao>((ref) {
  return ProductDao(ref.watch(databaseProvider));
});

final stockDaoProvider = Provider<StockDao>((ref) {
  return StockDao(ref.watch(databaseProvider));
});

final transactionDaoProvider = Provider<TransactionDao>((ref) {
  return TransactionDao(ref.watch(databaseProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(
    ref.watch(databaseProvider),
    ref.watch(productDaoProvider),
    ref.watch(stockDaoProvider),
  );
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(
    ref.watch(databaseProvider),
    ref.watch(transactionDaoProvider),
    ref.watch(stockDaoProvider),
  );
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(
    ref.watch(databaseProvider),
    ref.watch(transactionDaoProvider),
  );
});
