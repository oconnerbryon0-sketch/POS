#!/usr/bin/env bash
set -e

echo "[1/4] flutter pub get..."
flutter pub get

echo "[2/4] build_runner (generate Drift code)..."
dart run build_runner build --delete-conflicting-outputs

echo "[3/4] flutter test..."
flutter test

echo "[4/4] flutter analyze..."
flutter analyze

echo ""
echo "Setup selesai! Jalankan: flutter run"
