#!/bin/bash

# LLMCal - AI-Powered Calendar Event Creator
# Refactored modular version with improved error handling and performance
# Version 2.0

set -euo pipefail  # Enable strict error handling

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="$SCRIPT_DIR/lib"
readonly LOG_DIR="$HOME/Library/Logs/LLMCal"
readonly LOG_FILE="$LOG_DIR/llmcal.log"

# Create log directory
mkdir -p "$LOG_DIR"

# Initialize logging
log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level]: $message" >> "$LOG_FILE"
}

# Source all library modules
source_modules() {
    local modules=(
        "error_handler.sh"
        "date_utils.sh"
        "json_parser.sh"
        "api_client.sh"
        "zoom_integration.sh"
        "calendar_creator.sh"
    )
    
    for module in "${modules[@]}"; do
        local module_path="$LIB_DIR/$module"
        if [ -f "$module_path" ]; then
            source "$module_path"
            log "INFO" "Loaded module: $module"
        else
            echo "ERROR: Required module not found: $module_path" >&2
            exit 1
        fi
    done
}

# Initialize the application
initialize() {
    log "INFO" "Starting LLMCal v2.0 - Modular version"
    log "INFO" "Processing text: $POPCLIP_TEXT"
    
    # Set up error logging for all modules
    set_error_logger "log"
    
    # Validate dependencies
    if ! validate_dependencies; then
        show_error_notification "LLMCal Setup"
        graceful_exit
    fi
    
    # Initialize JSON processor
    init_json_processor
    
    # Test calendar availability early
    if ! test_calendar_availability; then
        show_error_notification "LLMCal Calendar Access"
        show_recovery_suggestion
        graceful_exit
    fi
    
    log "INFO" "Initialization completed successfully"
}

# Get system language for internationalization
get_language() {
    local sys_lang
    sys_lang=$(defaults read .GlobalPreferences AppleLanguages 2>/dev/null | awk 'NR==2 {print $1}' | tr -d '",')
    case "$sys_lang" in
        zh*) echo "zh" ;;
        es*) echo "es" ;;
        *) echo "en" ;;
    esac
}

# Get translated text
get_translation() {
    local lang
    lang=$(get_language)
    local key="$1"
    local translations_file="$POPCLIP_BUNDLE_PATH/i18n.json"
    
    if [ -f "$translations_file" ]; then
        python3 - "$translations_file" "$lang" "$key" <<'EOF'
import sys, json
try:
    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        data = json.load(f)
    lang = sys.argv[2]
    key = sys.argv[3]
    text = data.get(lang, {}).get(key, data.get('en', {}).get(key, 'Message not found'))
    print(text)
except Exception as e:
    print(f"Translation error: {str(e)}", file=sys.stderr)
    # Fallback translations
    fallbacks = {
        'processing': 'Processing...',
        'success': 'Event added to calendar',
        'error': 'Failed to add event'
    }
    print(fallbacks.get(sys.argv[3], 'Unknown message'))
EOF
    else
        log "WARN" "Translation file not found: $translations_file"
        case "$key" in
            "processing") echo "Processing..." ;;
            "success") echo "Event added to calendar" ;;
            "error") echo "Failed to add event" ;;
            *) echo "Unknown message" ;;
        esac
    fi
}

# Show processing notification
show_processing_notification() {
    local processing_msg
    processing_msg=$(get_translation "processing")
    osascript -e "display notification \"$processing_msg\" with title \"LLMCal\"" 2>/dev/null || true
}

# Process calendar event with AI
process_event_with_ai() {
    local text="$1"
    local api_key="$2"
    
    log "INFO" "Processing event with AI: $text"
    
    # Validate API key
    if ! validate_anthropic_api_key "$api_key"; then
        return $(get_error_code)
    fi
    
    # Get date references with proper timezone handling
    local date_refs
    date_refs=$(get_date_references)
    if [ $? -ne $ERR_SUCCESS ]; then
        return $(get_error_code)
    fi
    
    local today tomorrow
    today=$(extract_json_field "$date_refs" "today")
    tomorrow=$(extract_json_field "$date_refs" "tomorrow")
    
    log "INFO" "Date references: today=$today, tomorrow=$tomorrow"
    
    # Process calendar event
    local response
    response=$(process_calendar_event "$text" "$api_key" "$today" "$tomorrow")
    if [ $? -ne $ERR_SUCCESS ]; then
        return $(get_error_code)
    fi
    
    log "INFO" "AI processing completed successfully"
    echo "$response"
    return $ERR_SUCCESS
}

# Extract and validate event data
extract_event_data() {
    local api_response="$1"
    
    log "INFO" "Extracting event data from AI response"
    
    # Process the Anthropic response
    local event_json
    event_json=$(process_anthropic_response "$api_response")
    if [ $? -ne $ERR_SUCCESS ]; then
        return $(get_error_code)
    fi
    
    # Validate event structure
    local validated_event
    validated_event=$(validate_event_json "$event_json")
    if [ $? -ne $ERR_SUCCESS ]; then
        return $(get_error_code)
    fi
    
    log "INFO" "Event data extracted and validated successfully"
    echo "$validated_event"
    return $ERR_SUCCESS
}

# Handle Zoom meeting creation if needed
handle_zoom_integration() {
    local text="$1"
    local event_data="$2"
    
    local title start_time end_time description attendees location
    title=$(extract_json_field "$event_data" "title")
    start_time=$(extract_json_field "$event_data" "start_time")
    end_time=$(extract_json_field "$event_data" "end_time")
    description=$(extract_json_field "$event_data" "description")
    location=$(extract_json_field "$event_data" "location")
    
    # Get attendees as a multi-line string
    attendees=$(extract_json_array "$event_data" "attendees")
    
    log "INFO" "Checking if Zoom meeting is needed"
    
    # Check if Zoom meeting should be created
    if should_create_zoom_meeting "$text" "$location"; then
        log "INFO" "Creating Zoom meeting"
        
        # Get Zoom credentials
        local account_id="$POPCLIP_OPTION_ZOOM_ACCOUNT_ID"
        local client_id="$POPCLIP_OPTION_ZOOM_CLIENT_ID"
        local client_secret="$POPCLIP_OPTION_ZOOM_CLIENT_SECRET"
        local contact_email="$POPCLIP_OPTION_ZOOM_EMAIL"
        local contact_name="$POPCLIP_OPTION_ZOOM_NAME"
        
        # Create Zoom meeting
        local zoom_result
        zoom_result=$(create_zoom_meeting "$title" "$start_time" "$end_time" "$description" "$attendees" "$account_id" "$client_id" "$client_secret" "$contact_email" "$contact_name")
        local zoom_status=$?
        
        if [ $zoom_status -eq $ERR_SUCCESS ]; then
            local join_url
            join_url=$(extract_json_field "$zoom_result" "join_url")
            
            if [ -n "$join_url" ]; then
                log "INFO" "Zoom meeting created successfully: $join_url"
                
                # Update event data with Zoom information
                local updated_event
                updated_event=$(echo "$event_data" | python3 -c "
import sys
import json
try:
    data = json.load(sys.stdin)
    data['url'] = '$join_url'
    data['location'] = 'Zoom Meeting'
    print(json.dumps(data))
except Exception:
    print('$event_data')
")
                echo "$updated_event"
                return $ERR_SUCCESS
            fi
        else
            log "WARN" "Zoom meeting creation failed, continuing with regular event"
            # Don't fail the entire process, just continue without Zoom
        fi
    fi
    
    # Return original event data if no Zoom meeting was created
    echo "$event_data"
    return $ERR_SUCCESS
}

# Create the calendar event
create_event() {
    local event_data="$1"
    
    log "INFO" "Creating calendar event"
    
    # Extract all event fields
    local title start_time end_time description location url alerts recurrence attendees
    title=$(extract_json_field "$event_data" "title")
    start_time=$(extract_json_field "$event_data" "start_time")
    end_time=$(extract_json_field "$event_data" "end_time")
    description=$(extract_json_field "$event_data" "description")
    location=$(extract_json_field "$event_data" "location")
    url=$(extract_json_field "$event_data" "url")
    recurrence=$(extract_json_field "$event_data" "recurrence" "none")
    
    # Get arrays
    alerts=$(extract_json_array "$event_data" "alerts")
    attendees=$(extract_json_array "$event_data" "attendees")
    
    log "INFO" "Event details: title='$title', start='$start_time', end='$end_time'"
    log "DEBUG" "Additional details: location='$location', url='$url', recurrence='$recurrence'"
    
    # Create the calendar event
    if create_calendar_event "$title" "$start_time" "$end_time" "$description" "$location" "$url" "$alerts" "$recurrence" "$attendees"; then
        log "INFO" "Calendar event created successfully"
        return $ERR_SUCCESS
    else
        log "ERROR" "Failed to create calendar event"
        return $(get_error_code)
    fi
}

# Show success notification
show_success_notification() {
    local success_msg
    success_msg=$(get_translation "success")
    osascript -e "display notification \"$success_msg\" with title \"LLMCal\"" 2>/dev/null || true
}

# Show error notification
show_error_notification_with_message() {
    local error_msg
    error_msg=$(get_translation "error")
    show_error_notification "LLMCal"
}

# Cleanup resources
cleanup() {
    log "INFO" "Cleaning up resources"
    
    # Cleanup JSON processor
    cleanup_json_processor
    
    # Clear API cache
    clear_api_cache
    
    # Cleanup Zoom cache
    cleanup_zoom_cache
    
    log "INFO" "Cleanup completed"
}

# Main execution flow
main() {
    # Initialize
    initialize
    
    # Show processing notification
    show_processing_notification
    
    # Validate required environment variables
    if [ -z "${POPCLIP_TEXT:-}" ]; then
        handle_error $ERR_GENERAL "No text provided" true true
        graceful_exit
    fi
    
    if [ -z "${POPCLIP_OPTION_ANTHROPIC_API_KEY:-}" ]; then
        handle_error $ERR_API_KEY_MISSING "Anthropic API key not configured" true true
        graceful_exit
    fi
    
    # Process the event with AI
    local api_response
    api_response=$(process_event_with_ai "$POPCLIP_TEXT" "$POPCLIP_OPTION_ANTHROPIC_API_KEY")
    local ai_result=$?
    
    if [ $ai_result -ne $ERR_SUCCESS ]; then
        show_error_notification_with_message
        show_recovery_suggestion
        graceful_exit
    fi
    
    # Extract and validate event data
    local event_data
    event_data=$(extract_event_data "$api_response")
    local extract_result=$?
    
    if [ $extract_result -ne $ERR_SUCCESS ]; then
        show_error_notification_with_message
        show_recovery_suggestion
        graceful_exit
    fi
    
    # Handle Zoom integration if needed
    event_data=$(handle_zoom_integration "$POPCLIP_TEXT" "$event_data")
    
    # Create the calendar event
    if create_event "$event_data"; then
        show_success_notification
        log "INFO" "Event processing completed successfully"
    else
        show_error_notification_with_message
        show_recovery_suggestion
        graceful_exit
    fi
    
    # Cleanup and exit
    cleanup
    log "INFO" "LLMCal processing finished"
}

# Trap signals for graceful cleanup
trap 'cleanup; graceful_exit' EXIT INT TERM

# Source modules and run main function
source_modules
main "$@"