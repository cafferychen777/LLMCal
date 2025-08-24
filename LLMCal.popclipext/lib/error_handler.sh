#!/bin/bash

# Error Handler Module for LLMCal
# Provides comprehensive error handling with detailed error codes and recovery mechanisms

# Error codes
readonly ERR_SUCCESS=0
readonly ERR_GENERAL=1
readonly ERR_API_KEY_MISSING=10
readonly ERR_API_REQUEST_FAILED=11
readonly ERR_API_RESPONSE_INVALID=12
readonly ERR_API_RATE_LIMITED=13
readonly ERR_ZOOM_TOKEN_FAILED=20
readonly ERR_ZOOM_MEETING_FAILED=21
readonly ERR_ZOOM_CREDENTIALS_MISSING=22
readonly ERR_JSON_PARSE_FAILED=30
readonly ERR_JSON_VALIDATION_FAILED=31
readonly ERR_DATE_CONVERSION_FAILED=40
readonly ERR_DATE_FORMAT_INVALID=41
readonly ERR_TIMEZONE_INVALID=42
readonly ERR_CALENDAR_CREATION_FAILED=50
readonly ERR_APPLESCRIPT_FAILED=51
readonly ERR_FILE_NOT_FOUND=60
readonly ERR_PERMISSION_DENIED=61
readonly ERR_NETWORK_UNAVAILABLE=70
readonly ERR_DEPENDENCY_MISSING=80

# Error messages mapping
declare -A ERROR_MESSAGES=(
    [$ERR_SUCCESS]="Operation completed successfully"
    [$ERR_GENERAL]="General error occurred"
    [$ERR_API_KEY_MISSING]="Anthropic API key is missing or invalid"
    [$ERR_API_REQUEST_FAILED]="Failed to send request to Anthropic API"
    [$ERR_API_RESPONSE_INVALID]="Invalid response from Anthropic API"
    [$ERR_API_RATE_LIMITED]="API rate limit exceeded"
    [$ERR_ZOOM_TOKEN_FAILED]="Failed to obtain Zoom access token"
    [$ERR_ZOOM_MEETING_FAILED]="Failed to create Zoom meeting"
    [$ERR_ZOOM_CREDENTIALS_MISSING]="Zoom API credentials are missing"
    [$ERR_JSON_PARSE_FAILED]="Failed to parse JSON data"
    [$ERR_JSON_VALIDATION_FAILED]="JSON data validation failed"
    [$ERR_DATE_CONVERSION_FAILED]="Failed to convert date format"
    [$ERR_DATE_FORMAT_INVALID]="Invalid date format provided"
    [$ERR_TIMEZONE_INVALID]="Invalid timezone specified"
    [$ERR_CALENDAR_CREATION_FAILED]="Failed to create calendar event"
    [$ERR_APPLESCRIPT_FAILED]="AppleScript execution failed"
    [$ERR_FILE_NOT_FOUND]="Required file not found"
    [$ERR_PERMISSION_DENIED]="Permission denied"
    [$ERR_NETWORK_UNAVAILABLE]="Network connection unavailable"
    [$ERR_DEPENDENCY_MISSING]="Required dependency is missing"
)

# User-friendly error messages
declare -A USER_ERROR_MESSAGES=(
    [$ERR_SUCCESS]="✅ Calendar event created successfully!"
    [$ERR_GENERAL]="❌ An unexpected error occurred. Please try again."
    [$ERR_API_KEY_MISSING]="🔑 Please check your Anthropic API key in PopClip settings."
    [$ERR_API_REQUEST_FAILED]="🌐 Unable to connect to AI service. Check your internet connection."
    [$ERR_API_RESPONSE_INVALID]="🤖 AI service returned an invalid response. Please try again."
    [$ERR_API_RATE_LIMITED]="⏳ Too many requests. Please wait a moment and try again."
    [$ERR_ZOOM_TOKEN_FAILED]="🔐 Unable to authenticate with Zoom. Check your Zoom credentials."
    [$ERR_ZOOM_MEETING_FAILED]="📹 Failed to create Zoom meeting. Event will be created without meeting link."
    [$ERR_ZOOM_CREDENTIALS_MISSING]="⚙️ Zoom integration requires API credentials in PopClip settings."
    [$ERR_JSON_PARSE_FAILED]="📄 Unable to process AI response. Please try again."
    [$ERR_JSON_VALIDATION_FAILED]="📝 AI response is missing required information. Please try again."
    [$ERR_DATE_CONVERSION_FAILED]="📅 Unable to process date information. Please check your input."
    [$ERR_DATE_FORMAT_INVALID]="🕐 Invalid date format detected. Please check your input."
    [$ERR_TIMEZONE_INVALID]="🌍 Invalid timezone. Using system default."
    [$ERR_CALENDAR_CREATION_FAILED]="📆 Unable to create calendar event. Check Calendar app permissions."
    [$ERR_APPLESCRIPT_FAILED]="⚙️ System integration failed. Check Calendar app permissions."
    [$ERR_FILE_NOT_FOUND]="📁 Required file is missing. Please reinstall the extension."
    [$ERR_PERMISSION_DENIED]="🔒 Permission denied. Check app permissions in System Preferences."
    [$ERR_NETWORK_UNAVAILABLE]="🌐 No internet connection available."
    [$ERR_DEPENDENCY_MISSING]="🛠️ Required system component is missing."
)

# Recovery suggestions
declare -A RECOVERY_SUGGESTIONS=(
    [$ERR_API_KEY_MISSING]="1. Open PopClip preferences\n2. Find LLMCal extension settings\n3. Enter your Anthropic API key"
    [$ERR_API_REQUEST_FAILED]="1. Check your internet connection\n2. Try again in a few moments\n3. Verify API key is correct"
    [$ERR_API_RATE_LIMITED]="1. Wait 60 seconds before trying again\n2. Consider using fewer requests"
    [$ERR_ZOOM_CREDENTIALS_MISSING]="1. Go to PopClip settings for LLMCal\n2. Enter Zoom API credentials\n3. Or remove 'zoom' from your text"
    [$ERR_CALENDAR_CREATION_FAILED]="1. Open System Preferences → Security & Privacy\n2. Grant Calendar access to PopClip\n3. Restart PopClip"
    [$ERR_NETWORK_UNAVAILABLE]="1. Check your internet connection\n2. Try again when connected"
    [$ERR_DEPENDENCY_MISSING]="1. Ensure jq is installed: brew install jq\n2. Ensure Python 3 is available\n3. Reinstall the extension"
)

# Global error state
ERROR_CODE=$ERR_SUCCESS
ERROR_MESSAGE=""
ERROR_CONTEXT=""

# Logger reference (will be set by main script)
LOGGER_FUNCTION=""

# Set logger function
set_error_logger() {
    LOGGER_FUNCTION="$1"
}

# Enhanced logging function
error_log() {
    local message="$1"
    local level="${2:-ERROR}"
    
    if [ -n "$LOGGER_FUNCTION" ] && command -v "$LOGGER_FUNCTION" > /dev/null 2>&1; then
        "$LOGGER_FUNCTION" "$level" "$message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') [$level]: $message" >&2
    fi
}

# Set error state
set_error() {
    local code="$1"
    local context="${2:-}"
    
    ERROR_CODE="$code"
    ERROR_MESSAGE="${ERROR_MESSAGES[$code]:-Unknown error}"
    ERROR_CONTEXT="$context"
    
    error_log "Error $code: $ERROR_MESSAGE${context:+ ($context)}"
}

# Get error information
get_error_code() {
    echo "$ERROR_CODE"
}

get_error_message() {
    echo "$ERROR_MESSAGE"
}

get_user_error_message() {
    echo "${USER_ERROR_MESSAGES[$ERROR_CODE]:-❌ An error occurred}"
}

get_error_context() {
    echo "$ERROR_CONTEXT"
}

# Check if there's an error
has_error() {
    [ "$ERROR_CODE" -ne "$ERR_SUCCESS" ]
}

# Clear error state
clear_error() {
    ERROR_CODE=$ERR_SUCCESS
    ERROR_MESSAGE=""
    ERROR_CONTEXT=""
}

# Display user notification
show_error_notification() {
    local title="${1:-LLMCal Error}"
    local user_message="$(get_user_error_message)"
    
    if command -v osascript > /dev/null 2>&1; then
        osascript -e "display notification \"$user_message\" with title \"$title\""
    else
        error_log "Notification: $user_message" "INFO"
    fi
}

# Show recovery suggestion
show_recovery_suggestion() {
    local suggestion="${RECOVERY_SUGGESTIONS[$ERROR_CODE]:-}"
    
    if [ -n "$suggestion" ]; then
        error_log "Recovery suggestion:\n$suggestion" "INFO"
        
        if command -v osascript > /dev/null 2>&1; then
            osascript -e "display dialog \"$suggestion\" with title \"How to fix this:\" buttons {\"OK\"} default button \"OK\""
        fi
    fi
}

# Comprehensive error handler
handle_error() {
    local code="$1"
    local context="${2:-}"
    local show_notification="${3:-true}"
    local show_recovery="${4:-false}"
    
    set_error "$code" "$context"
    
    if [ "$show_notification" = "true" ]; then
        show_error_notification
    fi
    
    if [ "$show_recovery" = "true" ]; then
        show_recovery_suggestion
    fi
    
    return "$code"
}

# Retry mechanism
retry_operation() {
    local operation="$1"
    local max_attempts="${2:-3}"
    local delay="${3:-2}"
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        error_log "Attempting $operation (try $attempt/$max_attempts)" "INFO"
        
        if eval "$operation"; then
            error_log "$operation succeeded on attempt $attempt" "INFO"
            return $ERR_SUCCESS
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            error_log "$operation failed on attempt $attempt, retrying in ${delay}s..." "WARN"
            sleep "$delay"
        else
            error_log "$operation failed after $max_attempts attempts" "ERROR"
            return $ERR_GENERAL
        fi
        
        attempt=$((attempt + 1))
    done
}

# Validate dependencies
validate_dependencies() {
    local missing_deps=()
    
    # Check for required commands
    local required_commands=("curl" "jq" "python3" "osascript" "date")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" > /dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        set_error $ERR_DEPENDENCY_MISSING "Missing: ${missing_deps[*]}"
        return $ERR_DEPENDENCY_MISSING
    fi
    
    return $ERR_SUCCESS
}

# Validate API key
validate_api_key() {
    local api_key="$1"
    
    if [ -z "$api_key" ]; then
        set_error $ERR_API_KEY_MISSING "API key is empty"
        return $ERR_API_KEY_MISSING
    fi
    
    # Check API key format (Anthropic keys start with 'sk-ant-')
    if [[ ! "$api_key" =~ ^sk-ant- ]]; then
        set_error $ERR_API_KEY_MISSING "Invalid API key format"
        return $ERR_API_KEY_MISSING
    fi
    
    return $ERR_SUCCESS
}

# Network connectivity check
check_network() {
    if ! curl -s --connect-timeout 5 https://www.google.com > /dev/null 2>&1; then
        set_error $ERR_NETWORK_UNAVAILABLE "Unable to reach external services"
        return $ERR_NETWORK_UNAVAILABLE
    fi
    
    return $ERR_SUCCESS
}

# Graceful shutdown
graceful_exit() {
    local exit_code="${1:-$ERROR_CODE}"
    
    if has_error; then
        error_log "Exiting with error code $exit_code: $(get_error_message)"
        show_error_notification
    fi
    
    # Cleanup temporary files
    cleanup_temp_files
    
    exit "$exit_code"
}

# Cleanup temporary files
cleanup_temp_files() {
    # Remove any temporary files created by the application
    find /tmp -name "llmcal_*" -mtime +1 -delete 2>/dev/null || true
    find /tmp -name "process_event.py" -delete 2>/dev/null || true
}

# Emergency recovery mode
emergency_recovery() {
    error_log "Entering emergency recovery mode" "WARN"
    
    # Clear any partial state
    cleanup_temp_files
    
    # Reset error state
    clear_error
    
    # Show recovery dialog
    if command -v osascript > /dev/null 2>&1; then
        osascript -e 'display dialog "LLMCal encountered an issue and has been reset. Please try your request again." with title "LLMCal Recovery" buttons {"OK"} default button "OK"'
    fi
}

# Export functions for use in other modules
export -f set_error get_error_code get_error_message get_user_error_message
export -f has_error clear_error handle_error show_error_notification
export -f retry_operation validate_dependencies validate_api_key check_network
export -f graceful_exit emergency_recovery error_log set_error_logger