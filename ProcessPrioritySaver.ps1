# ProcessPrioritySaver.ps1
# Background daemon that monitors process priority changes and automatically applies saved priorities.

$ErrorActionPreference = "Stop"

# Configuration path
$ConfigPath = Join-Path $PSScriptRoot "priority_rules.json"

# Load rules
function Load-Rules {
    if (Test-Path $ConfigPath) {
        try {
            $Content = Get-Content $ConfigPath -Raw -ErrorAction SilentlyContinue
            if ([string]::IsNullOrWhiteSpace($Content)) {
                return @{}
            }
            $Json = ConvertFrom-Json $Content -AsHashtable
            if ($null -eq $Json) {
                return @{}
            }
            return $Json
        } catch {
            Write-Warning "Failed to load rules, starting fresh: $_"
            return @{}
        }
    }
    return @{}
}

# Save rules
function Save-Rules ($Rules) {
    try {
        $Json = ConvertTo-Json $Rules -Depth 10
        Set-Content -Path $ConfigPath -Value $Json -Force
    } catch {
        Write-Error "Failed to save rules to ${ConfigPath}: $_"
    }
}

# Translate priority class to string
function Get-PriorityString ($PriorityClass) {
    return [string]$PriorityClass
}

# Initialize state
$Rules = Load-Rules
$SeenProcesses = @{} # Key: PID, Value: [PSCustomObject]@{ Name; StartTime; LastPriority }

Write-Output "Process Priority Saver started. Monitoring priority changes..."
Write-Output "Rules config path: $ConfigPath"
Write-Output "Active rules: $($Rules.Keys -join ', ')"

while ($true) {
    # Get all currently running processes
    $CurrentProcesses = [System.Diagnostics.Process]::GetProcesses()
    $CurrentPids = @{}

    foreach ($Proc in $CurrentProcesses) {
        $ProcId = $Proc.Id
        $ProcName = $Proc.ProcessName
        $CurrentPids[$ProcId] = $true

        # Skip idle, system, and our own process
        if ($ProcId -eq 0 -or $ProcId -eq 4 -or $ProcName -eq "Idle" -or $ProcName -eq "System") {
            continue
        }

        try {
            $StartTime = $Proc.StartTime
            $CurrentPriority = Get-PriorityString $Proc.PriorityClass
        } catch {
            # Skip processes we don't have access to (Access Denied)
            continue
        }

        # Check if we've seen this process instance before
        $Seen = $SeenProcesses[$ProcId]
        $IsNewInstance = $true

        if ($null -ne $Seen) {
            # If start time matches, it's the same process instance
            if ($Seen.StartTime -eq $StartTime) {
                $IsNewInstance = $false
            }
        }

        if ($IsNewInstance) {
            # Process is new (or PID was reused)
            $RulePriority = $Rules[$ProcName]
            if ($null -ne $RulePriority) {
                # We have a saved rule for this process
                if ($CurrentPriority -ne $RulePriority) {
                    try {
                        $Proc.PriorityClass = $RulePriority
                        Write-Output "[$(Get-Date -Format 'HH:mm:ss')] Auto-applied priority '$RulePriority' to $ProcName (PID $ProcId)"
                        $CurrentPriority = $RulePriority
                    } catch {
                        Write-Warning "Failed to set priority '$RulePriority' for $ProcName (PID $ProcId): $_"
                    }
                }
            }
            # Track it
            $SeenProcesses[$ProcId] = [PSCustomObject]@{
                Name         = $ProcName
                StartTime    = $StartTime
                LastPriority = $CurrentPriority
            }
        } else {
            # Existing instance, check if priority changed
            if ($CurrentPriority -ne $Seen.LastPriority) {
                # Priority changed! User manually adjusted it in Task Manager
                Write-Output "[$(Get-Date -Format 'HH:mm:ss')] Detected manual priority change for $ProcName (PID $ProcId): $($Seen.LastPriority) -> $CurrentPriority"
                
                # Update rules
                if ($CurrentPriority -eq "Normal") {
                    # If changed back to Normal, remove the custom rule to keep config clean
                    if ($Rules.ContainsKey($ProcName)) {
                        $Rules.Remove($ProcName)
                        Save-Rules $Rules
                        Write-Output "[$(Get-Date -Format 'HH:mm:ss')] Removed rule for $ProcName (returned to Normal)"
                    }
                } else {
                    $Rules[$ProcName] = $CurrentPriority
                    Save-Rules $Rules
                    Write-Output "[$(Get-Date -Format 'HH:mm:ss')] Saved rule: $ProcName -> $CurrentPriority"
                }

                # Update state
                $Seen.LastPriority = $CurrentPriority
            }
        }
    }

    # Clean up SeenProcesses for processes that terminated
    $KeysToRemove = @()
    foreach ($ProcId in $SeenProcesses.Keys) {
        if (-not $CurrentPids.ContainsKey($ProcId)) {
            $KeysToRemove += $ProcId
        }
    }
    foreach ($ProcId in $KeysToRemove) {
        $SeenProcesses.Remove($ProcId)
    }

    # Sleep for 5 seconds (extremely lightweight)
    Start-Sleep -Seconds 5
}
