import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/cart_item.dart';
import '../core/constants/app_strings.dart';

class CartState {
  final List<CartItem> items;
  final double taxRate;
  final int discountType; // 0=none, 1=percentage, 2=fixed
  final double discountValue;
  final String? discountNote;

  const CartState({
    this.items = const [],
    this.taxRate = AppStrings.defaultTaxRate,
    this.discountType = 0,
    this.discountValue = 0,
    this.discountNote,
  });

  double get subtotal =>
      items.fold(0, (sum, item) => sum + item.finalSubtotal);

  double get grossSubtotal => items.fold(0, (sum, item) => sum + item.subtotal);

  double get discountAmount {
    switch (discountType) {
      case 1:
        return grossSubtotal * (discountValue / 100);
      case 2:
        return discountValue;
      default:
        return 0;
    }
  }

  double get discountedSubtotal => grossSubtotal - discountAmount;

  double get taxAmount => discountedSubtotal * taxRate;

  double get grandTotal => discountedSubtotal + taxAmount;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItem>? items,
    double? taxRate,
    int? discountType,
    double? discountValue,
    String? discountNote,
  }) {
    return CartState(
      items: items ?? this.items,
      taxRate: taxRate ?? this.taxRate,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountNote: discountNote ?? this.discountNote,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(CartItem item) {
    final idx = state.items.indexWhere((i) => i.productId == item.productId);
    if (idx >= 0) {
      final existing = state.items[idx];
      final newQty = existing.quantity + item.quantity;
      final updated = [
        ...state.items.sublist(0, idx),
        existing.copyWith(quantity: newQty),
        ...state.items.sublist(idx + 1),
      ];
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(items: [...state.items, item]);
    }
  }

  void updateQuantity(int productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }
    final updated = state.items.map((i) {
      if (i.productId == productId) return i.copyWith(quantity: newQuantity);
      return i;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void removeItem(int productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.productId != productId).toList(),
    );
  }

  void setPercentageDiscount(double percentage) {
    assert(percentage >= 0 && percentage <= 100);
    state = state.copyWith(
      discountType: 1,
      discountValue: percentage,
      discountNote: '${percentage.toStringAsFixed(0)}%',
    );
  }

  void setFixedDiscount(double amount) {
    assert(amount >= 0);
    state = state.copyWith(discountType: 2, discountValue: amount);
  }

  void clearDiscount() {
    state = state.copyWith(
      discountType: 0,
      discountValue: 0,
      discountNote: null,
    );
  }

  double calculateChange(double amountPaid) => amountPaid - state.grandTotal;

  bool validatePayment(double amountPaid) => amountPaid >= state.grandTotal;

  void clear() {
    state = const CartState();
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());
