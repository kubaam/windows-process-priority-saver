@echo off
:: Install.bat
:: Runs the RegisterStartupTask.ps1 script automatically.

echo Registering Process Priority Saver autostart...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0RegisterStartupTask.ps1"
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Installation failed.
    pause
    exit /b %errorlevel%
)

echo.
echo SUCCESS: Installation completed successfully.
pause
