# Windows Scheduled Task Script - Claude Auto Reset
# Runs every 5 hours to match Claude's reset cycle

param(
    [switch]$Setup
)

# =========================== Configuration ===========================
# Command to execute (modify to your actual command)
$commandToRun = "claude -p 'hi'"

# Daily execution times (24-hour format: HH:mm)
# Set to run every 5 hours to match Claude's reset cycle
$scheduleTimes = @(
    "07:30",  # Start of workday
    "12:30",  # Midday (7:30 + 5 hours)
    "17:30",  # Afternoon (12:30 + 5 hours)
    "22:30"   # Evening (17:30 + 5 hours)
)

# Log file path
$logFile = "$PSScriptRoot\scheduled_task.log"

# =========================== Functions ===========================
function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage -Encoding UTF8
}

function Test-ShouldRun {
    $currentTime = Get-Date -Format "HH:mm"
    return $scheduleTimes -contains $currentTime
}

function Execute-Command {
    try {
        Write-Log "Starting command execution: $commandToRun"

        # Execute command with output capture
        $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $commandToRun" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "output.log" -RedirectStandardError "error.log"

        # Option 2: Show window (uncomment the line below if you want to see the command window)
        # $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $commandToRun" -Wait -PassThru

        # Read output if available
        if (Test-Path "output.log") {
            $output = Get-Content "output.log" -Raw
            if ($output) {
                Write-Log "Command output: $output"
            }
        }

        # Read error if available
        if (Test-Path "error.log") {
            $errorOutput = Get-Content "error.log" -Raw
            if ($errorOutput) {
                Write-Log "Command error: $errorOutput"
            }
        }

        if ($process.ExitCode -eq 0) {
            Write-Log "Command executed successfully"
        } else {
            Write-Log "Command execution failed with exit code: $($process.ExitCode)"
        }
    }
    catch {
        Write-Log "Error executing command: $($_.Exception.Message)"
    }
}

function Setup-ScheduledTasks {
    Write-Log "Setting up Windows Task Scheduler..."

    $scriptPath = $MyInvocation.MyCommand.Path
    $taskName = "ClaudeAutoReset"

    # Delete existing tasks if they exist
    try {
        schtasks /delete /tn $taskName /f 2>$null
        Write-Log "Deleted existing scheduled tasks"
    } catch {
        # Task doesn't exist, ignore error
    }

    # Create tasks for each time slot
    for ($i = 0; $i -lt $scheduleTimes.Length; $i++) {
        $time = $scheduleTimes[$i]
        $timeFormatted = $time.Replace(":", "")
        $taskNameWithTime = "Claude_$timeFormatted"

        # Delete existing specific time tasks
        try {
            schtasks /delete /tn $taskNameWithTime /f 2>$null
        } catch {
            # Ignore errors
        }

        # Create new scheduled task
        try {
            $action = "powershell.exe -ExecutionPolicy Bypass -File `"$scriptPath`""
            schtasks /create /sc daily /st $time /tn "$taskNameWithTime" /tr "$action" /f
            Write-Log "Created scheduled task: $taskNameWithTime (daily at $time)"
        } catch {
            Write-Log "Failed to create task: $taskNameWithTime - $($_.Exception.Message)"
        }
    }

    Write-Log "Task Scheduler setup completed"
}

# =========================== Main Program ===========================
Write-Log "=== Claude Auto Reset Script Started ==="

# Check if setup mode
if ($Setup) {
    Setup-ScheduledTasks
    exit
}

# Check if command should be executed
if (Test-ShouldRun) {
    Write-Log "Current time matches schedule, starting execution..."
    Execute-Command
} else {
    Write-Log "Current time is not in schedule, skipping execution"
}

Write-Log "=== Script Execution Completed ==="
