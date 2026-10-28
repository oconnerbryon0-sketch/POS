import 'dart:convert';
import 'dart:typed_data';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';

class ReceiptData {
  final String storeName;
  final String? storeAddress;
  final String? storePhone;
  final String transactionNumber;
  final DateTime dateTime;
  final String cashier;
  final List<ReceiptItem> items;
  final double subtotal;
  final double discount;
  final String? discountNote;
  final double tax;
  final String taxLabel;
  final double grandTotal;
  final String paymentMethod;
  final double amountPaid;
  final double change;
  final String? footer;

  const ReceiptData({
    required this.storeName,
    this.storeAddress,
    this.storePhone,
    required this.transactionNumber,
    required this.dateTime,
    this.cashier = 'Kasir 1',
    required this.items,
    required this.subtotal,
    required this.discount,
    this.discountNote,
    required this.tax,
    this.taxLabel = 'PPN 11%',
    required this.grandTotal,
    required this.paymentMethod,
    required this.amountPaid,
    required this.change,
    this.footer,
  });
}

class ReceiptItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });
}

/// Generator konversi struk menjadi byte ESC/POS.
class EscPosGenerator {
  EscPosGenerator._();

  // ESC/POS Commands
  static const List<int> _init = [0x1B, 0x40];
  static const List<int> _boldOn = [0x1B, 0x45, 0x01];
  static const List<int> _boldOff = [0x1B, 0x45, 0x00];
  static const List<int> _alignCenter = [0x1B, 0x61, 0x01];
  static const List<int> _alignLeft = [0x1B, 0x61, 0x00];
  static const List<int> _feedLines = [0x1B, 0x64, 0x03];
  static const List<int> _cutPaper = [0x1D, 0x56, 0x42, 0x00];

  static Uint8List generateReceipt(ReceiptData receipt,
      {int paperWidth = 32}) {
    final bytes = <int>[];
    final w = paperWidth;

    bytes.addAll(_init);

    // HEADER
    bytes.addAll(_alignCenter);
    bytes.addAll(_boldOn);
    bytes.addAll(_text(receipt.storeName, w));
    bytes.addAll(_boldOff);

    if (receipt.storeAddress != null && receipt.storeAddress!.isNotEmpty) {
      bytes.addAll(_text(receipt.storeAddress!, w));
    }
    if (receipt.storePhone != null && receipt.storePhone!.isNotEmpty) {
      bytes.addAll(_text(receipt.storePhone!, w));
    }

    bytes.addAll(_text('-' * w, w));

    // INFO TRANSAKSI
    bytes.addAll(_alignLeft);
    bytes.addAll(_boldOn);
    bytes.addAll(_text('No. ${receipt.transactionNumber}', w));
    bytes.addAll(_boldOff);
    bytes.addAll(
        _text('Tgl: ${DateFormatter.formatDateTime(receipt.dateTime)}', w));
    bytes.addAll(_text('Kasir: ${receipt.cashier}', w));
    bytes.addAll(_text('', w)); // blank line

    // ITEMS
    bytes.addAll(_text('-' * w, w));
    for (final item in receipt.items) {
      final nameLine = '${item.name}  x${item.quantity}';
      bytes.addAll(_text(nameLine, w));
      final priceLine = _twoCols(
        CurrencyFormatter.format(item.unitPrice),
        CurrencyFormatter.format(item.subtotal),
        w,
      );
      bytes.addAll(_text(priceLine, w));
    }
    bytes.addAll(_text('-' * w, w));

    // TOTAL
    bytes.addAll(_text(_twoCols('Subtotal:', CurrencyFormatter.format(receipt.subtotal), w), w));

    if (receipt.discount > 0) {
      final label =
          receipt.discountNote != null ? 'Diskon (${receipt.discountNote})' : 'Diskon';
      bytes.addAll(_text(_twoCols('$label:', '-${CurrencyFormatter.format(receipt.discount)}', w), w));
    }

    bytes.addAll(_text(_twoCols('${receipt.taxLabel}:', CurrencyFormatter.format(receipt.tax), w), w));

    bytes.addAll(_boldOn);
    bytes.addAll(_text(_twoCols('TOTAL:', CurrencyFormatter.format(receipt.grandTotal), w), w));
    bytes.addAll(_boldOff);

    bytes.addAll(_text('', w));

    // PEMBAYARAN
    bytes.addAll(_text('Metode: ${receipt.paymentMethod}', w));
    bytes.addAll(_text(_twoCols('Bayar:', CurrencyFormatter.format(receipt.amountPaid), w), w));
    if (receipt.change > 0) {
      bytes.addAll(_boldOn);
      bytes.addAll(_text(_twoCols('Kembali:', CurrencyFormatter.format(receipt.change), w), w));
      bytes.addAll(_boldOff);
    }

    bytes.addAll(_text('', w));

    // FOOTER
    bytes.addAll(_alignCenter);
    bytes.addAll(_text(receipt.footer ?? 'Terima kasih atas kunjungan Anda', w));
    bytes.addAll(_text('Barang yang sudah dibeli', w));
    bytes.addAll(_text('tidak dapat dikembalikan', w));

    bytes.addAll(_feedLines);
    bytes.addAll(_cutPaper);

    return Uint8List.fromList(bytes);
  }

  static List<int> _text(String text, int maxChars) {
    if (text.length > maxChars) {
      text = text.substring(0, maxChars);
    }
    return utf8.encode('$text\n');
  }

  /// Dua kolom: label kiri, nilai kanan dengan titik pengisi.
  static String _twoCols(String left, String right, int w) {
    final used = left.length + right.length + 1;
    final dots = w - used;
    if (dots <= 0) return '$left $right';
    return '$left${'.' * dots}$right';
  }
}
