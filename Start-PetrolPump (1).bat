@echo off
setlocal
title Bhatti Petroleum - Local Server
color 0B

rem ============================================================
rem Bhatti Petroleum local launcher
rem Place this file in the same folder as index.js and package.json
rem ============================================================

cd /d "%~dp0"

set "APP_PORT=5000"
set "APP_URL=http://localhost:%APP_PORT%"

rem Database configuration used by config\db.js
rem Change these values if your local MySQL setup is different.
set "DB_HOST=localhost"
set "DB_PORT=3306"
set "DB_USER=root"
set "DB_PASSWORD="
set "DB_NAME=bhatti_petrolium"

rem Make the application use the configured port.
set "PORT=%APP_PORT%"

cls
echo ============================================================
echo          BHATTI PETROLEUM MANAGEMENT SYSTEM
echo ============================================================
echo.

if not exist "index.js" (
    echo [ERROR] index.js was not found.
    echo.
    echo Put Start-PetrolPump.bat inside the PetrolPump project
    echo folder, next to index.js and package.json.
    echo.
    pause
    exit /b 1
)

if not exist "package.json" (
    echo [ERROR] package.json was not found in:
    echo %CD%
    echo.
    pause
    exit /b 1
)

where node >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js is not installed or is not in PATH.
    echo.
    echo Install Node.js 18 or later from:
    echo https://nodejs.org/
    echo.
    pause
    exit /b 1
)

where npm >nul 2>&1
if errorlevel 1 (
    echo [ERROR] npm is not available.
    echo Reinstall Node.js and include npm in the installation.
    echo.
    pause
    exit /b 1
)

echo [OK] Node.js detected:
node --version
echo.

if not exist "node_modules\" (
    echo [INFO] Required packages are not installed.
    echo [INFO] Installing packages now. Internet is required once.
    echo.
    call npm install

    if errorlevel 1 (
        echo.
        echo [ERROR] Package installation failed.
        echo Check your internet connection and run this file again.
        echo.
        pause
        exit /b 1
    )

    echo.
    echo [OK] Packages installed successfully.
    echo.
)

rem Check whether another application is already responding on this URL.
powershell -NoProfile -Command "try { Invoke-WebRequest -UseBasicParsing -Uri '%APP_URL%' -TimeoutSec 2 | Out-Null; exit 0 } catch { exit 1 }"
if not errorlevel 1 (
    echo [INFO] The application is already running.
    echo [INFO] Opening %APP_URL%
    start "" "%APP_URL%"
    echo.
    pause
    exit /b 0
)

echo [INFO] Database : %DB_NAME%
echo [INFO] Server   : %APP_URL%
echo.
echo [INFO] Starting the application...
echo [INFO] Keep this window open while using the system.
echo [INFO] Press Ctrl+C in this window to stop it.
echo.

rem Wait until Express responds, and then open the application in the browser.
start "" /B powershell -NoProfile -WindowStyle Hidden -Command "$url='%APP_URL%'; foreach ($attempt in 1..30) { try { Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 2 | Out-Null; Start-Process $url; exit 0 } catch { Start-Sleep -Seconds 1 } }; exit 1"

node index.js
set "APP_EXIT_CODE=%ERRORLEVEL%"

echo.
echo ============================================================
if "%APP_EXIT_CODE%"=="0" (
    echo The Bhatti Petroleum application has stopped.
) else (
    echo [ERROR] The application stopped with code %APP_EXIT_CODE%.
    echo Review the error messages shown above.
    echo Confirm that MySQL is running and the database exists.
)
echo ============================================================
echo.
pause
exit /b %APP_EXIT_CODE%
