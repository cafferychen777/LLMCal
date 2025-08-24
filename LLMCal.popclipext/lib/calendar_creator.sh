#!/bin/bash

# Calendar Creator Module for LLMCal
# Handles Apple Calendar event creation via AppleScript

# Source error handler and utilities
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Calendar configuration
readonly DEFAULT_CALENDAR="calendar 1"
readonly APPLESCRIPT_TIMEOUT=30

# Set calendar logger
set_error_logger "calendar_log"

# Enhanced logging for calendar creator
calendar_log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [CALENDAR-$level]: $message" >> "${LOG_FILE:-/tmp/llmcal.log}"
}

# Validate event data structure
validate_event_data() {
    local title="$1"
    local start_time="$2"
    local end_time="$3"
    
    calendar_log "INFO" "Validating event data"
    
    if [ -z "$title" ]; then
        handle_error $ERR_CALENDAR_CREATION_FAILED "Event title is missing"
        return $ERR_CALENDAR_CREATION_FAILED
    fi
    
    if [ -z "$start_time" ]; then
        handle_error $ERR_CALENDAR_CREATION_FAILED "Start time is missing"
        return $ERR_CALENDAR_CREATION_FAILED
    fi
    
    if [ -z "$end_time" ]; then
        handle_error $ERR_CALENDAR_CREATION_FAILED "End time is missing"
        return $ERR_CALENDAR_CREATION_FAILED
    fi
    
    # Validate datetime formats
    if ! validate_datetime "$start_time"; then
        handle_error $ERR_DATE_FORMAT_INVALID "Invalid start time format: $start_time"
        return $ERR_DATE_FORMAT_INVALID
    fi
    
    if ! validate_datetime "$end_time"; then
        handle_error $ERR_DATE_FORMAT_INVALID "Invalid end time format: $end_time"
        return $ERR_DATE_FORMAT_INVALID
    fi
    
    calendar_log "INFO" "Event data validation successful"
    return $ERR_SUCCESS
}

# Escape string for AppleScript
escape_applescript_string() {
    local input="$1"
    # Escape quotes and backslashes for AppleScript
    echo "$input" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# Convert recurrence pattern to AppleScript format
convert_recurrence_pattern() {
    local recurrence="$1"
    
    case "$recurrence" in
        "daily") echo "FREQ=DAILY;INTERVAL=1";;
        "weekly") echo "FREQ=WEEKLY;INTERVAL=1";;
        "weekly_mon_wed_fri") echo "FREQ=WEEKLY;BYDAY=MO,WE,FR";;
        "weekly_tue_thu") echo "FREQ=WEEKLY;BYDAY=TU,TH";;
        "weekly_mon_tue_wed_thu_fri") echo "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR";;
        "biweekly") echo "FREQ=WEEKLY;INTERVAL=2";;
        "monthly") echo "FREQ=MONTHLY;INTERVAL=1";;
        "monthly_last_friday") echo "FREQ=MONTHLY;BYDAY=-1FR";;
        "none"|"") echo "";;
        *) 
            calendar_log "WARN" "Unknown recurrence pattern: $recurrence"
            echo ""
            ;;
    esac
}

# Generate AppleScript for date parsing
generate_date_script() {
    local datetime="$1"
    local variable_name="$2"
    
    # Extract date components
    local year month day hour minute
    year=$(echo "$datetime" | cut -d' ' -f1 | cut -d'-' -f1)
    month=$(echo "$datetime" | cut -d' ' -f1 | cut -d'-' -f2)
    day=$(echo "$datetime" | cut -d' ' -f1 | cut -d'-' -f3)
    hour=$(echo "$datetime" | cut -d' ' -f2 | cut -d':' -f1)
    minute=$(echo "$datetime" | cut -d' ' -f2 | cut -d':' -f2)
    
    cat << EOF
    set $variable_name to (current date)
    set year of $variable_name to $year
    set month of $variable_name to $month
    set day of $variable_name to $day
    set hours of $variable_name to $hour
    set minutes of $variable_name to $minute
    set seconds of $variable_name to 0
EOF
}

# Generate AppleScript for alerts
generate_alerts_script() {
    local alerts="$1"
    
    if [ -z "$alerts" ]; then
        return 0
    fi
    
    cat << 'EOF'
        tell newEvent
EOF
    
    while IFS= read -r minutes; do
        if [ -n "$minutes" ] && [[ "$minutes" =~ ^[0-9]+$ ]]; then
            echo "            make new sound alarm at end of sound alarms with properties {trigger interval:-$minutes}"
        fi
    done <<< "$alerts"
    
    cat << 'EOF'
        end tell
EOF
}

# Generate AppleScript for attendees
generate_attendees_script() {
    local attendees="$1"
    
    if [ -z "$attendees" ]; then
        return 0
    fi
    
    cat << 'EOF'
        tell newEvent
EOF
    
    while IFS= read -r email; do
        if [ -n "$email" ]; then
            local escaped_email
            escaped_email=$(escape_applescript_string "$email")
            echo "            make new attendee at end of attendees with properties {email:\"$escaped_email\"}"
        fi
    done <<< "$attendees"
    
    cat << 'EOF'
        end tell
EOF
}

# Create AppleScript for calendar event
create_applescript() {
    local title="$1"
    local start_time="$2"
    local end_time="$3"
    local description="$4"
    local location="$5"
    local url="$6"
    local alerts="$7"
    local recurrence="$8"
    local attendees="$9"
    local calendar_name="${10:-}"
    if [ -z "$calendar_name" ]; then
        calendar_name="1"  # Default to calendar 1
    fi
    local allday="${11:-false}"
    local status="${12:-confirmed}"
    local excluded_dates="${13:-}"
    
    calendar_log "INFO" "Generating AppleScript for event creation"
    
    # Escape strings for AppleScript
    local escaped_title escaped_description escaped_location escaped_url
    escaped_title=$(escape_applescript_string "$title")
    escaped_description=$(escape_applescript_string "$description")
    escaped_location=$(escape_applescript_string "$location")
    escaped_url=$(escape_applescript_string "$url")
    
    # Convert recurrence pattern
    local recurrence_rule
    recurrence_rule=$(convert_recurrence_pattern "$recurrence")
    
    # Start building the AppleScript
    cat << EOF
tell application "Calendar"
$(generate_date_script "$start_time" "startDate")
$(generate_date_script "$end_time" "endDate")
    
    tell calendar "$calendar_name"
        set eventProps to {summary:"$escaped_title", start date:startDate, end date:endDate}
EOF

    # Add optional properties
    if [ -n "$description" ]; then
        cat << EOF
        set eventProps to eventProps & {description:"$escaped_description"}
EOF
    fi
    
    if [ -n "$location" ]; then
        cat << EOF
        set eventProps to eventProps & {location:"$escaped_location"}
EOF
    fi
    
    if [ -n "$url" ]; then
        cat << EOF
        set eventProps to eventProps & {url:"$escaped_url"}
EOF
    fi
    
    if [ -n "$recurrence_rule" ]; then
        cat << EOF
        set eventProps to eventProps & {recurrence:"$recurrence_rule"}
EOF
    fi
    
    # Add all-day event property
    if [ "$allday" = "true" ]; then
        cat << EOF
        set eventProps to eventProps & {allday event:true}
EOF
    fi
    
    # Add status property (Note: macOS Calendar app doesn't support status in AppleScript)
    # Status is typically handled through calendar types or reminder flags
    # Commenting out as AppleScript doesn't recognize status as a valid property
    # if [ -n "$status" ] && [ "$status" != "confirmed" ]; then
    #     cat << EOF
    #     set eventProps to eventProps & {status:"$status"}
    # EOF
    # fi
    
    # Add excluded dates for recurring events
    if [ -n "$excluded_dates" ] && [ -n "$recurrence_rule" ]; then
        # Convert excluded dates to AppleScript date list
        local excluded_dates_script=""
        while IFS= read -r date; do
            if [ -n "$date" ]; then
                if [ -n "$excluded_dates_script" ]; then
                    excluded_dates_script="$excluded_dates_script, "
                fi
                excluded_dates_script="${excluded_dates_script}date \"$date\""
            fi
        done <<< "$excluded_dates"
        
        if [ -n "$excluded_dates_script" ]; then
            cat << EOF
        set eventProps to eventProps & {excluded dates:{$excluded_dates_script}}
EOF
        fi
    fi
    
    # Create the event
    cat << EOF
        set newEvent to make new event with properties eventProps
EOF
    
    # Add alerts if specified
    if [ -n "$alerts" ]; then
        generate_alerts_script "$alerts"
    fi
    
    # Add attendees if specified
    if [ -n "$attendees" ]; then
        generate_attendees_script "$attendees"
    fi
    
    # Close the script
    cat << EOF
    end tell
end tell
EOF
}

# Execute AppleScript with error handling
execute_applescript() {
    local script="$1"
    
    calendar_log "INFO" "Executing AppleScript"
    calendar_log "DEBUG" "AppleScript content: $script"
    
    # Check if osascript is available
    if ! command -v osascript > /dev/null 2>&1; then
        handle_error $ERR_DEPENDENCY_MISSING "osascript is not available"
        return $ERR_DEPENDENCY_MISSING
    fi
    
    # Execute the script with timeout
    local script_output script_error exit_code
    
    # Use a temporary file for the script
    local temp_script=$(mktemp)
    echo "$script" > "$temp_script"
    
    # Execute with timeout and capture both output and error
    # Check if timeout is available (gtimeout on macOS with coreutils)
    local timeout_cmd=""
    if command -v gtimeout >/dev/null 2>&1; then
        timeout_cmd="gtimeout $APPLESCRIPT_TIMEOUT"
    elif command -v timeout >/dev/null 2>&1; then
        timeout_cmd="timeout $APPLESCRIPT_TIMEOUT"
    fi
    
    # Execute the script (with or without timeout)
    if [ -n "$timeout_cmd" ]; then
        if script_output=$($timeout_cmd osascript "$temp_script" 2>&1); then
            exit_code=0
        else
            exit_code=$?
            script_error="$script_output"
        fi
    else
        if script_output=$(osascript "$temp_script" 2>&1); then
            exit_code=0
        else
            exit_code=$?
            script_error="$script_output"
        fi
    fi
    
    # Clean up temp file
    rm -f "$temp_script"
    
    if [ $exit_code -eq 0 ]; then
        calendar_log "INFO" "AppleScript executed successfully"
        if [ -n "$script_output" ]; then
            calendar_log "DEBUG" "AppleScript output: $script_output"
        fi
        return $ERR_SUCCESS
    else
        calendar_log "ERROR" "AppleScript execution failed with exit code $exit_code"
        calendar_log "ERROR" "AppleScript error: $script_error"
        
        # Parse common AppleScript errors
        case "$script_error" in
            *"User canceled"*|*"User cancelled"*)
                handle_error $ERR_APPLESCRIPT_FAILED "User cancelled the operation"
                ;;
            *"not allowed"*|*"permission denied"*|*"access denied"*)
                handle_error $ERR_PERMISSION_DENIED "Calendar access permission denied"
                ;;
            *"timeout"*|*"timed out"*)
                handle_error $ERR_APPLESCRIPT_FAILED "AppleScript execution timed out"
                ;;
            *"application isn't running"*|*"application not running"*)
                handle_error $ERR_APPLESCRIPT_FAILED "Calendar application is not running"
                ;;
            *)
                handle_error $ERR_APPLESCRIPT_FAILED "AppleScript error: $script_error"
                ;;
        esac
        
        return $ERR_APPLESCRIPT_FAILED
    fi
}

# Create calendar event (main function)
create_calendar_event() {
    local title="$1"
    local start_time="$2"
    local end_time="$3"
    local description="$4"
    local location="$5"
    local url="$6"
    local alerts="$7"
    local recurrence="$8"
    local attendees="$9"
    local calendar_name="${10:-}"
    local allday="${11:-false}"
    local status="${12:-confirmed}"
    local excluded_dates="${13:-}"
    
    calendar_log "INFO" "Creating calendar event: $title"
    
    # Validate event data
    if ! validate_event_data "$title" "$start_time" "$end_time"; then
        return $(get_error_code)
    fi
    
    # Convert datetime formats to ensure compatibility
    local start_time_converted end_time_converted
    start_time_converted=$(convert_datetime "$start_time")
    local start_result=$?
    
    if [ $start_result -ne $ERR_SUCCESS ]; then
        handle_error $ERR_DATE_CONVERSION_FAILED "Failed to convert start time"
        return $ERR_DATE_CONVERSION_FAILED
    fi
    
    end_time_converted=$(convert_datetime "$end_time")
    local end_result=$?
    
    if [ $end_result -ne $ERR_SUCCESS ]; then
        handle_error $ERR_DATE_CONVERSION_FAILED "Failed to convert end time"
        return $ERR_DATE_CONVERSION_FAILED
    fi
    
    calendar_log "INFO" "Converted times: start=$start_time_converted, end=$end_time_converted"
    
    # Generate AppleScript
    local applescript
    applescript=$(create_applescript "$title" "$start_time_converted" "$end_time_converted" "$description" "$location" "$url" "$alerts" "$recurrence" "$attendees" "$calendar_name" "$allday" "$status" "$excluded_dates")
    
    if [ -z "$applescript" ]; then
        handle_error $ERR_CALENDAR_CREATION_FAILED "Failed to generate AppleScript"
        return $ERR_CALENDAR_CREATION_FAILED
    fi
    
    # Execute AppleScript
    if execute_applescript "$applescript"; then
        calendar_log "INFO" "Calendar event created successfully"
        return $ERR_SUCCESS
    else
        calendar_log "ERROR" "Failed to create calendar event"
        return $(get_error_code)
    fi
}

# Test Calendar application availability
test_calendar_availability() {
    calendar_log "INFO" "Testing Calendar application availability"
    
    # Check if Calendar app is installed
    if ! osascript -e 'tell application "System Events" to exists application process "Calendar"' 2>/dev/null; then
        if ! osascript -e 'tell application "Calendar" to activate' 2>/dev/null; then
            handle_error $ERR_APPLESCRIPT_FAILED "Calendar application is not available"
            return $ERR_APPLESCRIPT_FAILED
        fi
    fi
    
    # Test basic Calendar access
    if osascript -e 'tell application "Calendar" to get name of every calendar' >/dev/null 2>&1; then
        calendar_log "INFO" "Calendar application is accessible"
        return $ERR_SUCCESS
    else
        handle_error $ERR_PERMISSION_DENIED "Calendar access permission required"
        return $ERR_PERMISSION_DENIED
    fi
}

# Get list of available calendars
get_available_calendars() {
    calendar_log "INFO" "Getting list of available calendars"
    
    local calendars_output
    if calendars_output=$(osascript -e 'tell application "Calendar" to get name of every calendar' 2>&1); then
        calendar_log "INFO" "Available calendars retrieved successfully"
        echo "$calendars_output"
        return $ERR_SUCCESS
    else
        calendar_log "ERROR" "Failed to get calendars: $calendars_output"
        handle_error $ERR_APPLESCRIPT_FAILED "Cannot access Calendar calendars"
        return $ERR_APPLESCRIPT_FAILED
    fi
}

# Validate calendar name exists
validate_calendar_name() {
    local calendar_name="$1"
    
    if [ -z "$calendar_name" ]; then
        return $ERR_SUCCESS  # Use default
    fi
    
    local available_calendars
    available_calendars=$(get_available_calendars 2>/dev/null)
    
    if echo "$available_calendars" | grep -q "$calendar_name"; then
        calendar_log "INFO" "Calendar name validated: $calendar_name"
        return $ERR_SUCCESS
    else
        calendar_log "WARN" "Calendar name not found: $calendar_name, using default"
        return $ERR_GENERAL  # Non-fatal, will use default
    fi
}

# Export functions for use in other modules
export -f create_calendar_event test_calendar_availability get_available_calendars
export -f validate_calendar_name validate_event_data escape_applescript_string