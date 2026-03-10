@echo off
chcp 65001 >nul 2>&1
title OpenClaw Updater

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "NODE=%ROOT%\runtime\node.exe"
set "NPM_CLI=%ROOT%\runtime\node_modules\npm\bin\npm-cli.js"
set "PATH=%ROOT%\runtime;%PATH%"

if not exist "%NODE%" (
    echo.
    echo  [ERROR] Node.js runtime not found. Package may be corrupted.
    echo.
    pause
    exit /b 1
)

echo.
echo  ================================================
echo    OpenClaw Updater
echo  ================================================
echo.

:: Show current version
if exist "%ROOT%\VERSION" (
    set /p CURRENT_VER=<"%ROOT%\VERSION"
    echo  Current version: %CURRENT_VER%
)

echo  Detecting best registry...

:: Auto-detect npm registry (3s timeout, fallback to China mirror)
"%NODE%" -e "fetch('https://registry.npmjs.org/openclaw',{signal:AbortSignal.timeout(3000)}).then(()=>console.log('https://registry.npmjs.org')).catch(()=>console.log('https://registry.npmmirror.com'))" > "%TEMP%\oc_registry.txt" 2>nul
set /p REGISTRY=<"%TEMP%\oc_registry.txt"
del "%TEMP%\oc_registry.txt" 2>nul

echo  Registry: %REGISTRY%
echo.
echo  Installing latest version...
echo.

"%NODE%" "%NPM_CLI%" install openclaw@latest --prefix "%ROOT%\app" --registry "%REGISTRY%" --no-fund --no-audit --loglevel error

:: Update VERSION file
"%NODE%" -e "console.log(require('%ROOT:\=/%/app/node_modules/openclaw/package.json').version)" > "%ROOT%\VERSION" 2>nul

echo.
echo  Update complete!
echo  Restart OpenClaw to use the new version.
echo.
pause
