@echo off
set "ROOT=%~dp0.."
set "PATH=%ROOT%\runtime;%PATH%"
set "NODE_PATH=%ROOT%\app\node_modules"
set "OPENCLAW_HOME=%ROOT%\data"
"%ROOT%\runtime\node.exe" "%ROOT%\app\node_modules\openclaw\openclaw.mjs" %*
