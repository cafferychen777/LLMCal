#!/bin/bash

# Zoom Integration Module for LLMCal
# Handles all Zoom API integration with improved error handling

# Source error handler
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Zoom API Configuration
readonly ZOOM_OAUTH_URL="https://zoom.us/oauth/token"
readonly ZOOM_API_BASE="https://api.zoom.us/v2"
readonly ZOOM_API_TIMEOUT=30
readonly ZOOM_TOKEN_CACHE_FILE="/tmp/llmcal_zoom_token"
readonly ZOOM_TOKEN_EXPIRY=3500  # Tokens expire in 1 hour, refresh after ~58 minutes

# Set zoom logger
set_error_logger "zoom_log"

# Enhanced logging for zoom integration
zoom_log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ZOOM-$level]: $message" >> "${LOG_FILE:-/tmp/llmcal.log}"
}

# Validate Zoom credentials
validate_zoom_credentials() {
    local account_id="$1"
    local client_id="$2"
    local client_secret="$3"
    
    zoom_log "INFO" "Validating Zoom credentials"
    
    if [ -z "$account_id" ] || [ -z "$client_id" ] || [ -z "$client_secret" ]; then
        handle_error $ERR_ZOOM_CREDENTIALS_MISSING "One or more Zoom credentials are missing"
        return $ERR_ZOOM_CREDENTIALS_MISSING
    fi
    
    # Validate format (basic check)
    if [[ ! "$client_id" =~ ^[A-Za-z0-9_-]+$ ]] || [[ ! "$client_secret" =~ ^[A-Za-z0-9_-]+$ ]]; then
        handle_error $ERR_ZOOM_CREDENTIALS_MISSING "Invalid Zoom credential format"
        return $ERR_ZOOM_CREDENTIALS_MISSING
    fi
    
    zoom_log "INFO" "Zoom credentials validation successful"
    return $ERR_SUCCESS
}

# Check if cached token is still valid
is_token_valid() {
    local cache_file="$1"
    
    if [ ! -f "$cache_file" ]; then
        return 1
    fi
    
    # Check if token file is too old
    local file_age
    file_age=$(( $(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))
    
    if [ $file_age -gt $ZOOM_TOKEN_EXPIRY ]; then
        zoom_log "INFO" "Cached token expired (age: ${file_age}s)"
        rm -f "$cache_file"
        return 1
    fi
    
    # Check if token file has content
    if [ -s "$cache_file" ]; then
        zoom_log "INFO" "Valid cached token found"
        return 0
    fi
    
    return 1
}

# Get Zoom access token with caching
get_zoom_access_token() {
    local account_id="$1"
    local client_id="$2"
    local client_secret="$3"
    
    zoom_log "INFO" "Getting Zoom access token"
    
    # Validate credentials first
    if ! validate_zoom_credentials "$account_id" "$client_id" "$client_secret"; then
        return $(get_error_code)
    fi
    
    # Check for cached token
    if is_token_valid "$ZOOM_TOKEN_CACHE_FILE"; then
        local cached_token
        cached_token=$(cat "$ZOOM_TOKEN_CACHE_FILE" 2>/dev/null)
        if [ -n "$cached_token" ]; then
            zoom_log "INFO" "Using cached Zoom token"
            echo "$cached_token"
            return $ERR_SUCCESS
        fi
    fi
    
    zoom_log "INFO" "Requesting new Zoom token"
    
    # Create authorization header
    local auth_token
    auth_token=$(echo -n "$client_id:$client_secret" | base64)
    
    # Make token request
    local response http_code
    local temp_response=$(mktemp)
    
    http_code=$(curl -w "%{http_code}" -s \
        --max-time $ZOOM_API_TIMEOUT \
        -X POST "$ZOOM_OAUTH_URL?grant_type=account_credentials&account_id=$account_id" \
        -H "Authorization: Basic $auth_token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -o "$temp_response" 2>/dev/null)
    
    local curl_result=$?
    response=$(cat "$temp_response" 2>/dev/null)
    rm -f "$temp_response"
    
    # Handle curl errors
    if [ $curl_result -ne 0 ]; then
        zoom_log "ERROR" "Curl request failed with code $curl_result"
        case $curl_result in
            6|7) handle_error $ERR_NETWORK_UNAVAILABLE "Cannot connect to Zoom API";;
            28) handle_error $ERR_ZOOM_TOKEN_FAILED "Token request timeout";;
            *) handle_error $ERR_ZOOM_TOKEN_FAILED "Curl error code: $curl_result";;
        esac
        return $(get_error_code)
    fi
    
    # Handle HTTP errors
    case "$http_code" in
        200)
            zoom_log "INFO" "Token request successful"
            ;;
        401)
            zoom_log "ERROR" "Zoom authentication failed (401)"
            handle_error $ERR_ZOOM_CREDENTIALS_MISSING "Invalid Zoom credentials"
            return $ERR_ZOOM_CREDENTIALS_MISSING
            ;;
        *)
            zoom_log "ERROR" "Token request failed with HTTP $http_code: $response"
            handle_error $ERR_ZOOM_TOKEN_FAILED "HTTP error: $http_code"
            return $ERR_ZOOM_TOKEN_FAILED
            ;;
    esac
    
    # Parse access token from response
    local access_token
    if command -v jq > /dev/null 2>&1; then
        access_token=$(echo "$response" | jq -r '.access_token // empty' 2>/dev/null)
    else
        # Fallback parsing without jq
        access_token=$(echo "$response" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
    fi
    
    if [ -z "$access_token" ] || [ "$access_token" = "null" ]; then
        zoom_log "ERROR" "Failed to extract access token from response: $response"
        handle_error $ERR_ZOOM_TOKEN_FAILED "Invalid token response format"
        return $ERR_ZOOM_TOKEN_FAILED
    fi
    
    # Cache the token
    echo "$access_token" > "$ZOOM_TOKEN_CACHE_FILE" 2>/dev/null
    
    zoom_log "INFO" "Successfully obtained Zoom access token"
    echo "$access_token"
    return $ERR_SUCCESS
}

# Create meeting invitees JSON
create_meeting_invitees() {
    local attendees="$1"
    
    if [ -z "$attendees" ]; then
        echo "[]"
        return $ERR_SUCCESS
    fi
    
    local invitees_json="["
    local first_entry=true
    
    while IFS= read -r email; do
        if [ -n "$email" ]; then
            if [ "$first_entry" = "false" ]; then
                invitees_json="$invitees_json,"
            fi
            # Escape email for JSON
            local escaped_email
            escaped_email=$(printf '%s' "$email" | sed 's/\\/\\\\/g; s/"/\\"/g')
            invitees_json="$invitees_json{\"email\":\"$escaped_email\"}"
            first_entry=false
        fi
    done <<< "$attendees"
    
    invitees_json="$invitees_json]"
    echo "$invitees_json"
    return $ERR_SUCCESS
}

# Create Zoom meeting payload
create_zoom_meeting_payload() {
    local title="$1"
    local start_time_iso="$2"
    local duration_minutes="$3"
    local description="$4"
    local attendees="$5"
    local timezone="$6"
    local contact_email="$7"
    local contact_name="$8"
    
    zoom_log "INFO" "Creating Zoom meeting payload"
    
    # Validate required fields
    if [ -z "$title" ] || [ -z "$start_time_iso" ] || [ -z "$duration_minutes" ]; then
        handle_error $ERR_ZOOM_MEETING_FAILED "Missing required meeting parameters"
        return $ERR_ZOOM_MEETING_FAILED
    fi
    
    # Create invitees JSON
    local invitees_json
    invitees_json=$(create_meeting_invitees "$attendees")
    
    # Escape strings for JSON
    local escaped_title escaped_description escaped_contact_email escaped_contact_name
    escaped_title=$(printf '%s' "$title" | sed 's/\\/\\\\/g; s/"/\\"/g')
    escaped_description=$(printf '%s' "$description" | sed 's/\\/\\\\/g; s/"/\\"/g')
    escaped_contact_email=$(printf '%s' "$contact_email" | sed 's/\\/\\\\/g; s/"/\\"/g')
    escaped_contact_name=$(printf '%s' "$contact_name" | sed 's/\\/\\\\/g; s/"/\\"/g')
    
    # Create payload
    cat << EOF
{
    "topic": "$escaped_title",
    "type": 2,
    "start_time": "$start_time_iso",
    "duration": $duration_minutes,
    "timezone": "$timezone",
    "settings": {
        "host_video": true,
        "participant_video": true,
        "join_before_host": true,
        "mute_upon_entry": false,
        "auto_recording": "none",
        "registrants_email_notification": true,
        "meeting_invitees": $invitees_json,
        "email_notification": true,
        "calendar_type": 1,
        "schedule_for_reminder": true,
        "contact_email": "$escaped_contact_email",
        "contact_name": "$escaped_contact_name"
    }
}
EOF
    
    return $ERR_SUCCESS
}

# Create Zoom meeting
create_zoom_meeting() {
    local title="$1"
    local start_time="$2"
    local end_time="$3"
    local description="$4"
    local attendees="$5"
    local account_id="$6"
    local client_id="$7"
    local client_secret="$8"
    local contact_email="$9"
    local contact_name="${10}"
    
    zoom_log "INFO" "Creating Zoom meeting: $title"
    
    # Get timezone from system
    local timezone
    timezone=$(get_system_timezone)
    
    # Convert start time to ISO format
    local start_time_iso
    start_time_iso=$(convert_to_iso "$start_time" "$timezone")
    if [ $? -ne $ERR_SUCCESS ]; then
        handle_error $ERR_DATE_CONVERSION_FAILED "Failed to convert start time to ISO format"
        return $ERR_DATE_CONVERSION_FAILED
    fi
    
    # Calculate duration
    local duration_minutes
    duration_minutes=$(calculate_duration "$start_time" "$end_time" "minutes")
    if [ $? -ne $ERR_SUCCESS ]; then
        handle_error $ERR_DATE_CONVERSION_FAILED "Failed to calculate meeting duration"
        return $ERR_DATE_CONVERSION_FAILED
    fi
    
    # Ensure minimum duration
    if [ "$duration_minutes" -lt 1 ]; then
        duration_minutes=60  # Default to 1 hour
        zoom_log "WARN" "Duration too short, defaulting to 60 minutes"
    fi
    
    zoom_log "INFO" "Meeting details: start=$start_time_iso, duration=${duration_minutes}min, timezone=$timezone"
    
    # Get access token
    local access_token
    access_token=$(get_zoom_access_token "$account_id" "$client_id" "$client_secret")
    local token_result=$?
    
    if [ $token_result -ne $ERR_SUCCESS ]; then
        zoom_log "ERROR" "Failed to get Zoom access token"
        return $token_result
    fi
    
    # Create meeting payload
    local payload
    payload=$(create_zoom_meeting_payload "$title" "$start_time_iso" "$duration_minutes" "$description" "$attendees" "$timezone" "$contact_email" "$contact_name")
    if [ $? -ne $ERR_SUCCESS ]; then
        return $(get_error_code)
    fi
    
    zoom_log "DEBUG" "Meeting payload: $payload"
    
    # Create meeting via API
    local response http_code
    local temp_response=$(mktemp)
    local temp_headers=$(mktemp)
    
    http_code=$(curl -w "%{http_code}" -s \
        --max-time $ZOOM_API_TIMEOUT \
        -X POST "$ZOOM_API_BASE/users/me/meetings" \
        -H "Authorization: Bearer $access_token" \
        -H "Content-Type: application/json" \
        -D "$temp_headers" \
        -d "$payload" \
        -o "$temp_response" 2>/dev/null)
    
    local curl_result=$?
    response=$(cat "$temp_response" 2>/dev/null)
    
    # Cleanup temp files
    rm -f "$temp_response" "$temp_headers"
    
    # Handle curl errors
    if [ $curl_result -ne 0 ]; then
        zoom_log "ERROR" "Meeting creation request failed: curl error $curl_result"
        handle_error $ERR_ZOOM_MEETING_FAILED "Network error during meeting creation"
        return $ERR_ZOOM_MEETING_FAILED
    fi
    
    zoom_log "INFO" "Meeting creation response: HTTP $http_code"
    zoom_log "DEBUG" "Response body: $response"
    
    # Handle HTTP response
    case "$http_code" in
        201)
            zoom_log "INFO" "Zoom meeting created successfully"
            ;;
        401)
            # Token might be expired, try to clear cache and retry once
            rm -f "$ZOOM_TOKEN_CACHE_FILE"
            zoom_log "WARN" "Token expired, cleared cache"
            handle_error $ERR_ZOOM_TOKEN_FAILED "Zoom token expired"
            return $ERR_ZOOM_TOKEN_FAILED
            ;;
        400)
            zoom_log "ERROR" "Bad request (400): $response"
            handle_error $ERR_ZOOM_MEETING_FAILED "Invalid meeting parameters"
            return $ERR_ZOOM_MEETING_FAILED
            ;;
        *)
            zoom_log "ERROR" "Meeting creation failed: HTTP $http_code - $response"
            handle_error $ERR_ZOOM_MEETING_FAILED "HTTP error: $http_code"
            return $ERR_ZOOM_MEETING_FAILED
            ;;
    esac
    
    # Parse meeting URL from response
    local join_url meeting_id
    if command -v jq > /dev/null 2>&1; then
        join_url=$(echo "$response" | jq -r '.join_url // empty' 2>/dev/null)
        meeting_id=$(echo "$response" | jq -r '.id // empty' 2>/dev/null)
    else
        # Fallback parsing without jq
        join_url=$(echo "$response" | sed -n 's/.*"join_url":"\([^"]*\)".*/\1/p')
        meeting_id=$(echo "$response" | sed -n 's/.*"id":\([^,}]*\).*/\1/p')
    fi
    
    if [ -z "$join_url" ]; then
        zoom_log "ERROR" "Failed to extract meeting URL from response: $response"
        handle_error $ERR_ZOOM_MEETING_FAILED "Invalid meeting creation response"
        return $ERR_ZOOM_MEETING_FAILED
    fi
    
    zoom_log "INFO" "Zoom meeting created successfully: ID=$meeting_id, URL=$join_url"
    
    # Return meeting information as JSON
    cat << EOF
{
    "success": true,
    "join_url": "$join_url",
    "meeting_id": "$meeting_id",
    "duration_formatted": "$(format_duration_display "$duration_minutes")"
}
EOF
    
    return $ERR_SUCCESS
}

# Check if text indicates Zoom meeting is needed
should_create_zoom_meeting() {
    local text="$1"
    local location="$2"
    
    # Check for Zoom keywords in text
    if echo "$text" | grep -qi "zoom"; then
        return 0
    fi
    
    # Check for Zoom keywords in location
    if echo "$location" | grep -qi "zoom"; then
        return 0
    fi
    
    # Check for virtual meeting indicators
    if echo "$text $location" | grep -qi "virtual\|online\|remote\|video call\|video meeting"; then
        return 0
    fi
    
    return 1
}

# Clean up Zoom token cache
cleanup_zoom_cache() {
    if [ -f "$ZOOM_TOKEN_CACHE_FILE" ]; then
        rm -f "$ZOOM_TOKEN_CACHE_FILE"
        zoom_log "INFO" "Zoom token cache cleaned up"
    fi
}

# Get Zoom meeting info (if needed for debugging)
get_zoom_meeting_info() {
    local meeting_id="$1"
    local access_token="$2"
    
    if [ -z "$meeting_id" ] || [ -z "$access_token" ]; then
        handle_error $ERR_ZOOM_MEETING_FAILED "Missing meeting ID or access token"
        return $ERR_ZOOM_MEETING_FAILED
    fi
    
    local response http_code
    local temp_response=$(mktemp)
    
    http_code=$(curl -w "%{http_code}" -s \
        --max-time $ZOOM_API_TIMEOUT \
        -X GET "$ZOOM_API_BASE/meetings/$meeting_id" \
        -H "Authorization: Bearer $access_token" \
        -o "$temp_response" 2>/dev/null)
    
    response=$(cat "$temp_response" 2>/dev/null)
    rm -f "$temp_response"
    
    if [ "$http_code" = "200" ]; then
        echo "$response"
        return $ERR_SUCCESS
    else
        handle_error $ERR_ZOOM_MEETING_FAILED "Failed to get meeting info: HTTP $http_code"
        return $ERR_ZOOM_MEETING_FAILED
    fi
}

# Export functions for use in other modules
export -f validate_zoom_credentials get_zoom_access_token create_zoom_meeting
export -f should_create_zoom_meeting cleanup_zoom_cache get_zoom_meeting_info