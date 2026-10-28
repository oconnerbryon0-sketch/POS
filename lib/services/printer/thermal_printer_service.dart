import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';

import 'esc_pos_generator.dart';

class PrinterException implements Exception {
  final String message;
  PrinterException(this.message);
  @override
  String toString() => 'PrinterException: $message';
}

class ThermalPrinterService {
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;

  Future<bool> get isConnected async =>
      await _printer.isConnected ?? false;

  Future<List<BluetoothDevice>> scanDevices() async {
    return await _printer.getBondedDevices();
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await _printer.connect(device);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> disconnect() async {
    await _printer.disconnect();
  }

  Future<bool> printReceipt(ReceiptData receipt) async {
    if (!(await isConnected)) {
      throw PrinterException('Printer tidak terhubung');
    }
    try {
      final Uint8List bytes = EscPosGenerator.generateReceipt(receipt);
      await _printer.writeBytes(bytes);
      return true;
    } on PrinterException {
      rethrow;
    } catch (e) {
      throw PrinterException('Gagal mencetak: $e');
    }
  }

  Future<void> cutPaper() async {
    if (!(await isConnected)) return;
    await _printer
        .writeBytes(Uint8List.fromList(const [0x1D, 0x56, 0x42, 0x00]));
  }
}
