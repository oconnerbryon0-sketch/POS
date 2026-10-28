import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/services/printer/esc_pos_generator.dart';

void main() {
  group('EscPosGenerator', () {
    test('menghasilkan byte header ESC/POS init', () {
      final receipt = _sampleReceipt();
      final bytes = EscPosGenerator.generateReceipt(receipt);

      // Byte pertama harus 0x1B, 0x40 (init printer)
      expect(bytes[0], 0x1B);
      expect(bytes[1], 0x40);
    });

    test('berisi teks nama toko dalam UTF-8', () {
      final receipt = _sampleReceipt();
      final bytes = EscPosGenerator.generateReceipt(receipt);

      // Konversi bytes yang terbaca ke string dan cek mengandung nama toko
      final asText = utf8.decode(bytes);
      expect(asText, contains('Toko Contoh'));
    });

    test('mengandung total transaksi', () {
      final receipt = _sampleReceipt();
      final bytes = EscPosGenerator.generateReceipt(receipt);
      final asText = utf8.decode(bytes);
      expect(asText, contains('TOTAL'));
      expect(asText, contains('Rp'));
    });

    test('memotong baris jika melebihi lebar kertas', () {
      final receipt = ReceiptData(
        storeName: 'Nama Toko Yang Sangat Panjang Melebihi Lebar Kertas Maksimum',
        transactionNumber: 'TX-001',
        dateTime: DateTime(2024, 1, 1),
        items: const [],
        subtotal: 0,
        discount: 0,
        tax: 0,
        grandTotal: 0,
        paymentMethod: 'Tunai',
        amountPaid: 0,
        change: 0,
      );
      final bytes = EscPosGenerator.generateReceipt(receipt);
      final asText = utf8.decode(bytes);
      // Buang urutan escape ESC/POS (ESC + byte parameter) dan byte kontrol
      // lainnya, agar hanya teks isi struk yang diukur panjangnya.
      final escStripped = asText.replaceAll(RegExp(r'\x1b.'), '');
      final cleaned =
          escStripped.replaceAll(RegExp(r'[\x00-\x09\x0B-\x1F\x7F]'), '');
      final lines = cleaned.split('\n').where((l) => l.isNotEmpty);
      for (final line in lines) {
        expect(line.length, lessThanOrEqualTo(32),
            reason: 'Baris melebihi lebar 32: "$line"');
      }
    });
  });
}

ReceiptData _sampleReceipt() {
  return ReceiptData(
    storeName: 'Toko Contoh',
    storeAddress: 'Jl. Merdeka No. 1',
    storePhone: '0812-3456-7890',
    transactionNumber: 'TX-20240901-123456-0001',
    dateTime: DateTime(2024, 9, 1, 10, 30),
    cashier: 'Kasir 1',
    items: [
      const ReceiptItem(name: 'Kopi Susu', quantity: 2, unitPrice: 15000, subtotal: 30000),
      const ReceiptItem(name: 'Roti Bakar', quantity: 1, unitPrice: 10000, subtotal: 10000),
    ],
    subtotal: 40000,
    discount: 0,
    tax: 4400,
    grandTotal: 44400,
    paymentMethod: 'Tunai',
    amountPaid: 50000,
    change: 5600,
    footer: 'Terima kasih',
  );
}
