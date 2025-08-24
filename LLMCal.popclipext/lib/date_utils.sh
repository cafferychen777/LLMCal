#!/bin/bash

# Date Utilities Module for LLMCal
# Handles all date/time processing with improved timezone support

# Source error handler
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Date format constants
readonly DATE_FORMAT_INPUT="%Y-%m-%d %H:%M:%S"
readonly DATE_FORMAT_OUTPUT="%Y-%m-%d %H:%M:%S"
readonly DATE_FORMAT_ISO="%Y-%m-%dT%H:%M:%S%z"
readonly DATE_FORMAT_SIMPLE="%Y-%m-%d"
readonly TIME_FORMAT_SIMPLE="%H:%M"

# Set date utils logger
set_error_logger "date_log"

# Enhanced logging for date utils
date_log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [DATE-$level]: $message" >> "${LOG_FILE:-/tmp/llmcal.log}"
}

# Get system timezone
get_system_timezone() {
    local timezone
    
    # Try multiple methods to get system timezone
    if command -v timedatectl > /dev/null 2>&1; then
        # Linux systems with systemd
        timezone=$(timedatectl show --property=Timezone --value 2>/dev/null)
    elif [ -f /etc/timezone ]; then
        # Linux systems with /etc/timezone
        timezone=$(cat /etc/timezone 2>/dev/null)
    elif [ -L /etc/localtime ]; then
        # Systems with symlinked /etc/localtime
        timezone=$(readlink /etc/localtime | sed 's|.*/zoneinfo/||')
    elif command -v systemsetup > /dev/null 2>&1; then
        # macOS systems
        timezone=$(systemsetup -gettimezone 2>/dev/null | awk '{print $3}')
    fi
    
    # Fallback to common timezone patterns
    if [ -z "$timezone" ] || [ "$timezone" = "n/a" ]; then
        # Try to guess from date command
        local date_output
        date_output=$(date "+%Z %z" 2>/dev/null)
        
        case "$date_output" in
            *EST*|*EDT*) timezone="America/New_York";;
            *CST*|*CDT*) timezone="America/Chicago";;
            *MST*|*MDT*) timezone="America/Denver";;
            *PST*|*PDT*) timezone="America/Los_Angeles";;
            *UTC*|*GMT*) timezone="UTC";;
            *) timezone="UTC";;  # Final fallback
        esac
    fi
    
    date_log "INFO" "Detected system timezone: $timezone"
    echo "$timezone"
}

# Validate timezone
validate_timezone() {
    local timezone="$1"
    
    if [ -z "$timezone" ]; then
        handle_error $ERR_TIMEZONE_INVALID "Timezone is empty"
        return $ERR_TIMEZONE_INVALID
    fi
    
    # Test timezone by trying to use it
    if TZ="$timezone" date > /dev/null 2>&1; then
        date_log "INFO" "Timezone validation successful: $timezone"
        return $ERR_SUCCESS
    else
        date_log "WARN" "Invalid timezone: $timezone, falling back to system default"
        handle_error $ERR_TIMEZONE_INVALID "Invalid timezone: $timezone"
        return $ERR_TIMEZONE_INVALID
    fi
}

# Get current date references
get_date_references() {
    local timezone="${1:-$(get_system_timezone)}"
    
    date_log "INFO" "Getting date references for timezone: $timezone"
    
    local today tomorrow day_after_tomorrow next_wednesday
    
    if validate_timezone "$timezone"; then
        export TZ="$timezone"
        
        today=$(date "+$DATE_FORMAT_SIMPLE")
        tomorrow=$(date -v+1d "+$DATE_FORMAT_SIMPLE" 2>/dev/null || date -d "+1 day" "+$DATE_FORMAT_SIMPLE" 2>/dev/null)
        day_after_tomorrow=$(date -v+2d "+$DATE_FORMAT_SIMPLE" 2>/dev/null || date -d "+2 days" "+$DATE_FORMAT_SIMPLE" 2>/dev/null)
        next_wednesday=$(date -v+wed "+$DATE_FORMAT_SIMPLE" 2>/dev/null || date -d "next wednesday" "+$DATE_FORMAT_SIMPLE" 2>/dev/null)
    else
        # Use system default timezone
        today=$(date "+$DATE_FORMAT_SIMPLE")
        tomorrow=$(date -v+1d "+$DATE_FORMAT_SIMPLE" 2>/dev/null || date -d "+1 day" "+$DATE_FORMAT_SIMPLE" 2>/dev/null)
        day_after_tomorrow=$(date -v+2d "+$DATE_FORMAT_SIMPLE" 2>/dev/null || date -d "+2 days" "+$DATE_FORMAT_SIMPLE" 2>/dev/null)
        next_wednesday=$(date -v+wed "+$DATE_FORMAT_SIMPLE" 2>/dev/null || date -d "next wednesday" "+$DATE_FORMAT_SIMPLE" 2>/dev/null)
    fi
    
    # Validate results
    if [ -z "$today" ] || [ -z "$tomorrow" ]; then
        handle_error $ERR_DATE_CONVERSION_FAILED "Failed to generate date references"
        return $ERR_DATE_CONVERSION_FAILED
    fi
    
    # Create JSON output
    cat << EOF
{
    "today": "$today",
    "tomorrow": "$tomorrow",
    "day_after_tomorrow": "$day_after_tomorrow",
    "next_wednesday": "$next_wednesday",
    "timezone": "$timezone"
}
EOF
    
    return $ERR_SUCCESS
}

# Convert datetime format
convert_datetime() {
    local input_datetime="$1"
    local input_format="${2:-auto}"
    local output_format="${3:-$DATE_FORMAT_OUTPUT}"
    local timezone="${4:-$(get_system_timezone)}"
    
    date_log "INFO" "Converting datetime: $input_datetime"
    
    if [ -z "$input_datetime" ]; then
        handle_error $ERR_DATE_FORMAT_INVALID "Input datetime is empty"
        return $ERR_DATE_FORMAT_INVALID
    fi
    
    # Clean input datetime
    local cleaned_datetime
    cleaned_datetime=$(echo "$input_datetime" | tr -d '"' | sed 's/\([0-9][0-9]:[0-9][0-9]\)$/\1:00/')
    
    local converted_datetime
    
    # Set timezone if valid
    if validate_timezone "$timezone"; then
        export TZ="$timezone"
    fi
    
    # Auto-detect format or use specified format
    if [ "$input_format" = "auto" ]; then
        # Try common formats
        if [[ "$cleaned_datetime" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
            input_format="$DATE_FORMAT_INPUT"
        elif [[ "$cleaned_datetime" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}$ ]]; then
            cleaned_datetime="$cleaned_datetime:00"
            input_format="$DATE_FORMAT_INPUT"
        else
            handle_error $ERR_DATE_FORMAT_INVALID "Unrecognized datetime format: $cleaned_datetime"
            return $ERR_DATE_FORMAT_INVALID
        fi
    fi
    
    # Convert using date command (with fallback for different systems)
    if date -j -f "$input_format" "$cleaned_datetime" "+$output_format" > /dev/null 2>&1; then
        # macOS/BSD date
        converted_datetime=$(date -j -f "$input_format" "$cleaned_datetime" "+$output_format")
    elif date -d "$cleaned_datetime" "+$output_format" > /dev/null 2>&1; then
        # GNU date
        converted_datetime=$(date -d "$cleaned_datetime" "+$output_format")
    else
        handle_error $ERR_DATE_CONVERSION_FAILED "Failed to convert datetime: $cleaned_datetime"
        return $ERR_DATE_CONVERSION_FAILED
    fi
    
    if [ -z "$converted_datetime" ]; then
        handle_error $ERR_DATE_CONVERSION_FAILED "Date conversion returned empty result"
        return $ERR_DATE_CONVERSION_FAILED
    fi
    
    date_log "INFO" "Successfully converted: $input_datetime -> $converted_datetime"
    echo "$converted_datetime"
    return $ERR_SUCCESS
}

# Convert to ISO 8601 format
convert_to_iso() {
    local datetime="$1"
    local timezone="${2:-$(get_system_timezone)}"
    
    date_log "INFO" "Converting to ISO format: $datetime"
    
    local iso_datetime
    iso_datetime=$(convert_datetime "$datetime" "auto" "$DATE_FORMAT_ISO" "$timezone")
    local result=$?
    
    if [ $result -ne $ERR_SUCCESS ]; then
        return $result
    fi
    
    # Ensure proper ISO format (add timezone if missing)
    if [[ ! "$iso_datetime" =~ [+-][0-9]{4}$ ]] && [[ ! "$iso_datetime" =~ Z$ ]]; then
        # Add timezone offset
        local tz_offset
        tz_offset=$(date "+%z")
        iso_datetime="$iso_datetime$tz_offset"
    fi
    
    echo "$iso_datetime"
    return $ERR_SUCCESS
}

# Calculate duration between two datetimes
calculate_duration() {
    local start_datetime="$1"
    local end_datetime="$2"
    local unit="${3:-minutes}"  # minutes, hours, seconds
    
    date_log "INFO" "Calculating duration: $start_datetime to $end_datetime"
    
    # Convert to seconds since epoch
    local start_seconds end_seconds
    
    if command -v date > /dev/null 2>&1; then
        if date -j > /dev/null 2>&1; then
            # macOS/BSD date
            start_seconds=$(date -j -f "$DATE_FORMAT_INPUT" "$start_datetime" "+%s" 2>/dev/null)
            end_seconds=$(date -j -f "$DATE_FORMAT_INPUT" "$end_datetime" "+%s" 2>/dev/null)
        else
            # GNU date
            start_seconds=$(date -d "$start_datetime" "+%s" 2>/dev/null)
            end_seconds=$(date -d "$end_datetime" "+%s" 2>/dev/null)
        fi
    fi
    
    if [ -z "$start_seconds" ] || [ -z "$end_seconds" ]; then
        handle_error $ERR_DATE_CONVERSION_FAILED "Failed to convert datetimes to seconds"
        return $ERR_DATE_CONVERSION_FAILED
    fi
    
    local duration_seconds=$((end_seconds - start_seconds))
    
    if [ $duration_seconds -lt 0 ]; then
        date_log "WARN" "Negative duration detected: $duration_seconds seconds"
    fi
    
    local duration
    case "$unit" in
        "seconds") duration=$duration_seconds;;
        "minutes") duration=$((duration_seconds / 60));;
        "hours") duration=$((duration_seconds / 3600));;
        *) duration=$duration_seconds;;  # Default to seconds
    esac
    
    date_log "INFO" "Duration calculated: $duration $unit"
    echo "$duration"
    return $ERR_SUCCESS
}

# Parse relative date expressions
parse_relative_date() {
    local expression="$1"
    local base_date="${2:-$(date "+$DATE_FORMAT_SIMPLE")}"
    local timezone="${3:-$(get_system_timezone)}"
    
    date_log "INFO" "Parsing relative date: $expression from $base_date"
    
    # Set timezone
    if validate_timezone "$timezone"; then
        export TZ="$timezone"
    fi
    
    local result_date
    
    # Handle common relative expressions
    case "$expression" in
        "today") result_date="$base_date";;
        "tomorrow") 
            result_date=$(date -v+1d -j -f "$DATE_FORMAT_SIMPLE" "$base_date" "+$DATE_FORMAT_SIMPLE" 2>/dev/null || \
                         date -d "$base_date +1 day" "+$DATE_FORMAT_SIMPLE" 2>/dev/null);;
        "yesterday") 
            result_date=$(date -v-1d -j -f "$DATE_FORMAT_SIMPLE" "$base_date" "+$DATE_FORMAT_SIMPLE" 2>/dev/null || \
                         date -d "$base_date -1 day" "+$DATE_FORMAT_SIMPLE" 2>/dev/null);;
        "next week"|"next monday") 
            result_date=$(date -v+mon -j -f "$DATE_FORMAT_SIMPLE" "$base_date" "+$DATE_FORMAT_SIMPLE" 2>/dev/null || \
                         date -d "$base_date next monday" "+$DATE_FORMAT_SIMPLE" 2>/dev/null);;
        "next friday") 
            result_date=$(date -v+fri -j -f "$DATE_FORMAT_SIMPLE" "$base_date" "+$DATE_FORMAT_SIMPLE" 2>/dev/null || \
                         date -d "$base_date next friday" "+$DATE_FORMAT_SIMPLE" 2>/dev/null);;
        *) 
            # Try to parse as a direct date
            result_date=$(convert_datetime "$expression" "auto" "$DATE_FORMAT_SIMPLE" "$timezone" 2>/dev/null)
            ;;
    esac
    
    if [ -z "$result_date" ]; then
        handle_error $ERR_DATE_FORMAT_INVALID "Cannot parse relative date: $expression"
        return $ERR_DATE_FORMAT_INVALID
    fi
    
    date_log "INFO" "Parsed relative date: $expression -> $result_date"
    echo "$result_date"
    return $ERR_SUCCESS
}

# Validate datetime string
validate_datetime() {
    local datetime="$1"
    local format="${2:-auto}"
    
    if [ -z "$datetime" ]; then
        handle_error $ERR_DATE_FORMAT_INVALID "Datetime is empty"
        return $ERR_DATE_FORMAT_INVALID
    fi
    
    # Try to convert - if it succeeds, it's valid
    local converted
    converted=$(convert_datetime "$datetime" "$format" "$DATE_FORMAT_OUTPUT" 2>/dev/null)
    
    if [ $? -eq $ERR_SUCCESS ] && [ -n "$converted" ]; then
        date_log "INFO" "Datetime validation successful: $datetime"
        return $ERR_SUCCESS
    else
        handle_error $ERR_DATE_FORMAT_INVALID "Invalid datetime format: $datetime"
        return $ERR_DATE_FORMAT_INVALID
    fi
}

# Get timezone offset
get_timezone_offset() {
    local timezone="${1:-$(get_system_timezone)}"
    
    if validate_timezone "$timezone"; then
        export TZ="$timezone"
    fi
    
    local offset
    offset=$(date "+%z")
    
    date_log "INFO" "Timezone offset for $timezone: $offset"
    echo "$offset"
    return $ERR_SUCCESS
}

# Format duration for display
format_duration_display() {
    local minutes="$1"
    
    if [ -z "$minutes" ] || ! [[ "$minutes" =~ ^[0-9]+$ ]]; then
        echo "Unknown duration"
        return $ERR_DATE_FORMAT_INVALID
    fi
    
    local hours=$((minutes / 60))
    local remaining_minutes=$((minutes % 60))
    
    if [ $hours -eq 0 ]; then
        echo "${minutes}m"
    elif [ $remaining_minutes -eq 0 ]; then
        echo "${hours}h"
    else
        echo "${hours}h ${remaining_minutes}m"
    fi
    
    return $ERR_SUCCESS
}

# Export functions for use in other modules
export -f get_system_timezone validate_timezone get_date_references convert_datetime
export -f convert_to_iso calculate_duration parse_relative_date validate_datetime
export -f get_timezone_offset format_duration_display