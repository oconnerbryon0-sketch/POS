import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/models/cart_item.dart';
import '../data/models/report_models.dart';
import '../data/repositories/transaction_repository.dart';
import 'database_providers.dart';
import 'cart_provider.dart';

/// Hasil checkout untuk UI.
class CheckoutResult {
  final TransactionResult result;
  final List<CartItem> items;
  final String paymentMethod;

  const CheckoutResult({
    required this.result,
    required this.items,
    required this.paymentMethod,
  });
}

final transactionListProvider =
    StreamProvider<List<Transaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchRecent();
});

/// Notifier checkout - memproses pembayaran.
class CheckoutNotifier extends StateNotifier<AsyncValue<CheckoutResult?>> {
  final TransactionRepository _repo;
  CheckoutNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<CheckoutResult> execute({
    required List<CartItem> items,
    required int paymentMethodId,
    required String paymentMethodName,
    required double amountPaid,
    double taxRate = 0.11,
    int discountType = 0,
    double discountValue = 0,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.processCheckout(
        items: items,
        paymentMethodId: paymentMethodId,
        amountPaid: amountPaid,
        taxRate: taxRate,
        discountType: discountType,
        discountValue: discountValue,
      );
      final checkoutResult = CheckoutResult(
        result: result,
        items: items,
        paymentMethod: paymentMethodName,
      );
      state = AsyncValue.data(checkoutResult);
      return checkoutResult;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final checkoutProvider =
    StateNotifierProvider<CheckoutNotifier, AsyncValue<CheckoutResult?>>(
        (ref) => CheckoutNotifier(ref.watch(transactionRepositoryProvider)));

/// Provider yang mengkombinasikan cart & checkout untuk verifikasi.
final cartCanCheckoutProvider = Provider<bool>((ref) {
  final cart = ref.watch(cartProvider);
  return !cart.isEmpty;
});
