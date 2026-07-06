@echo off
:: Uninstall.bat
:: Runs the RegisterStartupTask.ps1 script with -Uninstall flag automatically.

echo Removing Process Priority Saver autostart and stopping daemon...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0RegisterStartupTask.ps1" -Uninstall
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Uninstallation failed.
    pause
    exit /b %errorlevel%
)

echo.
echo SUCCESS: Uninstallation completed successfully.
pause
