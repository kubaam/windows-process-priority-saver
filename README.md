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

1. Open a PowerShell console in this directory.
2. Run the registration script:
   ```powershell
   .\RegisterStartupTask.ps1
   ```
3. The background daemon is now running and will automatically start on future logins.

## How to Uninstall

To stop the background monitoring and remove the startup link:

1. Run the registration script with the `-Uninstall` flag:
   ```powershell
   .\RegisterStartupTask.ps1 -Uninstall
   ```

## Files

- `ProcessPrioritySaver.ps1`: The main background daemon script.
- `RegisterStartupTask.ps1`: Helper script to register/unregister the startup link.
- `priority_rules.json`: Local database file storing process name -> priority mapping.
- `README.md`: Project documentation.
