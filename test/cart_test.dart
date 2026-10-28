import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/data/models/cart_item.dart';
import 'package:pos_app/providers/cart_provider.dart';

void main() {
  group('CartItem', () {
    test('subtotal dihitung benar', () {
      const item = CartItem(
        productId: 1,
        name: 'Kopi',
        unitPrice: 15000,
        costPrice: 10000,
        quantity: 2,
      );
      expect(item.subtotal, 30000);
      expect(item.finalSubtotal, 30000);
      expect(item.profit, 10000);
    });

    test('diskon persentase per item', () {
      const item = CartItem(
        productId: 1,
        name: 'Kopi',
        unitPrice: 10000,
        costPrice: 5000,
        quantity: 1,
        discountType: 1,
        discountValue: 10,
      );
      expect(item.itemDiscount, 1000);
      expect(item.finalSubtotal, 9000);
    });
  });

  group('CartState', () {
    // Karena CartNotifier tergantung widget binding, gunakan notifier langsung
    test('perhitungan total termasuk pajak', () {
      final notifier = CartNotifier();
      notifier.addItem(const CartItem(
        productId: 1,
        name: 'A',
        unitPrice: 10000,
        costPrice: 5000,
        quantity: 2,
      ));
      final state = notifier.state;
      // gross = 20000, discounted = 20000, tax 11% = 2200, total = 22200
      expect(state.grossSubtotal, 20000);
      expect(state.grandTotal, closeTo(22200, 0.001));
    });

    test('diskon persentase diterapkan pada total', () {
      final notifier = CartNotifier();
      notifier.addItem(const CartItem(
        productId: 1,
        name: 'A',
        unitPrice: 10000,
        costPrice: 5000,
        quantity: 2,
      ));
      notifier.setPercentageDiscount(10);
      final state = notifier.state;
      // gross = 20000, diskon 10% = 2000, discounted = 18000, tax 11% = 1980, total = 19980
      expect(state.discountAmount, closeTo(2000, 0.001));
      expect(state.grandTotal, closeTo(19980, 0.001));
    });

    test('menghitung uang kembalian', () {
      final notifier = CartNotifier();
      notifier.addItem(const CartItem(
        productId: 1,
        name: 'A',
        unitPrice: 10000,
        costPrice: 5000,
        quantity: 1,
      ));
      final change = notifier.calculateChange(20000);
      // total = 11100, bayar 20000 => kembalian 8900
      expect(change, closeTo(8900, 0.001));
    });

    test('update dan hapus quantity', () {
      final notifier = CartNotifier();
      notifier.addItem(const CartItem(
        productId: 1,
        name: 'A',
        unitPrice: 1000,
        costPrice: 500,
        quantity: 1,
      ));
      notifier.updateQuantity(1, 3);
      expect(notifier.state.totalQuantity, 3);

      notifier.updateQuantity(1, 0);
      expect(notifier.state.isEmpty, true);
    });
  });
}
