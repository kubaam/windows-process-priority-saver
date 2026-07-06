# RegisterStartupTask.ps1
# Registers/unregisters the Process Priority Saver.
# Dual-mode:
# - Run as Admin: Registers via Windows Task Scheduler with Highest Privileges (can manage elevated games & Razer apps).
# - Run as User: Registers via Startup folder with silent VBScript (can only manage user-level processes).

param (
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"
$TaskName = "ProcessPrioritySaver"

# Get paths
$StartupFolder = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Startup)
$VbsPath = Join-Path $StartupFolder "ProcessPrioritySaver.vbs"
$ScriptPath = Join-Path $PSScriptRoot "ProcessPrioritySaver.ps1"

# Check if running as Administrator
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
$IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

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
    Write-Output "Uninstalling autostart registrations..."
    
    # 1. Remove VBS startup script
    if (Test-Path $VbsPath) {
        Remove-Item $VbsPath -Force
        Write-Output "Removed VBS launch script from Startup folder."
    }
    
    # 2. Remove Scheduled Task
    if ($IsAdmin) {
        if (Get-ScheduledTask -TaskPath "\" -TaskName $TaskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Write-Output "Unregistered Scheduled Task '$TaskName'."
        }
    } else {
        # If not admin, try to remove but ignore error if we can't
        try {
            if (Get-ScheduledTask -TaskPath "\" -TaskName $TaskName -ErrorAction SilentlyContinue) {
                Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
                Write-Output "Unregistered Scheduled Task '$TaskName'."
            }
        } catch {}
    }
    
    Stop-Daemon
    exit
}

# Ensure main script exists
if (-not (Test-Path $ScriptPath)) {
    Write-Error "Could not find ProcessPrioritySaver.ps1 at $ScriptPath"
    exit
}

# Stop current instances
Stop-Daemon

if ($IsAdmin) {
    Write-Output "Admin rights detected. Registering via Windows Task Scheduler with HIGHEST privileges..."
    
    # Remove VBS startup script if it exists to avoid duplicates
    if (Test-Path $VbsPath) {
        Remove-Item $VbsPath -Force
    }

    # Action: Run powershell silently
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    
    # Principal: Run with highest privileges (elevated) under current user account
    $PrincipalObj = New-ScheduledTaskPrincipal -UserId $Identity.Name -RunLevel Highest
    
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    $Settings.ExecutionTimeLimit = $null

    Register-ScheduledTask -TaskName $TaskName -Trigger $Trigger -Action $Action -Settings $Settings -Principal $PrincipalObj -Force | Out-Null
    Start-ScheduledTask -TaskName $TaskName | Out-Null

    Write-Output "Successfully registered and started Scheduled Task '$TaskName' with Highest Privileges."
} else {
    Write-Output "User rights detected. Registering via Startup folder (VBScript)..."
    
    # Try to clean up Scheduled Task if it exists
    try {
        if (Get-ScheduledTask -TaskPath "\" -TaskName $TaskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false | Out-Null
            Write-Output "Removed old Scheduled Task registration."
        }
    } catch {}

    $VbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""$ScriptPath""", 0, false
"@

    [System.IO.File]::WriteAllText($VbsPath, $VbsContent)
    Write-Output "Successfully registered autostart at: $VbsPath"
    
    # Start it
    Start-Process wscript.exe -ArgumentList "`"$VbsPath`""
    Write-Output "Successfully started. Running silently in the background."
}
