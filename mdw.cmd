@echo off
setlocal

set "MDW_ROOT=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%MDW_ROOT%mdw.ps1" %*

endlocal