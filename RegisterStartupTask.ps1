# RegisterStartupTask.ps1
# Helper script to register/unregister the Process Priority Saver as a Windows Scheduled Task.

param (
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"
$TaskName = "ProcessPrioritySaver"

# Tasks can be registered for the current user without Administrator privileges.

if ($Uninstall) {
    Write-Output "Uninstalling scheduled task '$TaskName'..."
    if (Get-ScheduledTask -TaskPath "\" -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Output "Successfully unregistered '$TaskName'."
    } else {
        Write-Output "Task '$TaskName' is not registered."
    }
    exit
}

# Register the task
$ScriptPath = Join-Path $PSScriptRoot "ProcessPrioritySaver.ps1"
if (-not (Test-Path $ScriptPath)) {
    Write-Error "Could not find ProcessPrioritySaver.ps1 at $ScriptPath"
    exit
}

Write-Output "Registering scheduled task '$TaskName' to run at logon..."

# Action: Run powershell silently
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""

# Trigger: At logon of the current user
$Trigger = New-ScheduledTaskTrigger -AtLogOn

# Settings: Allow on battery, don't stop after 3 days
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
# Set ExecutionTimeLimit to 0 (disabled) to prevent task from stopping after 72 hours
$Settings.ExecutionTimeLimit = [System.TimeSpan]::Zero

# Register
Register-ScheduledTask -TaskName $TaskName -Trigger $Trigger -Action $Action -Settings $Settings -Force

# Start task immediately
Start-ScheduledTask -TaskName $TaskName

Write-Output "Successfully registered and started '$TaskName'."
Write-Output "The script is now running in the background and will start automatically at login."
