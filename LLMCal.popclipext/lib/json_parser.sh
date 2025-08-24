#!/bin/bash

# JSON Parser Module for LLMCal
# Handles all JSON processing with improved error handling and caching

# Source error handler
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# JSON processing configuration
readonly JSON_TEMP_DIR="/tmp/llmcal_json"
readonly PYTHON_JSON_PROCESSOR="/tmp/llmcal_json_processor.py"

# Cache directory for parsed JSON (to avoid duplicate parsing)
# Using filesystem-based cache instead of associative array for Bash 3.2 compatibility
JSON_CACHE_DIR="/tmp/llmcal_json_cache"
mkdir -p "$JSON_CACHE_DIR" 2>/dev/null || true

# Set JSON parser logger
set_error_logger "json_log"

# Enhanced logging for JSON parser
json_log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [JSON-$level]: $message" >> "${LOG_FILE:-/tmp/llmcal.log}"
}

# Initialize JSON processing environment
init_json_processor() {
    json_log "INFO" "Initializing JSON processor"
    
    # Create temp directory
    mkdir -p "$JSON_TEMP_DIR"
    
    # Create Python JSON processor if it doesn't exist
    if [ ! -f "$PYTHON_JSON_PROCESSOR" ]; then
        create_python_json_processor
    fi
    
    return $ERR_SUCCESS
}

# Create Python JSON processor script
create_python_json_processor() {
    json_log "INFO" "Creating Python JSON processor"
    
    cat > "$PYTHON_JSON_PROCESSOR" << 'EOF'
#!/usr/bin/env python3
import sys
import json
import re
from typing import Any, Dict, Optional

def clean_json_content(content: str) -> str:
    """Clean and normalize JSON content."""
    # Remove potential markdown code blocks
    content = re.sub(r'^```(?:json)?\s*', '', content, flags=re.MULTILINE)
    content = re.sub(r'\s*```$', '', content, flags=re.MULTILINE)
    
    # Remove any leading/trailing whitespace
    content = content.strip()
    
    # Remove any control characters except newlines and tabs
    content = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]', '', content)
    
    return content

def extract_json_from_text(text: str) -> Optional[str]:
    """Extract JSON content from mixed text."""
    # First try to find a complete JSON object containing 'title'
    # This handles cases where LLM adds explanatory text after the JSON
    
    # Pattern to match JSON object with title field (handles nested objects and arrays)
    title_json_pattern = r'\{[^{}]*"title"[^{}]*(?:\{[^{}]*\}[^{}]*)*(?:\[[^\[\]]*\][^{}]*)*\}'
    
    matches = re.findall(title_json_pattern, text, re.DOTALL)
    for match in matches:
        try:
            # Balance braces if needed
            open_braces = match.count('{')
            close_braces = match.count('}')
            if open_braces > close_braces:
                # Find additional closing braces from the text
                remaining_text = text[text.index(match) + len(match):]
                for char in remaining_text:
                    if char == '}':
                        match += char
                        close_braces += 1
                        if open_braces == close_braces:
                            break
            
            # Test if it's valid JSON
            parsed = json.loads(match)
            # Verify it has essential fields
            if isinstance(parsed, dict) and 'title' in parsed:
                return match
        except (json.JSONDecodeError, ValueError):
            continue
    
    # Fallback to simpler patterns
    json_patterns = [
        r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}',  # Simple nested JSON
        r'\{.*?\}',  # Basic JSON object
    ]
    
    for pattern in json_patterns:
        matches = re.findall(pattern, text, re.DOTALL)
        for match in matches:
            try:
                # Test if it's valid JSON
                json.loads(match)
                return match
            except json.JSONDecodeError:
                continue
    
    return None

def process_anthropic_response(response_text: str) -> Dict[str, Any]:
    """Process Anthropic API response and extract event data."""
    try:
        # First, try to parse as direct JSON response
        response_data = json.loads(response_text)
        
        # Handle different response formats
        if isinstance(response_data, dict):
            # Check if it's already an event object
            if all(key in response_data for key in ['title', 'start_time']):
                return response_data
            
            # Extract from Anthropic API response format
            if 'content' in response_data:
                content_list = response_data.get('content', [])
                if content_list and isinstance(content_list, list):
                    text_content = content_list[0].get('text', '')
                    if text_content:
                        # Try to extract JSON directly using brace counting
                        start = text_content.find('{')
                        if start >= 0:
                            count = 0
                            end = -1
                            for i in range(start, len(text_content)):
                                if text_content[i] == '{':
                                    count += 1
                                elif text_content[i] == '}':
                                    count -= 1
                                    if count == 0:
                                        end = i + 1
                                        break
                            
                            if end > start:
                                json_str = text_content[start:end]
                                try:
                                    event_data = json.loads(json_str)
                                    return event_data
                                except json.JSONDecodeError:
                                    pass
                        
                        # Fallback to cleaning method
                        cleaned_content = clean_json_content(text_content)
                        event_data = json.loads(cleaned_content)
                        return event_data
            
            # If response_data is already the event, return it
            return response_data
        
        # If it's a string, try to extract JSON
        elif isinstance(response_data, str):
            cleaned_content = clean_json_content(response_data)
            event_data = json.loads(cleaned_content)
            return event_data
            
    except json.JSONDecodeError as e:
        # Try to extract JSON from the text
        json_text = extract_json_from_text(response_text)
        if json_text:
            try:
                event_data = json.loads(json_text)
                return event_data
            except json.JSONDecodeError:
                pass
        
        print(f"JSON decode error: {str(e)}", file=sys.stderr)
        return {}
    except Exception as e:
        print(f"Error processing response: {str(e)}", file=sys.stderr)
        return {}
    
    return {}

def validate_event_data(event_data: Dict[str, Any]) -> Dict[str, Any]:
    """Validate and normalize event data."""
    required_fields = ['title', 'start_time']
    
    # Check required fields
    for field in required_fields:
        if field not in event_data:
            print(f"Missing required field: {field}", file=sys.stderr)
            return {}
    
    # Normalize and validate fields
    normalized_event = {}
    
    # Required fields
    normalized_event['title'] = str(event_data['title']).strip()
    normalized_event['start_time'] = str(event_data['start_time']).strip()
    
    # Optional fields with defaults
    normalized_event['end_time'] = str(event_data.get('end_time', '')).strip()
    normalized_event['description'] = str(event_data.get('description', '')).strip()
    normalized_event['location'] = str(event_data.get('location', '')).strip()
    normalized_event['url'] = str(event_data.get('url', '')).strip()
    normalized_event['recurrence'] = str(event_data.get('recurrence', 'none')).strip()
    
    # New fields for calendar management
    normalized_event['priority'] = str(event_data.get('priority', 'medium')).strip()
    normalized_event['calendar_type'] = str(event_data.get('calendar_type', '')).strip()
    normalized_event['status'] = str(event_data.get('status', 'confirmed')).strip()
    normalized_event['allday'] = event_data.get('allday', False)
    
    # Handle alerts (should be array of numbers)
    alerts = event_data.get('alerts', [])
    if isinstance(alerts, list):
        normalized_event['alerts'] = [int(x) for x in alerts if isinstance(x, (int, str)) and str(x).isdigit()]
    else:
        normalized_event['alerts'] = []
    
    # Handle attendees (should be array of strings)
    attendees = event_data.get('attendees', [])
    if isinstance(attendees, list):
        normalized_event['attendees'] = [str(x).strip() for x in attendees if x]
    else:
        normalized_event['attendees'] = []
    
    # Handle excluded_dates (should be array of date strings)
    excluded_dates = event_data.get('excluded_dates', [])
    if isinstance(excluded_dates, list):
        normalized_event['excluded_dates'] = [str(x).strip() for x in excluded_dates if x]
    else:
        normalized_event['excluded_dates'] = []
    
    return normalized_event

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 json_processor.py <command> [args...]", file=sys.stderr)
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "process_response":
        # Read from stdin
        response_text = sys.stdin.read()
        event_data = process_anthropic_response(response_text)
        if event_data:
            validated_event = validate_event_data(event_data)
            if validated_event:
                print(json.dumps(validated_event, indent=2))
            else:
                print("{}", file=sys.stderr)
                sys.exit(1)
        else:
            print("{}", file=sys.stderr)
            sys.exit(1)
    
    elif command == "validate":
        # Read JSON from stdin and validate
        try:
            data = json.loads(sys.stdin.read())
            validated = validate_event_data(data)
            if validated:
                print(json.dumps(validated, indent=2))
            else:
                sys.exit(1)
        except Exception as e:
            print(f"Validation error: {str(e)}", file=sys.stderr)
            sys.exit(1)
    
    elif command == "extract_field":
        if len(sys.argv) < 3:
            print("Usage: python3 json_processor.py extract_field <field_name>", file=sys.stderr)
            sys.exit(1)
        
        field_name = sys.argv[2]
        try:
            data = json.loads(sys.stdin.read())
            value = data.get(field_name, "")
            print(str(value))
        except Exception as e:
            print(f"Field extraction error: {str(e)}", file=sys.stderr)
            sys.exit(1)
    
    elif command == "extract_array":
        if len(sys.argv) < 3:
            print("Usage: python3 json_processor.py extract_array <field_name>", file=sys.stderr)
            sys.exit(1)
        
        field_name = sys.argv[2]
        try:
            data = json.loads(sys.stdin.read())
            array_data = data.get(field_name, [])
            if isinstance(array_data, list):
                for item in array_data:
                    print(str(item))
            else:
                print(str(array_data))
        except Exception as e:
            print(f"Array extraction error: {str(e)}", file=sys.stderr)
            sys.exit(1)
    
    else:
        print(f"Unknown command: {command}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF
    
    # Make the processor executable
    chmod +x "$PYTHON_JSON_PROCESSOR"
    
    if [ $? -eq 0 ]; then
        json_log "INFO" "Python JSON processor created successfully"
        return $ERR_SUCCESS
    else
        handle_error $ERR_JSON_PARSE_FAILED "Failed to create Python JSON processor"
        return $ERR_JSON_PARSE_FAILED
    fi
}

# Check if jq is available and functional
check_jq_availability() {
    if command -v jq > /dev/null 2>&1; then
        if echo '{"test": true}' | jq -r '.test' > /dev/null 2>&1; then
            json_log "DEBUG" "jq is available and functional"
            return 0
        fi
    fi
    json_log "DEBUG" "jq is not available or not functional"
    return 1
}

# Parse JSON using best available method
parse_json_with_fallback() {
    local json_text="$1"
    local method="${2:-auto}"
    
    json_log "DEBUG" "Parsing JSON with method: $method"
    
    # Generate cache key
    local cache_key
    cache_key=$(echo "$json_text" | shasum -a 256 2>/dev/null | cut -d' ' -f1)
    
    # Check cache first (using file-based cache)
    local cache_file="$JSON_CACHE_DIR/$cache_key"
    if [ -f "$cache_file" ]; then
        json_log "DEBUG" "Using cached JSON parse result"
        cat "$cache_file"
        return $ERR_SUCCESS
    fi
    
    local result
    local parse_result
    
    if [ "$method" = "jq" ] || ([ "$method" = "auto" ] && check_jq_availability); then
        # Use jq if available and requested/auto
        json_log "DEBUG" "Using jq for JSON parsing"
        result=$(echo "$json_text" | jq -r '.' 2>/dev/null)
        parse_result=$?
    else
        # Use Python fallback
        json_log "DEBUG" "Using Python for JSON parsing"
        if [ ! -f "$PYTHON_JSON_PROCESSOR" ]; then
            init_json_processor
        fi
        
        result=$(echo "$json_text" | python3 -c "
import sys
import json
try:
    data = json.loads(sys.stdin.read())
    print(json.dumps(data))
except Exception as e:
    print('{}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null)
        parse_result=$?
    fi
    
    if [ $parse_result -eq 0 ] && [ -n "$result" ] && [ "$result" != "null" ]; then
        # Cache successful result (using file-based cache)
        echo "$result" > "$cache_file"
        echo "$result"
        return $ERR_SUCCESS
    else
        handle_error $ERR_JSON_PARSE_FAILED "Failed to parse JSON"
        return $ERR_JSON_PARSE_FAILED
    fi
}

# Process Anthropic API response to extract event data
process_anthropic_response() {
    local response_text="$1"
    
    json_log "INFO" "Processing Anthropic API response"
    
    if [ -z "$response_text" ]; then
        handle_error $ERR_JSON_PARSE_FAILED "Empty response text"
        return $ERR_JSON_PARSE_FAILED
    fi
    
    # Initialize processor if needed
    if [ ! -f "$PYTHON_JSON_PROCESSOR" ]; then
        init_json_processor
    fi
    
    # Use Python processor for reliable parsing
    local event_data
    event_data=$(echo "$response_text" | python3 "$PYTHON_JSON_PROCESSOR" process_response 2>/dev/null)
    local result=$?
    
    if [ $result -eq 0 ] && [ -n "$event_data" ] && [ "$event_data" != "{}" ]; then
        json_log "INFO" "Successfully processed Anthropic response"
        echo "$event_data"
        return $ERR_SUCCESS
    else
        json_log "ERROR" "Failed to process Anthropic response"
        handle_error $ERR_JSON_PARSE_FAILED "Invalid Anthropic API response format"
        return $ERR_JSON_PARSE_FAILED
    fi
}

# Extract specific field from JSON
extract_json_field() {
    local json_data="$1"
    local field_name="$2"
    local default_value="${3:-}"
    
    json_log "DEBUG" "Extracting field: $field_name"
    
    if [ -z "$json_data" ] || [ -z "$field_name" ]; then
        echo "$default_value"
        return $ERR_JSON_PARSE_FAILED
    fi
    
    local value
    
    # Try jq first if available
    if check_jq_availability; then
        value=$(echo "$json_data" | jq -r ".$field_name // \"$default_value\"" 2>/dev/null)
    else
        # Use Python processor
        if [ ! -f "$PYTHON_JSON_PROCESSOR" ]; then
            init_json_processor
        fi
        value=$(echo "$json_data" | python3 "$PYTHON_JSON_PROCESSOR" extract_field "$field_name" 2>/dev/null)
        if [ $? -ne 0 ] || [ -z "$value" ]; then
            value="$default_value"
        fi
    fi
    
    echo "$value"
    return $ERR_SUCCESS
}

# Extract array field from JSON
extract_json_array() {
    local json_data="$1"
    local field_name="$2"
    
    json_log "DEBUG" "Extracting array field: $field_name"
    
    if [ -z "$json_data" ] || [ -z "$field_name" ]; then
        return $ERR_JSON_PARSE_FAILED
    fi
    
    # Use Python processor for reliable array handling
    if [ ! -f "$PYTHON_JSON_PROCESSOR" ]; then
        init_json_processor
    fi
    
    echo "$json_data" | python3 "$PYTHON_JSON_PROCESSOR" extract_array "$field_name" 2>/dev/null
    return $?
}

# Validate JSON structure
validate_json() {
    local json_text="$1"
    
    json_log "DEBUG" "Validating JSON structure"
    
    if [ -z "$json_text" ]; then
        handle_error $ERR_JSON_VALIDATION_FAILED "Empty JSON text"
        return $ERR_JSON_VALIDATION_FAILED
    fi
    
    # Try to parse the JSON
    local parsed_json
    parsed_json=$(parse_json_with_fallback "$json_text")
    local result=$?
    
    if [ $result -eq $ERR_SUCCESS ]; then
        json_log "DEBUG" "JSON validation successful"
        echo "$parsed_json"
        return $ERR_SUCCESS
    else
        json_log "ERROR" "JSON validation failed"
        return $ERR_JSON_VALIDATION_FAILED
    fi
}

# Validate event JSON structure
validate_event_json() {
    local event_json="$1"
    
    json_log "INFO" "Validating event JSON structure"
    
    if [ ! -f "$PYTHON_JSON_PROCESSOR" ]; then
        init_json_processor
    fi
    
    local validated_event
    validated_event=$(echo "$event_json" | python3 "$PYTHON_JSON_PROCESSOR" validate 2>/dev/null)
    local result=$?
    
    if [ $result -eq 0 ] && [ -n "$validated_event" ]; then
        json_log "INFO" "Event JSON validation successful"
        echo "$validated_event"
        return $ERR_SUCCESS
    else
        json_log "ERROR" "Event JSON validation failed"
        handle_error $ERR_JSON_VALIDATION_FAILED "Event data is missing required fields"
        return $ERR_JSON_VALIDATION_FAILED
    fi
}

# Create JSON from key-value pairs
create_json() {
    local -n data_ref=$1
    
    json_log "DEBUG" "Creating JSON from data array"
    
    local json_string="{"
    local first=true
    
    for key in "${!data_ref[@]}"; do
        if [ "$first" = "false" ]; then
            json_string="$json_string,"
        fi
        
        # Escape key and value
        local escaped_key escaped_value
        escaped_key=$(printf '%s' "$key" | sed 's/\\/\\\\/g; s/"/\\"/g')
        escaped_value=$(printf '%s' "${data_ref[$key]}" | sed 's/\\/\\\\/g; s/"/\\"/g')
        
        json_string="$json_string\"$escaped_key\":\"$escaped_value\""
        first=false
    done
    
    json_string="$json_string}"
    
    # Validate the created JSON
    if validate_json "$json_string" > /dev/null; then
        echo "$json_string"
        return $ERR_SUCCESS
    else
        handle_error $ERR_JSON_PARSE_FAILED "Failed to create valid JSON"
        return $ERR_JSON_PARSE_FAILED
    fi
}

# Clear JSON parse cache
clear_json_cache() {
    rm -f "$JSON_CACHE_DIR"/* 2>/dev/null || true
    json_log "INFO" "JSON parse cache cleared"
}

# Get JSON cache statistics
get_json_cache_stats() {
    local cache_size=$(find "$JSON_CACHE_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "JSON Cache: $cache_size entries"
    json_log "INFO" "JSON cache contains $cache_size entries"
}

# Cleanup JSON processor resources
cleanup_json_processor() {
    # Clean up temporary files
    rm -f "$PYTHON_JSON_PROCESSOR" 2>/dev/null
    rm -rf "$JSON_TEMP_DIR" 2>/dev/null
    
    # Clear cache
    clear_json_cache
    
    json_log "INFO" "JSON processor cleanup completed"
}

# Export functions for use in other modules
export -f init_json_processor process_anthropic_response extract_json_field
export -f extract_json_array validate_json validate_event_json create_json
export -f clear_json_cache get_json_cache_stats cleanup_json_processor