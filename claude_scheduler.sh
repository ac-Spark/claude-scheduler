#!/bin/bash

# Linux Scheduled Task Script - Claude Auto Reset
# Runs every 5 hours to match Claude's reset cycle

# =========================== Configuration ===========================
# Command to execute (modify to your actual command)
COMMAND_TO_RUN="claude -p 'hi'"

# Timezone setting (optional, defaults to system timezone)
# Set to "Asia/Taipei" for UTC+8, or leave empty to use system timezone
TIMEZONE="Asia/Taipei"

# Daily execution times (24-hour format: HH:MM)
# Set to run every 5 hours to match Claude's reset cycle
SCHEDULE_TIMES=(
    "07:30"  # Start of workday
    "12:30"  # Midday (7:30 + 5 hours)
    "17:30"  # Afternoon (12:30 + 5 hours)
    "22:30"  # Evening (17:30 + 5 hours)
)

# Log file path
LOG_FILE="$(dirname "$0")/scheduled_task.log"

# Output files
OUTPUT_FILE="$(dirname "$0")/output.log"
ERROR_FILE="$(dirname "$0")/error.log"

# =========================== Functions ===========================
write_log() {
    local timestamp
    if [[ -n "$TIMEZONE" ]]; then
        timestamp=$(TZ="$TIMEZONE" date '+%Y-%m-%d %H:%M:%S')
    else
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    fi
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

test_should_run() {
    local current_time
    if [[ -n "$TIMEZONE" ]]; then
        current_time=$(TZ="$TIMEZONE" date '+%H:%M')
    else
        current_time=$(date '+%H:%M')
    fi

    for time in "${SCHEDULE_TIMES[@]}"; do
        if [[ "$current_time" == "$time" ]]; then
            return 0
        fi
    done
    return 1
}

execute_command() {
    write_log "Starting command execution: $COMMAND_TO_RUN"

    # Execute command with output capture
    if eval "$COMMAND_TO_RUN" > "$OUTPUT_FILE" 2> "$ERROR_FILE"; then
        # Read output if available
        if [[ -s "$OUTPUT_FILE" ]]; then
            local output
            output=$(cat "$OUTPUT_FILE")
            write_log "Command output: $output"
        fi

        # Read error if available
        if [[ -s "$ERROR_FILE" ]]; then
            local error_output
            error_output=$(cat "$ERROR_FILE")
            write_log "Command error: $error_output"
        fi

        write_log "Command executed successfully"
        return 0
    else
        local exit_code=$?
        write_log "Command execution failed with exit code: $exit_code"

        # Read error output on failure
        if [[ -s "$ERROR_FILE" ]]; then
            local error_output
            error_output=$(cat "$ERROR_FILE")
            write_log "Command error: $error_output"
        fi

        return $exit_code
    fi
}

setup_cron() {
    write_log "Setting up Linux cron jobs..."

    local script_path
    script_path=$(realpath "$0")

    # Remove existing cron jobs for this script
    crontab -l 2>/dev/null | grep -v "$script_path" | crontab -

    # Add new cron jobs
    for time in "${SCHEDULE_TIMES[@]}"; do
        local hour minute
        hour=$(echo "$time" | cut -d: -f1)
        minute=$(echo "$time" | cut -d: -f2)

        # Create cron job with timezone support
        if [[ -n "$TIMEZONE" ]]; then
            # Use TZ environment variable for timezone
            (crontab -l 2>/dev/null; echo "TZ=$TIMEZONE $minute $hour * * * $script_path") | crontab -
        else
            # Use system timezone
            (crontab -l 2>/dev/null; echo "$minute $hour * * * $script_path") | crontab -
        fi

        write_log "Added cron job: $time daily"
    done

    write_log "Cron setup completed"
    write_log "Current cron jobs:"
    crontab -l | tee -a "$LOG_FILE"
}

# =========================== Main Program ===========================
write_log "=== Claude Auto Reset Script Started ==="

# Check if setup mode
if [[ "$1" == "setup" ]]; then
    setup_cron
    exit 0
fi

# Check if command should be executed
if test_should_run; then
    write_log "Current time matches schedule, starting execution..."
    execute_command
else
    write_log "Current time is not in schedule, skipping execution"
fi

write_log "=== Script Execution Completed ==="
