@echo off
echo ========================================
echo Starting FastAPI Backend
echo ========================================
echo.

cd services\api_fastapi

echo Installing dependencies...
pip install -r requirements.txt

echo.
echo Starting server on http://127.0.0.1:8000
echo API Docs: http://127.0.0.1:8000/docs
echo.

uvicorn app.main:app --reload --port 8000
