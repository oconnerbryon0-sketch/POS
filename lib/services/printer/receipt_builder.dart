import '../../core/constants/app_strings.dart';
import '../../data/database/app_database.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/report_models.dart';
import 'esc_pos_generator.dart';

/// Membangun [ReceiptData] (struk) dari data transaksi.
class ReceiptBuilder {
  ReceiptBuilder._();

  /// Build struk langsung dari item keranjang (pasca checkout),
  /// sehingga nama produk tetap tersedia.
  static ReceiptData buildFromCart({
    required TransactionResult result,
    required List<CartItem> items,
    required String paymentMethod,
    required String storeName,
    required double taxRate,
    int discountType = 0,
    double discountValue = 0,
    String cashier = 'Kasir 1',
  }) {
    final grossSubtotal = items.fold<double>(0, (s, i) => s + i.subtotal);
    double discountAmount = 0;
    if (discountType == 1) {
      discountAmount = grossSubtotal * (discountValue / 100);
    } else if (discountType == 2) {
      discountAmount = discountValue;
    }
    final discountedSubtotal = grossSubtotal - discountAmount;
    final taxAmount = discountedSubtotal * taxRate;
    final grandTotal = discountedSubtotal + taxAmount;

    final amountPaid = result.changeAmount + grandTotal;

    return ReceiptData(
      storeName: storeName,
      storeAddress: null,
      storePhone: null,
      transactionNumber: result.transactionNumber,
      dateTime: DateTime.now(),
      cashier: cashier,
      items: items
          .map((i) => ReceiptItem(
                name: i.name,
                quantity: i.quantity,
                unitPrice: i.unitPrice,
                subtotal: i.finalSubtotal,
              ))
          .toList(),
      subtotal: grossSubtotal,
      discount: discountAmount,
      discountNote: discountAmount > 0
          ? (discountType == 1
              ? '${discountValue.toStringAsFixed(0)}%'
              : 'nominal')
          : null,
      tax: taxAmount,
      taxLabel: 'PPN',
      grandTotal: grandTotal,
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
      change: result.changeAmount,
      footer: AppStrings.appName,
    );
  }

  /// Build struk dari transaksi tersimpan (untuk riwayat/reprint).
  /// Nama produk diambil lewat callback pemetaan id -> nama.
  static ReceiptData buildFromStored({
    required Transaction transaction,
    required List<TransactionItem> items,
    required String paymentMethodName,
    required String storeName,
    String Function(int productId)? productNameResolver,
    String cashier = 'Kasir 1',
  }) {
    return ReceiptData(
      storeName: storeName,
      storeAddress: null,
      storePhone: null,
      transactionNumber: transaction.transactionNumber,
      dateTime: transaction.createdAt,
      cashier: cashier,
      items: items
          .map((i) => ReceiptItem(
                name: productNameResolver?.call(i.productId) ??
                    'Produk #${i.productId}',
                quantity: i.quantity,
                unitPrice: i.unitPrice.toDouble(),
                subtotal: i.subtotal.toDouble(),
              ))
          .toList(),
      subtotal: transaction.subtotal.toDouble(),
      discount: transaction.discountAmount.toDouble(),
      discountNote: transaction.discountAmount > 0 ? 'Diskon' : null,
      tax: transaction.taxAmount.toDouble(),
      taxLabel: 'PPN',
      grandTotal: transaction.totalAmount.toDouble(),
      paymentMethod: paymentMethodName,
      amountPaid: transaction.amountPaid.toDouble(),
      change: transaction.changeAmount.toDouble(),
      footer: AppStrings.appName,
    );
  }
}
