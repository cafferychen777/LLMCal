#!/bin/bash

# Error Handler Module for LLMCal - Bash 3.2 Compatible Version
# Works with macOS default bash (3.2)

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

# Global variables for error handling
LAST_ERROR_CODE=0
LAST_ERROR_MESSAGE=""
ERROR_LOGGER=""

# Get error message for code (using case statement instead of associative array)
get_error_message() {
    local code="$1"
    case "$code" in
        $ERR_SUCCESS) echo "Operation completed successfully" ;;
        $ERR_GENERAL) echo "General error occurred" ;;
        $ERR_API_KEY_MISSING) echo "Anthropic API key is missing or invalid" ;;
        $ERR_API_REQUEST_FAILED) echo "Failed to send request to Anthropic API" ;;
        $ERR_API_RESPONSE_INVALID) echo "Invalid response from Anthropic API" ;;
        $ERR_API_RATE_LIMITED) echo "API rate limit exceeded" ;;
        $ERR_ZOOM_TOKEN_FAILED) echo "Failed to obtain Zoom access token" ;;
        $ERR_ZOOM_MEETING_FAILED) echo "Failed to create Zoom meeting" ;;
        $ERR_ZOOM_CREDENTIALS_MISSING) echo "Zoom credentials are missing" ;;
        $ERR_JSON_PARSE_FAILED) echo "Failed to parse JSON data" ;;
        $ERR_JSON_VALIDATION_FAILED) echo "JSON validation failed" ;;
        $ERR_DATE_CONVERSION_FAILED) echo "Failed to convert date format" ;;
        $ERR_DATE_FORMAT_INVALID) echo "Invalid date format" ;;
        $ERR_TIMEZONE_INVALID) echo "Invalid timezone specified" ;;
        $ERR_CALENDAR_CREATION_FAILED) echo "Failed to create calendar event" ;;
        $ERR_APPLESCRIPT_FAILED) echo "AppleScript execution failed" ;;
        $ERR_FILE_NOT_FOUND) echo "File not found" ;;
        $ERR_PERMISSION_DENIED) echo "Permission denied" ;;
        $ERR_NETWORK_UNAVAILABLE) echo "Network connection unavailable" ;;
        $ERR_DEPENDENCY_MISSING) echo "Required dependency is missing" ;;
        *) echo "Unknown error (code: $code)" ;;
    esac
}

# Set error logger function
set_error_logger() {
    ERROR_LOGGER="$1"
}

# Log error using the configured logger
log_error() {
    local message="$1"
    if [ -n "$ERROR_LOGGER" ] && [ "$(type -t $ERROR_LOGGER)" = "function" ]; then
        $ERROR_LOGGER "ERROR" "$message"
    else
        echo "ERROR: $message" >&2
    fi
}

# Handle error with optional recovery
handle_error() {
    local error_code="$1"
    local context="${2:-}"
    local show_notification="${3:-false}"
    local attempt_recovery="${4:-false}"
    
    LAST_ERROR_CODE="$error_code"
    LAST_ERROR_MESSAGE=$(get_error_message "$error_code")
    
    if [ -n "$context" ]; then
        LAST_ERROR_MESSAGE="$LAST_ERROR_MESSAGE: $context"
    fi
    
    log_error "$LAST_ERROR_MESSAGE"
    
    if [ "$show_notification" = "true" ]; then
        show_error_notification "$LAST_ERROR_MESSAGE"
    fi
    
    if [ "$attempt_recovery" = "true" ]; then
        attempt_error_recovery "$error_code"
    fi
    
    return "$error_code"
}

# Get last error code
get_error_code() {
    echo "$LAST_ERROR_CODE"
}

# Get last error message
get_error_message_last() {
    echo "$LAST_ERROR_MESSAGE"
}

# Show error notification to user
show_error_notification() {
    local message="${1:-$LAST_ERROR_MESSAGE}"
    local title="${2:-LLMCal Error}"
    
    osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null || true
}

# Show error notification with current message
show_error_notification_with_message() {
    show_error_notification "$LAST_ERROR_MESSAGE"
}

# Attempt automatic error recovery
attempt_error_recovery() {
    local error_code="$1"
    
    case "$error_code" in
        $ERR_NETWORK_UNAVAILABLE)
            log_error "Attempting network recovery..."
            sleep 2
            if ping -c 1 google.com &>/dev/null; then
                log_error "Network connection restored"
                return 0
            fi
            ;;
        $ERR_API_RATE_LIMITED)
            log_error "Rate limited, waiting before retry..."
            sleep 5
            return 0
            ;;
        $ERR_DEPENDENCY_MISSING)
            log_error "Checking for missing dependencies..."
            validate_dependencies
            ;;
    esac
    
    return 1
}

# Validate required dependencies
validate_dependencies() {
    local missing_deps=""
    
    # Check for jq
    if ! command -v jq &>/dev/null; then
        missing_deps="$missing_deps jq"
    fi
    
    # Check for osascript (should always be present on macOS)
    if ! command -v osascript &>/dev/null; then
        missing_deps="$missing_deps osascript"
    fi
    
    # Check for curl
    if ! command -v curl &>/dev/null; then
        missing_deps="$missing_deps curl"
    fi
    
    if [ -n "$missing_deps" ]; then
        handle_error "$ERR_DEPENDENCY_MISSING" "Missing:$missing_deps"
        return "$ERR_DEPENDENCY_MISSING"
    fi
    
    return "$ERR_SUCCESS"
}

# Show recovery suggestion to user
show_recovery_suggestion() {
    local suggestion=""
    
    case "$LAST_ERROR_CODE" in
        $ERR_API_KEY_MISSING)
            suggestion="Please configure your Anthropic API key in PopClip preferences"
            ;;
        $ERR_NETWORK_UNAVAILABLE)
            suggestion="Please check your internet connection and try again"
            ;;
        $ERR_DEPENDENCY_MISSING)
            suggestion="Please install required dependencies: brew install jq"
            ;;
        $ERR_CALENDAR_CREATION_FAILED)
            suggestion="Please ensure Calendar app has necessary permissions"
            ;;
        *)
            suggestion="Please try again or check the logs for more details"
            ;;
    esac
    
    if [ -n "$suggestion" ]; then
        osascript -e "display dialog \"$suggestion\" buttons {\"OK\"} default button 1 with title \"LLMCal - Recovery Suggestion\"" 2>/dev/null || true
    fi
}

# Create error report for debugging
create_error_report() {
    local report_file="${1:-$HOME/Library/Logs/LLMCal/error_report_$(date +%Y%m%d_%H%M%S).txt}"
    local report_dir
    report_dir=$(dirname "$report_file")
    mkdir -p "$report_dir"
    
    {
        echo "LLMCal Error Report"
        echo "=================="
        echo "Date: $(date)"
        echo "Error Code: $LAST_ERROR_CODE"
        echo "Error Message: $LAST_ERROR_MESSAGE"
        echo ""
        echo "Environment:"
        echo "OS Version: $(sw_vers -productVersion 2>/dev/null || echo 'Unknown')"
        echo "Bash Version: $BASH_VERSION"
        echo ""
        echo "Dependencies:"
        echo "jq: $(command -v jq &>/dev/null && jq --version || echo 'Not installed')"
        echo "curl: $(command -v curl &>/dev/null && curl --version | head -1 || echo 'Not installed')"
    } > "$report_file"
    
    echo "$report_file"
}

# Graceful exit function
graceful_exit() {
    local exit_code="${1:-$LAST_ERROR_CODE}"
    
    if [ "$exit_code" -ne 0 ]; then
        log_error "Exiting with error code: $exit_code"
    fi
    
    exit "$exit_code"
}

# Validate API key format
validate_api_key() {
    local api_key="$1"
    
    if [ -z "$api_key" ]; then
        handle_error "$ERR_API_KEY_MISSING" "API key not provided"
        return "$ERR_API_KEY_MISSING"
    fi
    
    # Check for basic API key format (sk-ant-api03-...)
    if [[ ! "$api_key" =~ ^sk-ant-api03- ]]; then
        handle_error "$ERR_API_KEY_MISSING" "Invalid API key format"
        return "$ERR_API_KEY_MISSING"
    fi
    
    return "$ERR_SUCCESS"
}

# Check network connectivity
check_network() {
    # Check if we can reach a known endpoint
    if ! curl -s --head --connect-timeout 5 https://api.anthropic.com > /dev/null 2>&1; then
        handle_error "$ERR_NETWORK_UNAVAILABLE" "Cannot connect to API endpoint"
        return "$ERR_NETWORK_UNAVAILABLE"
    fi
    
    return "$ERR_SUCCESS"
}

# Export functions for use in other modules
export -f get_error_message
export -f handle_error
export -f show_error_notification
export -f validate_dependencies
export -f graceful_exit
export -f validate_api_key
export -f check_network