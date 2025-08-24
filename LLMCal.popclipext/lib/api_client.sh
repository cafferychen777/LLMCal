#!/bin/bash

# API Client Module for LLMCal
# Handles all API communications with Anthropic Claude API

# Source error handler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/error_handler.sh"

# API Configuration
readonly ANTHROPIC_API_URL="https://api.anthropic.com/v1/messages"
readonly ANTHROPIC_API_VERSION="2023-06-01"
readonly DEFAULT_MODEL="claude-3-5-haiku-20241022"
readonly DEFAULT_MAX_TOKENS=1024
readonly REQUEST_TIMEOUT=30
readonly MAX_RETRIES=3

# Cache for API responses (optional optimization)
declare -A API_RESPONSE_CACHE

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
    local model="${4:-$DEFAULT_MODEL}"
    
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
    local model="${4:-$DEFAULT_MODEL}"
    
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
    
    # Check cache first (optional optimization)
    if [ -n "${API_RESPONSE_CACHE[$cache_key]:-}" ]; then
        api_log "INFO" "Using cached response"
        echo "${API_RESPONSE_CACHE[$cache_key]}"
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
            # Cache successful response
            API_RESPONSE_CACHE[$cache_key]="$response"
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
    
    cat << EOF
Convert text to calendar event: '$text'
Use these dates:
- Today: $today
- Tomorrow: $tomorrow

Return only JSON with the following structure:
{
    "title": "Event title",
    "start_time": "$tomorrow 15:00",
    "end_time": "$tomorrow 16:00",
    "description": "Event description",
    "location": "meeting place or address or 'online' for virtual meetings",
    "url": "meeting link for virtual meetings (if applicable)",
    "alerts": [5, 15, 30, 1440],
    "recurrence": "daily|weekly|biweekly|monthly|monthly_last_friday|none",
    "attendees": ["email1@example.com", "email2@example.com"]
}

Important:
- Use proper date format: YYYY-MM-DD HH:MM
- For location: use specific address, "zoom", "online", or meeting room name
- Include meeting URL only if it's a virtual meeting
- Set alerts in minutes before event
- Only include attendees if email addresses are mentioned in the text
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
    API_RESPONSE_CACHE=()
    api_log "INFO" "API response cache cleared"
}

# Get cache statistics
get_cache_stats() {
    local cache_size=${#API_RESPONSE_CACHE[@]}
    echo "API Cache: $cache_size entries"
    api_log "INFO" "API cache contains $cache_size entries"
}

# Export functions for use in other modules
export -f validate_anthropic_api_key make_anthropic_request process_calendar_event
export -f clear_api_cache get_cache_stats create_calendar_event_request