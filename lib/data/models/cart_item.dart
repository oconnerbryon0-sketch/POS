/// Model keranjang belanja di memori (bukan table database).
class CartItem {
  final int productId;
  final String name;
  final String? barcode;
  final double unitPrice;
  final double costPrice;
  final int quantity;
  final int discountType; // 0=none, 1=percentage, 2=fixed
  final double discountValue;

  const CartItem({
    required this.productId,
    required this.name,
    this.barcode,
    required this.unitPrice,
    required this.costPrice,
    required this.quantity,
    this.discountType = 0,
    this.discountValue = 0,
  });

  double get subtotal => unitPrice * quantity;

  double get itemDiscount {
    switch (discountType) {
      case 1:
        return subtotal * (discountValue / 100);
      case 2:
        return discountValue;
      default:
        return 0;
    }
  }

  double get finalSubtotal => subtotal - itemDiscount;

  double get profit => (unitPrice - costPrice) * quantity;

  CartItem copyWith({
    int? productId,
    String? name,
    String? barcode,
    double? unitPrice,
    double? costPrice,
    int? quantity,
    int? discountType,
    double? discountValue,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
    );
  }
}
