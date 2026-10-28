import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/printer_provider.dart';
import '../../../core/constants/app_strings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader('Printer Thermal Bluetooth'),
          const SizedBox(height: 8),
          const _PrinterCard(),
          const SizedBox(height: 24),
          const _SectionHeader('Tentang Aplikasi'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.store, color: AppColors.primary),
                  title: Text(AppStrings.appName),
                  subtitle: Text('v1.0.0 - ${AppStrings.appTagline}'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_off, color: AppColors.warning),
                  title: const Text('Mode Operasi'),
                  subtitle: const Text(AppStrings.noConnection),
                  trailing: const Chip(
                    label: Text('Offline-First'),
                    backgroundColor: AppColors.warningLight,
                    labelStyle: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }
}

class _PrinterCard extends ConsumerStatefulWidget {
  const _PrinterCard();

  @override
  ConsumerState<_PrinterCard> createState() => _PrinterCardState();
}

class _PrinterCardState extends ConsumerState<_PrinterCard> {
  @override
  Widget build(BuildContext context) {
    final printerState = ref.watch(printerProvider);
    final printerNotifier = ref.read(printerProvider.notifier);

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            value: printerState.isConnected,
            title: const Text('Printer Terhubung'),
            subtitle: Text(
              printerState.currentDevice?.name ?? 'Belum ada printer',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            secondary: const Icon(Icons.print, color: AppColors.primary),
            onChanged: (value) {
              if (value) {
                printerNotifier.scan();
              } else {
                printerNotifier.disconnect();
              }
            },
          ),
          if (printerState.isScanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!printerState.isConnected &&
              printerState.devices.isNotEmpty)
            ...printerState.devices.map((device) => ListTile(
                  leading: const Icon(Icons.bluetooth, color: AppColors.primary),
                  title: Text(device.name ?? 'Unknown'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _connect(printerNotifier, device),
                )),
          if (!printerState.isConnected &&
              printerState.devices.isEmpty &&
              !printerState.isScanning)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Aktifkan Bluetooth dan hubungkan printer untuk scan.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: printerNotifier.scan,
                    child: const Text('Scan'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _connect(dynamic notifier, BluetoothDevice device) async {
    final ok = await notifier.connect(device);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Printer terhubung'),
            backgroundColor: AppColors.success),
      );
    }
  }
}
