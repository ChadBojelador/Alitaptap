@echo off
echo ========================================
echo Starting Alitaptap Backend and App
echo ========================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    pause
    exit /b 1
)

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter is not installed or not in PATH
    pause
    exit /b 1
)

echo [1/4] Installing Python dependencies...
cd "services\api_fastapi"
pip install -r requirements.txt
if errorlevel 1 (
    echo ERROR: Failed to install Python dependencies
    pause
    exit /b 1
)

echo.
echo [2/4] Starting FastAPI backend on port 8000...
start "FastAPI Backend" cmd /k "uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"

echo.
echo [3/4] Waiting for backend to start...
timeout /t 5 /nobreak >nul

echo.
echo [4/4] Starting Flutter app...
cd ..\..\apps\mobile_flutter
start "Flutter App" cmd /k "flutter run"

echo.
echo ========================================
echo Both services are starting!
echo ========================================
echo FastAPI Backend: http://127.0.0.1:8000/docs
echo Flutter App: Running in separate window
echo.
echo Press any key to exit this window...
pause >nul
