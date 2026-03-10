@echo off
set "ROOT=%~dp0.."
set "PATH=%ROOT%\runtime;%PATH%"
set "NODE_PATH=%ROOT%\app\node_modules"
"%ROOT%\runtime\node.exe" "%ROOT%\app\node_modules\openclaw\openclaw.mjs" %*
