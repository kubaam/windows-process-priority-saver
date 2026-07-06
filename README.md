# Windows Process Priority Saver

A lightweight, zero-dependency background daemon written in native PowerShell that automatically monitors, saves, and restores custom CPU priorities set in Windows Task Manager.

Windows Task Manager does not natively persist process priority classes across restarts. This utility solves that limitation by running a silent monitoring loop in the background.

## Features

- **Automatic Saving**: If you manually change a process's CPU priority in Task Manager (e.g., setting `chrome.exe` to `High`), the script automatically detects this change and saves it.
- **Automatic Restoring**: Whenever a process starts, the script detects it and instantly applies your saved custom priority class.
- **Zero Overhead**: Uses native .NET APIs for process scanning. Runs on a 5-second sleep interval, ensuring 0% CPU consumption.
- **Silent Background Run**: Automatically registers via a silent VBScript launcher in the user's Startup folder, running hidden (no console window popups) at system logon without requiring Administrator privileges.
- **Clean Configuration**: Saves rules in a simple JSON file (`priority_rules.json`).

## How to Install (Autostart)

To register the script to run automatically at user logon:

- Simply double-click **`Install.bat`** (or run it in a terminal).
- Alternatively, run `.\RegisterStartupTask.ps1` in PowerShell.

The background daemon will start immediately and automatically run on future logins.

## How to Uninstall

To stop the background monitoring and remove the startup link:

- Simply double-click **`Uninstall.bat`** (or run it in a terminal).
- Alternatively, run `.\RegisterStartupTask.ps1 -Uninstall` in PowerShell.

## Files

- `Install.bat`: Double-click to install/register autostart.
- `Uninstall.bat`: Double-click to uninstall/stop the daemon.
- `ProcessPrioritySaver.ps1`: The main background daemon script.
- `RegisterStartupTask.ps1`: Helper script to register/unregister the startup link.
- `priority_rules.json`: Local database file storing process name -> priority mapping.
- `README.md`: Project documentation.
