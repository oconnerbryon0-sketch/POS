# Platform Setup Reference

Aplikasi ini berbasis **Drift (SQLite)** dan membutuhkan akses **Bluetooth** untuk thermal printer serta **Kamera** untuk barcode scanner.

## Cara scaffolding platform (wajib sekali)

Jalankan di root proyek setelah Flutter SDK terpasang:

```bash
flutter create . --platforms=android,ios
```

Perintah ini akan membuat folder `android/`, `ios/`, `web/`, dll **tanpa menghapus** file `lib/` dan `pubspec.yaml` yang sudah ada.

> CATATAN: Jika `flutter create .` menolak karena nama folder tidak valid, jalankan:
> ```bash
> flutter create . --project-name pos_app --platforms=android,ios
> ```

## Setelah scaffolding - tambahkan izin berikut

### Android: `android/app/src/main/AndroidManifest.xml`

Tambahkan izin berikut di dalam tag `<manifest>` (sebelum `<application>`):

```xml
<!-- Bluetooth (untuk thermal printer) -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />

<!-- Kamera (untuk barcode scanner) -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />

<!-- Internet (untuk sync masa depan) -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### iOS: `ios/Runner/Info.plist`

Tambahkan:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Dibutuhkan untuk menghubungkan printer thermal.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Dibutuhkan untuk menghubungkan printer thermal.</string>
<key>NSCameraUsageDescription</key>
<string>Dibutuhkan untuk memindai barcode produk.</string>
```

## Menjalankan aplikasi

Gunakan script di `scripts/`:

**Windows (cmd):**
```bash
scripts\setup.bat
```

**Linux/macOS:**
```bash
bash scripts/setup.sh
```

atau manual:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```
