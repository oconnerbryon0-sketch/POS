import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerService {
  MobileScannerController? _controller;

  MobileScannerController getController({
    DetectionSpeed speed = DetectionSpeed.noDuplicates,
  }) {
    _controller ??= MobileScannerController(
      detectionSpeed: speed,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.qrCode,
      ],
    );
    return _controller!;
  }

  Stream<BarcodeCapture> get onDetect =>
      _controller?.barcodes ?? const Stream.empty();

  Future<void> toggleTorch() async {
    final c = _controller;
    if (c != null && c.torchState.value == TorchState.off) {
      await c.toggleTorch();
    } else if (c != null) {
      await c.toggleTorch();
    }
  }

  Future<void> start() => _controller?.start() ?? Future.value();

  Future<void> stop() => _controller?.stop() ?? Future.value();

  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
