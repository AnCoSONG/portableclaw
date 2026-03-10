@echo off
chcp 65001 >nul 2>&1
title OpenClaw Gateway

set "ROOT=%~dp0"
:: Remove trailing backslash for cleaner paths
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "NODE=%ROOT%\runtime\node.exe"
set "OPENCLAW_ENTRY=%ROOT%\app\node_modules\openclaw\openclaw.mjs"
set "NODE_PATH=%ROOT%\app\node_modules"
set "PATH=%ROOT%\runtime;%ROOT%\bin;%PATH%"

:: Verify runtime exists
if not exist "%NODE%" (
    echo.
    echo  [ERROR] Node.js runtime not found at: %NODE%
    echo  The package may be corrupted. Please re-download.
    echo.
    pause
    exit /b 1
)

:: Verify openclaw exists
if not exist "%OPENCLAW_ENTRY%" (
    echo.
    echo  [ERROR] OpenClaw not found at: %OPENCLAW_ENTRY%
    echo  The package may be corrupted. Please re-download.
    echo.
    pause
    exit /b 1
)

:: First run: onboard if no config exists
if not exist "%USERPROFILE%\.openclaw\openclaw.json" (
    echo.
    echo  ================================================
    echo    OpenClaw - First Run Setup
    echo  ================================================
    echo.
    echo  Welcome! Let's configure OpenClaw for first use.
    echo.
    "%NODE%" "%OPENCLAW_ENTRY%" onboard
    if errorlevel 1 (
        echo.
        echo  Setup was interrupted. You can run it again later
        echo  by double-clicking start.bat
        echo.
        pause
        exit /b 1
    )
    echo.
)

echo.
echo  ================================================
echo    OpenClaw Gateway
echo  ================================================
echo.
echo  Dashboard:  http://127.0.0.1:18789/
echo  Press Ctrl+C to stop
echo.

:: Open browser after a short delay
start "" "http://127.0.0.1:18789/"

:: Run gateway in foreground (closing the window stops it)
"%NODE%" "%OPENCLAW_ENTRY%" gateway --port 18789 --verbose
pause
