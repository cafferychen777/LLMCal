#!/bin/bash

# API Client Module for LLMCal
# Handles all API communications with Anthropic Claude API

# Source error handler
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# API Configuration
readonly ANTHROPIC_API_URL="https://api.anthropic.com/v1/messages"
readonly ANTHROPIC_API_VERSION="2023-06-01"
# Get user-selected model or use default
get_selected_model() {
    local selected_model="${POPCLIP_OPTION_CLAUDE_MODEL:-claude-sonnet-4-20250514}"
    api_log "INFO" "Using model: $selected_model"
    echo "$selected_model"
}
readonly DEFAULT_MAX_TOKENS=1024
readonly REQUEST_TIMEOUT=30
readonly MAX_RETRIES=3

# Cache directory for API responses (optional optimization)
# Using filesystem-based cache instead of associative array for Bash 3.2 compatibility
API_CACHE_DIR="/tmp/llmcal_api_cache"
mkdir -p "$API_CACHE_DIR" 2>/dev/null || true

# Set API client logger
set_error_logger "api_log"

# Enhanced logging for API client
api_log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [API-$level]: $message" >> "${LOG_FILE:-/tmp/llmcal.log}"
}

# Validate API key format and accessibility
validate_anthropic_api_key() {
    local api_key="$1"
    
    api_log "INFO" "Validating Anthropic API key"
    
    if ! validate_api_key "$api_key"; then
        return $(get_error_code)
    fi
    
    # Test API key with a minimal request
    local test_response
    test_response=$(make_api_request_internal "$api_key" "test" 10 2>&1)
    local test_result=$?
    
    if [ $test_result -ne 0 ] && [ $test_result -ne $ERR_API_RESPONSE_INVALID ]; then
        api_log "ERROR" "API key validation failed: $test_response"
        return $test_result
    fi
    
    api_log "INFO" "API key validation successful"
    return $ERR_SUCCESS
}

# Make API request with error handling and retries
make_api_request_internal() {
    local api_key="$1"
    local content="$2"
    local max_tokens="${3:-$DEFAULT_MAX_TOKENS}"
    local model="${4:-$(get_selected_model)}"
    
    # Prepare JSON payload
    local json_payload
    json_payload=$(create_api_payload "$content" "$max_tokens" "$model")
    if [ $? -ne 0 ]; then
        return $(get_error_code)
    fi
    
    api_log "INFO" "Making API request to $ANTHROPIC_API_URL"
    api_log "DEBUG" "Request payload: $json_payload"
    
    # Make the API request
    local response
    local http_code
    local temp_response=$(mktemp)
    local temp_headers=$(mktemp)
    
    # Use curl with comprehensive error handling
    http_code=$(curl -w "%{http_code}" -s \
        --max-time $REQUEST_TIMEOUT \
        --connect-timeout 10 \
        -X POST "$ANTHROPIC_API_URL" \
        -H "x-api-key: $api_key" \
        -H "anthropic-version: $ANTHROPIC_API_VERSION" \
        -H "content-type: application/json" \
        -D "$temp_headers" \
        -d "$json_payload" \
        -o "$temp_response" 2>/dev/null)
    
    local curl_result=$?
    response=$(cat "$temp_response" 2>/dev/null)
    
    # Cleanup temporary files
    rm -f "$temp_response" "$temp_headers"
    
    # Handle curl errors
    if [ $curl_result -ne 0 ]; then
        api_log "ERROR" "Curl request failed with code $curl_result"
        case $curl_result in
            6|7) handle_error $ERR_NETWORK_UNAVAILABLE "Cannot connect to Anthropic API";;
            28) handle_error $ERR_API_REQUEST_FAILED "Request timeout";;
            *) handle_error $ERR_API_REQUEST_FAILED "Curl error code: $curl_result";;
        esac
        return $(get_error_code)
    fi
    
    # Handle HTTP errors
    case "$http_code" in
        200) 
            api_log "INFO" "API request successful"
            echo "$response"
            return $ERR_SUCCESS
            ;;
        401) 
            handle_error $ERR_API_KEY_MISSING "Invalid API key"
            return $ERR_API_KEY_MISSING
            ;;
        429) 
            handle_error $ERR_API_RATE_LIMITED "Rate limit exceeded"
            return $ERR_API_RATE_LIMITED
            ;;
        400) 
            api_log "ERROR" "Bad request (400): $response"
            handle_error $ERR_API_REQUEST_FAILED "Invalid request format"
            return $ERR_API_REQUEST_FAILED
            ;;
        500|502|503|504) 
            api_log "ERROR" "Server error ($http_code): $response"
            handle_error $ERR_API_REQUEST_FAILED "Server error (HTTP $http_code)"
            return $ERR_API_REQUEST_FAILED
            ;;
        *) 
            api_log "ERROR" "Unexpected HTTP code ($http_code): $response"
            handle_error $ERR_API_REQUEST_FAILED "HTTP error: $http_code"
            return $ERR_API_REQUEST_FAILED
            ;;
    esac
}

# Create API request payload
create_api_payload() {
    local content="$1"
    local max_tokens="$2"
    local model="$3"
    
    # Escape content for JSON
    local escaped_content
    escaped_content=$(printf '%s' "$content" | python3 -c "
import sys
import json
content = sys.stdin.read()
print(json.dumps(content), end='')
")
    
    if [ $? -ne 0 ]; then
        handle_error $ERR_JSON_PARSE_FAILED "Failed to escape content for JSON"
        return $ERR_JSON_PARSE_FAILED
    fi
    
    # Create the payload
    local payload="{
        \"model\": \"$model\",
        \"max_tokens\": $max_tokens,
        \"messages\": [{
            \"role\": \"user\",
            \"content\": $escaped_content
        }]
    }"
    
    echo "$payload"
    return $ERR_SUCCESS
}

# Make API request with retry logic
make_anthropic_request() {
    local api_key="$1"
    local content="$2"
    local max_tokens="${3:-$DEFAULT_MAX_TOKENS}"
    local model="${4:-$(get_selected_model)}"
    
    api_log "INFO" "Starting Anthropic API request"
    
    # Validate inputs
    if [ -z "$api_key" ]; then
        handle_error $ERR_API_KEY_MISSING "API key not provided"
        return $ERR_API_KEY_MISSING
    fi
    
    if [ -z "$content" ]; then
        handle_error $ERR_API_REQUEST_FAILED "Content not provided"
        return $ERR_API_REQUEST_FAILED
    fi
    
    # Check network connectivity
    if ! check_network; then
        return $(get_error_code)
    fi
    
    # Generate cache key
    local cache_key
    cache_key=$(echo "$content" | shasum -a 256 | cut -d' ' -f1)
    
    # Check cache first (using file-based cache)
    local cache_file="$API_CACHE_DIR/$cache_key"
    if [ -f "$cache_file" ]; then
        api_log "INFO" "Using cached response"
        cat "$cache_file"
        return $ERR_SUCCESS
    fi
    
    # Retry logic with exponential backoff
    local attempt=1
    local delay=1
    
    while [ $attempt -le $MAX_RETRIES ]; do
        api_log "INFO" "API request attempt $attempt/$MAX_RETRIES"
        
        local response
        response=$(make_api_request_internal "$api_key" "$content" "$max_tokens" "$model")
        local result=$?
        
        if [ $result -eq $ERR_SUCCESS ]; then
            # Cache successful response (using file-based cache)
            echo "$response" > "$cache_file"
            echo "$response"
            return $ERR_SUCCESS
        fi
        
        # Check if we should retry based on error type
        case $result in
            $ERR_API_RATE_LIMITED|$ERR_NETWORK_UNAVAILABLE)
                if [ $attempt -lt $MAX_RETRIES ]; then
                    api_log "WARN" "Retryable error occurred, waiting ${delay}s before retry"
                    sleep $delay
                    delay=$((delay * 2))  # Exponential backoff
                else
                    api_log "ERROR" "Max retries exceeded for retryable error"
                fi
                ;;
            *)
                api_log "ERROR" "Non-retryable error occurred, aborting"
                return $result
                ;;
        esac
        
        attempt=$((attempt + 1))
    done
    
    api_log "ERROR" "All API request attempts failed"
    return $result
}

# Create calendar event request content
create_calendar_event_request() {
    local text="$1"
    local today="$2"
    local tomorrow="$3"
    
    # Get user preferences if available
    local user_preferences="${POPCLIP_OPTION_USER_PREFERENCES:-}"
    local preferences_section=""
    
    if [ -n "$user_preferences" ]; then
        preferences_section="
IMPORTANT: USER HAS PROVIDED CUSTOM PREFERENCES THAT MUST BE FOLLOWED:
=====================================================
$user_preferences
=====================================================

OVERRIDE INSTRUCTION: When the user preferences specify a calendar for certain types of events (like 'work meetings should be in my Work calendar'), you MUST use that calendar_type regardless of the default rules above. The user's preferences take absolute priority.

For this event, check if it matches any criteria in the user preferences and apply the specified calendar_type.
"
    fi
    
    cat << EOF
Convert this text to a calendar event: '$text'

Reference dates:
- Today: $today
- Tomorrow: $tomorrow

Return ONLY valid JSON in this exact format:
{
    "title": "Event title",
    "start_time": "$tomorrow 15:00",
    "end_time": "$tomorrow 16:00",
    "allday": false,
    "description": "Event description",
    "location": "location or 'online'",
    "url": "meeting link if applicable",
    "status": "confirmed",
    "priority": "high|medium|low",
    "calendar_type": "MUST BE ONE OF: high_priority, medium_priority, low_priority, work, personal, deadlines, meetings",
    "alerts": [5, 15, 30, 1440],
    "recurrence": "none|weekly|weekly_tue_thu|biweekly|monthly",
    "excluded_dates": [],
    "attendees": []
}

CALENDAR TYPE SELECTION RULES - Apply USER PREFERENCES first if provided, otherwise use these defaults:

1. "high_priority": Use when text contains:
   - Words like: urgent, emergency, critical, ASAP, important, must, required, mandatory
   - CEO/executive requests, critical issues, emergencies
   - Chinese: 紧急, 重要, 必须, 立即, 马上, 危急

2. "deadlines": Use when text contains:
   - Explicit deadlines with dates/times
   - Words like: deadline, due date, submission, expires, cutoff, last day
   - Chinese: 截止, 期限, 到期, 最后, 提交日期

3. "meetings": Use when text contains:
   - Words like: meeting, conference, discussion, call, presentation, interview
   - Multiple attendees mentioned
   - Chinese: 会议, 例会, 讨论, 研讨会, 面试

4. "work": Use when text contains:
   - Work-related tasks without urgency or meetings
   - Words like: project, client, review, report, task, office
   - Chinese: 工作, 项目, 客户, 报告, 办公

5. "personal": Use when text contains:
   - Personal activities, family, friends
   - Words like: birthday, vacation, doctor, dinner, personal
   - Chinese: 家庭, 朋友, 生日, 私人, 看病

6. "low_priority": Use when text contains:
   - Optional or tentative language
   - Words like: optional, maybe, if possible, could, might
   - Chinese: 可选, 有空, 如果, 也许

7. "medium_priority": Default for regular tasks without specific urgency

OTHER RULES:
- Date format: YYYY-MM-DD HH:MM
- For all-day events: set "allday": true, use YYYY-MM-DD format
- Status: "confirmed", "tentative", "cancelled", or "none"
- Priority: based on urgency (high/medium/low)
- Alerts in minutes (1440 = 1 day)

RECURRENCE RULES - IMPORTANT:
- "none": no recurrence
- "daily": every day
- "weekly": once a week on the same day
- "weekly_mon_wed_fri": Monday, Wednesday, Friday
- "weekly_tue_thu": Tuesday and Thursday (for classes like TTh)
- "biweekly": every two weeks
- "monthly": monthly on the same date
- "monthly_last_friday": last Friday of each month
- For courses with "TTh" or "MWF" schedule, use the appropriate weekly pattern
- For Chinese "每二和周四" or "周二周四", use "weekly_tue_thu"

$preferences_section
EOF
}

# Process calendar event text with AI
process_calendar_event() {
    local text="$1"
    local api_key="$2"
    local today="$3"
    local tomorrow="$4"
    
    api_log "INFO" "Processing calendar event text"
    
    local content
    content=$(create_calendar_event_request "$text" "$today" "$tomorrow")
    
    local response
    response=$(make_anthropic_request "$api_key" "$content")
    local result=$?
    
    if [ $result -ne $ERR_SUCCESS ]; then
        api_log "ERROR" "Failed to process calendar event"
        return $result
    fi
    
    api_log "INFO" "Calendar event processed successfully"
    echo "$response"
    return $ERR_SUCCESS
}

# Clear API response cache
clear_api_cache() {
    rm -f "$API_CACHE_DIR"/* 2>/dev/null || true
    api_log "INFO" "API response cache cleared"
}

# Get cache statistics
get_cache_stats() {
    local cache_size=$(find "$API_CACHE_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "API Cache: $cache_size entries"
    api_log "INFO" "API cache contains $cache_size entries"
}

# Export functions for use in other modules
export -f validate_anthropic_api_key make_anthropic_request process_calendar_event
export -f clear_api_cache get_cache_stats create_calendar_event_request