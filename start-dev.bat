@echo off
echo ===============================================================
echo ⚡ SECURE P2P FILE SHARING SYSTEM — LOCAL DEV LAUNCHER
echo ===============================================================
echo.

echo [1/3] Building TypeScript Signaling Server...
cd signaling-server
call npm run build
if %errorlevel% neq 0 (
    echo [ERROR] Signaling server build failed!
    exit /b %errorlevel%
)
cd ..

echo.
echo [2/3] Starting Signaling Server on http://localhost:3000...
start "P2P Signaling Server" cmd /k "cd signaling-server && npm start"

echo.
echo [3/3] Launching Flutter App Client...
flutter run -d chrome

pause
