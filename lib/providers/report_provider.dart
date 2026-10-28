import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/models/report_models.dart';
import '../data/repositories/report_repository.dart';
import 'database_providers.dart';

final paymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getPaymentMethods();
});

class DailyReportNotifier extends StateNotifier<AsyncValue<DailyReport>> {
  final ReportRepository _repo;
  DateTime _selectedDate;

  DailyReportNotifier(this._repo, this._selectedDate)
      : super(const AsyncValue.loading()) {
    load(_selectedDate);
  }

  DateTime get selectedDate => _selectedDate;

  Future<void> load(DateTime date) async {
    _selectedDate = date;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getDailyReport(date));
  }

  Future<void> refresh() => load(_selectedDate);
}

final dailyReportProvider = StateNotifierProvider<DailyReportNotifier,
    AsyncValue<DailyReport>>(
  (ref) => DailyReportNotifier(
    ref.watch(reportRepositoryProvider),
    DateTime.now(),
  ),
);

class TopProductsNotifier extends StateNotifier<AsyncValue<List<TopProduct>>> {
  final ReportRepository _repo;
  TopProductsNotifier(this._repo)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getTopProducts(limit: 10));
  }
}

final topProductsProvider =
    StateNotifierProvider<TopProductsNotifier, AsyncValue<List<TopProduct>>>(
        (ref) => TopProductsNotifier(ref.watch(reportRepositoryProvider)));

class CategorySalesNotifier
    extends StateNotifier<AsyncValue<List<CategorySales>>> {
  final ReportRepository _repo;
  CategorySalesNotifier(this._repo)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.getCategorySales);
  }
}

final categorySalesProvider =
    StateNotifierProvider<CategorySalesNotifier, AsyncValue<List<CategorySales>>>(
        (ref) => CategorySalesNotifier(ref.watch(reportRepositoryProvider)));
