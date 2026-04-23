@echo off
echo ========================================
echo Starting Flutter App
echo ========================================
echo.

cd apps\mobile_flutter

echo Getting Flutter dependencies...
flutter pub get

echo.
echo Starting Flutter app...
echo Make sure the backend is running at http://192.168.0.139:8000
echo.

flutter run
