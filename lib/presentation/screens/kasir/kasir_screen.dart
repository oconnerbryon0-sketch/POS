import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/cart_item.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/report_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../services/printer/receipt_builder.dart';
import '../../../services/scanner/barcode_scanner_service.dart';
import '../../widgets/payment_sheet.dart';
import '../../widgets/receipt_preview_dialog.dart';
import 'transaction_history_screen.dart';

class KasirScreen extends ConsumerStatefulWidget {
  const KasirScreen({super.key});

  @override
  ConsumerState<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends ConsumerState<KasirScreen> {
  final TextEditingController _searchController = TextEditingController();
  final BarcodeScannerService _scannerService = BarcodeScannerService();

  @override
  void dispose() {
    _searchController.dispose();
    _scannerService.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String barcode) async {
    final repo = ref.read(productRepositoryProvider);
    final product = await repo.getByBarcode(barcode);
    if (!mounted) return;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produk dengan barcode $barcode tidak ditemukan'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    _addToCart(product);
  }

  void _addToCart(Product product) {
    final cartNotifier = ref.read(cartProvider.notifier);
    cartNotifier.addItem(CartItem(
      productId: product.id,
      name: product.name,
      barcode: product.barcode,
      unitPrice: product.price.toDouble(),
      costPrice: product.costPrice.toDouble(),
      quantity: 1,
    ));
  }

  void _openScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: MobileScanner(
          controller: _scannerService.getController(),
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isEmpty) return;
            final code = barcodes.first.rawValue;
            if (code != null && code.isNotEmpty) {
              _scannerService.stop();
              Navigator.pop(context);
              _handleScan(code);
            }
          },
        ),
      ),
    );
  }

  void _openPayment() {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PaymentSheet(
        grandTotal: cart.grandTotal,
        onConfirm: _processPayment,
      ),
    );
  }

  Future<void> _processPayment(double amountPaid) async {
    final cart = ref.read(cartProvider);
    final checkout = ref.read(checkoutProvider.notifier);

    try {
      final paymentMethods = await ref.read(paymentMethodsProvider.future);
      final defaultMethod =
          paymentMethods.isNotEmpty ? paymentMethods.first : null;
      final paymentMethodId = defaultMethod?.id ?? 0;

      final result = await checkout.execute(
        items: cart.items,
        paymentMethodId: paymentMethodId,
        paymentMethodName: defaultMethod?.name ?? 'Tunai',
        amountPaid: amountPaid,
        taxRate: cart.taxRate,
        discountType: cart.discountType,
        discountValue: cart.discountValue,
      );

      if (!mounted) return;

      // Bangun struk dari keranjang sebelum di-clear.
      final receipt = ReceiptBuilder.buildFromCart(
        result: result.result,
        items: cart.items,
        paymentMethod: defaultMethod?.name ?? 'Tunai',
        storeName: AppStrings.appName,
        taxRate: cart.taxRate,
        discountType: cart.discountType,
        discountValue: cart.discountValue,
      );

      ref.read(cartProvider.notifier).clear();
      ref.invalidate(transactionListProvider);
      ref.invalidate(dailyReportProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Transaksi ${result.result.transactionNumber} berhasil'),
          backgroundColor: AppColors.success,
        ),
      );

      // Preview struk dengan tombol cetak (pending setelah snackbar).
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        await ReceiptPreviewDialog.show(context, receipt: receipt);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout gagal: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final hasQuery = _searchController.text.trim().isNotEmpty;
    // Saat pengguna mengetik, tampilkan hasil pencarian; jika kosong, tampilkan semua.
    final productsAsync = hasQuery
        ? ref.watch(productSearchProvider)
        : ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Cari produk / scan barcode...',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (q) {
            if (q.trim().isEmpty) {
              ref.invalidate(productListProvider);
            } else {
              ref.read(productSearchProvider.notifier).search(q);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat Transaksi',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const TransactionHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _openScanner,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(color: AppColors.primaryDark),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                      child: Text('Belum ada produk'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return _ProductGridCard(
                      product: p,
                      onTap: () => _addToCart(p),
                    );
                  },
                );
              },
            ),
          ),
          _CartBar(
            cart: cart,
            onOpenPayment: _openPayment,
          ),
        ],
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProductGridCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lowStock = product.stockQuantity <= product.minStock;
    return InkWell(
      onTap: product.stockQuantity <= 0 ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Icon(
                    _iconFor(product.name),
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Text(product.name,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(CurrencyFormatter.format(product.price),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary)),
              Text(
                product.stockQuantity <= 0
                    ? 'Habis'
                    : 'Stok ${product.stockQuantity} ${product.unit}',
                style: TextStyle(
                  fontSize: 11,
                  color: product.stockQuantity <= 0
                      ? AppColors.danger
                      : (lowStock ? AppColors.warning : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('minum') || lower.contains('air') || lower.contains('jus')) {
      return Icons.local_drink;
    }
    if (lower.contains('nasi') || lower.contains('makan')) {
      return Icons.lunch_dining;
    }
    return Icons.inventory_2;
  }
}

class _CartBar extends StatelessWidget {
  final CartState cart;
  final VoidCallback onOpenPayment;
  const _CartBar({required this.cart, required this.onOpenPayment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _cartSummary(context),
          ),
          if (cart.totalQuantity > 0) ...[
            IconButton(
              onPressed: () => _showCartDetail(context),
              icon: const Icon(Icons.shopping_cart),
            ),
          ],
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: cart.isEmpty ? null : onOpenPayment,
            icon: const Icon(Icons.payment),
            label: Text('Bayar ${CurrencyFormatter.format(cart.grandTotal)}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${cart.totalQuantity} item',
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        if (cart.discountAmount > 0)
          Text('Diskon -${CurrencyFormatter.format(cart.discountAmount)}',
              style: const TextStyle(
                  color: AppColors.danger, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showCartDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CartDetailSheet(cart: cart),
    );
  }
}

class _CartDetailSheet extends ConsumerWidget {
  final CartState cart;
  const _CartDetailSheet({required this.cart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.read(cartProvider.notifier);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detail Keranjang',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showDiscountSheet(context, ref),
                  icon: const Icon(Icons.percent, size: 16),
                  label: Text(cart.discountType == 0
                      ? 'Tambah Diskon'
                      : 'Diskon ${cart.discountNote ?? cart.discountValue}'),
                ),
                if (cart.discountType != 0)
                  TextButton(
                    onPressed: cartNotifier.clearDiscount,
                    child: const Text('Hapus'),
                  ),
              ],
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: cart.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                        '${CurrencyFormatter.format(item.unitPrice)} x ${item.quantity}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => cartNotifier
                              .updateQuantity(item.productId, item.quantity - 1),
                        ),
                        Text('${item.quantity}'),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => cartNotifier
                              .updateQuantity(item.productId, item.quantity + 1),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            CurrencyFormatter.format(item.finalSubtotal),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            _totalRow('Subtotal', cart.grossSubtotal),
            if (cart.discountAmount > 0)
              _totalRow('Diskon', -cart.discountAmount),
            _totalRow('PPN 11%', cart.taxAmount),
            _totalRow('Total', cart.grandTotal, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool bold = false}) {
    final style = bold
        ? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
        : const TextStyle(fontSize: 15);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(CurrencyFormatter.format(amount), style: style),
        ],
      ),
    );
  }

  void _showDiscountSheet(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Atur Diskon',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  notifier.setPercentageDiscount(10);
                  Navigator.pop(context);
                },
                child: const Text('Diskon 10%'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  notifier.setPercentageDiscount(20);
                  Navigator.pop(context);
                },
                child: const Text('Diskon 20%'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showCustomDiscount(context, notifier),
                child: const Text('Diskon Kustom'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomDiscount(BuildContext context, dynamic notifier) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Diskon Kustom'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Persentase (%)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          TextButton(
            onPressed: () {
              final pct = double.tryParse(controller.text);
              if (pct != null) {
                notifier.setPercentageDiscount(pct.clamp(0, 100));
              }
              controller.dispose();
              Navigator.pop(context);
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }
}
