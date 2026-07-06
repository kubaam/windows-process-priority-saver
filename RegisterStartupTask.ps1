# RegisterStartupTask.ps1
# Registers/unregisters the Process Priority Saver for autostart using the Windows Startup folder (requires no Admin rights).

param (
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

# Get user's Startup folder path
$StartupFolder = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Startup)
$VbsPath = Join-Path $StartupFolder "ProcessPrioritySaver.vbs"
$ScriptPath = Join-Path $PSScriptRoot "ProcessPrioritySaver.ps1"

# Helper to stop running daemon processes
function Stop-Daemon {
    Write-Output "Stopping any running ProcessPrioritySaver instances..."
    $Processes = Get-Process -Name powershell -ErrorAction SilentlyContinue | Where-Object {
        try {
            $_.CommandLine -like "*ProcessPrioritySaver.ps1*"
        } catch {
            $false
        }
    }
    if ($Processes) {
        $Processes | Stop-Process -Force
        Write-Output "Stopped $($Processes.Count) process(es)."
    } else {
        Write-Output "No running instances found."
    }
}

if ($Uninstall) {
    Write-Output "Uninstalling autostart shortcut..."
    if (Test-Path $VbsPath) {
        Remove-Item $VbsPath -Force
        Write-Output "Removed Vbs launch script from Startup folder."
    } else {
        Write-Output "No startup script found."
    }
    Stop-Daemon
    exit
}

# Ensure main script exists
if (-not (Test-Path $ScriptPath)) {
    Write-Error "Could not find ProcessPrioritySaver.ps1 at $ScriptPath"
    exit
}

# Stop any currently running instances before registering/restarting
Stop-Daemon

Write-Output "Creating silent VBScript launcher in Startup folder..."
$VbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""$ScriptPath""", 0, false
"@

[System.IO.File]::WriteAllText($VbsPath, $VbsContent)
Write-Output "Successfully registered autostart at: $VbsPath"

# Run it immediately
Write-Output "Starting Process Priority Saver in the background..."
Start-Process wscript.exe -ArgumentList "`"$VbsPath`""
Write-Output "Successfully started. It is now running silently in the background."
