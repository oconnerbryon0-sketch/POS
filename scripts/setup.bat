@echo off
REM ============================================
REM  POS UMKM - Project Setup Script
REM  Jangan lupa instal Flutter SDK terlebih dahulu
REM ============================================

echo.
echo [1/4] Flutter pub get (mengunduh dependencies)...
call flutter pub get
if errorlevel 1 goto :error

echo.
echo [2/4] Menjalankan build_runner untuk generate kode Drift...
call dart run build_runner build --delete-conflicting-outputs
if errorlevel 1 goto :error

echo.
echo [3/4] Menjalankan unit test...
call flutter test
if errorlevel 1 goto :error

echo.
echo [4/4] Menjalankan analisis statis...
call flutter analyze
if errorlevel 1 goto :error

echo.
echo ============================================
echo  Setup selesai! Jalankan aplikasi dengan:
echo.
echo    flutter run
echo.
echo ============================================
goto :eof

:error
echo.
echo [ERROR] Terjadi kesalahan. Periksa pesan di atas.
exit /b 1
