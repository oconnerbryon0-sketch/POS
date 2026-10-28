import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

import '../services/printer/esc_pos_generator.dart';
import '../services/printer/thermal_printer_service.dart';

class PrinterState {
  final bool isConnected;
  final BluetoothDevice? currentDevice;
  final List<BluetoothDevice> devices;
  final bool isScanning;

  const PrinterState({
    this.isConnected = false,
    this.currentDevice,
    this.devices = const [],
    this.isScanning = false,
  });

  PrinterState copyWith({
    bool? isConnected,
    BluetoothDevice? currentDevice,
    List<BluetoothDevice>? devices,
    bool? isScanning,
  }) {
    return PrinterState(
      isConnected: isConnected ?? this.isConnected,
      currentDevice: currentDevice ?? this.currentDevice,
      devices: devices ?? this.devices,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}

class PrinterNotifier extends StateNotifier<PrinterState> {
  final ThermalPrinterService _service;
  PrinterNotifier(this._service) : super(const PrinterState());

  Future<void> scan() async {
    state = state.copyWith(isScanning: true);
    try {
      final devices = await _service.scanDevices();
      state = state.copyWith(devices: devices, isScanning: false);
    } catch (_) {
      state = state.copyWith(isScanning: false);
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    final ok = await _service.connect(device);
    if (ok) {
      state = state.copyWith(isConnected: true, currentDevice: device);
    }
    return ok;
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    state = state.copyWith(isConnected: false, currentDevice: null);
  }

  Future<bool> get isConnected async {
    if (state.isConnected) return true;
    return _service.isConnected;
  }

  Future<bool> printReceipt(ReceiptData receipt) {
    return _service.printReceipt(receipt);
  }
}

final printerServiceProvider = Provider<ThermalPrinterService>(
    (ref) => ThermalPrinterService());

final printerProvider =
    StateNotifierProvider<PrinterNotifier, PrinterState>(
  (ref) => PrinterNotifier(ref.watch(printerServiceProvider)),
);
