@echo off
:: Install.bat
:: Runs the RegisterStartupTask.ps1 script automatically.

echo ===================================================
echo Windows Process Priority Saver Installer
echo ===================================================
echo.
echo TIP: To manage elevated processes (like Valorant, Razer Cortex,
echo      or OBS running as Admin), run this batch file as Administrator!
echo.
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
