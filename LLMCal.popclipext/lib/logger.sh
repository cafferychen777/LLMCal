#!/bin/bash

# Secure Logger for LLMCal
# Provides secure logging with sanitization of sensitive data

# Source security utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/security.sh"

# Default log configuration
LOG_DIR="${LOG_DIR:-$HOME/Library/Logs/LLMCal}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/llmcal.log}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"
MAX_LOG_SIZE="${MAX_LOG_SIZE:-10485760}"  # 10MB
MAX_LOG_FILES="${MAX_LOG_FILES:-5}"

# Log levels
declare -A LOG_LEVELS=(
    ["DEBUG"]=0
    ["INFO"]=1
    ["WARN"]=2
    ["ERROR"]=3
    ["CRITICAL"]=4
)

# Initialize logging
init_logging() {
    # Create log directory if it doesn't exist
    mkdir -p "$LOG_DIR"
    
    # Set restrictive permissions on log directory
    chmod 700 "$LOG_DIR"
    
    # Rotate logs if necessary
    rotate_logs_if_needed
    
    # Touch log file and set permissions
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"
}

# Check if log level should be written
should_log() {
    local level="$1"
    local current_level_num=${LOG_LEVELS[$LOG_LEVEL]}
    local level_num=${LOG_LEVELS[$level]}
    
    [ "$level_num" -ge "$current_level_num" ]
}

# Write log entry with sanitization
write_log() {
    local level="$1"
    local message="$2"
    local sanitized_message
    
    # Don't log if level is below threshold
    if ! should_log "$level"; then
        return 0
    fi
    
    # Sanitize sensitive data from the message
    sanitized_message=$(sanitize_sensitive_data "$message")
    
    # Create timestamp
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Write to log file
    echo "[$timestamp] [$level] $sanitized_message" >> "$LOG_FILE"
}

# Logging functions for different levels
log_debug() {
    write_log "DEBUG" "$1"
}

log_info() {
    write_log "INFO" "$1"
}

log_warn() {
    write_log "WARN" "$1"
}

log_error() {
    write_log "ERROR" "$1"
}

log_critical() {
    write_log "CRITICAL" "$1"
}

# Log API request (with sanitization)
log_api_request() {
    local method="$1"
    local url="$2"
    local headers="$3"
    local body="$4"
    
    # Sanitize URL
    local sanitized_url=$(sanitize_sensitive_data "$url")
    
    # Sanitize headers (remove Authorization and other sensitive headers)
    local sanitized_headers=$(echo "$headers" | sed -E 's/(Authorization|x-api-key):\s*[^[:space:]]+/\1: [REDACTED]/g')
    sanitized_headers=$(sanitize_sensitive_data "$sanitized_headers")
    
    # Sanitize body
    local sanitized_body=$(sanitize_json_response "$body")
    
    log_info "API请求: $method $sanitized_url"
    log_debug "请求头: $sanitized_headers"
    log_debug "请求体: $sanitized_body"
}

# Log API response (with sanitization)
log_api_response() {
    local status_code="$1"
    local headers="$2"
    local body="$3"
    
    # Sanitize response
    local sanitized_headers=$(sanitize_sensitive_data "$headers")
    local sanitized_body=$(sanitize_json_response "$body")
    
    log_info "API响应: HTTP $status_code"
    log_debug "响应头: $sanitized_headers"
    log_debug "响应体: $sanitized_body"
}

# Log environment information (with sensitive data masked)
log_env_info() {
    local env_info="操作系统: $(uname -a)"
    env_info="$env_info\n当前目录: $(pwd)"
    env_info="$env_info\n脚本路径: ${BASH_SOURCE[1]}"
    
    # Log environment variables (masked)
    local env_vars=$(env | grep -E "^(POPCLIP|ZOOM|ANTHROPIC)" | head -20)
    local masked_env=$(mask_env_vars "$env_vars")
    env_info="$env_info\n环境变量: $masked_env"
    
    log_info "$env_info"
}

# Rotate logs if file size exceeds limit
rotate_logs_if_needed() {
    if [ ! -f "$LOG_FILE" ]; then
        return 0
    fi
    
    # Check file size
    local file_size
    if command -v stat >/dev/null 2>&1; then
        file_size=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo "0")
    else
        file_size=0
    fi
    
    if [ "$file_size" -gt "$MAX_LOG_SIZE" ]; then
        rotate_logs
    fi
}

# Rotate log files
rotate_logs() {
    local base_name="${LOG_FILE%.*}"
    local extension="${LOG_FILE##*.}"
    
    # Remove oldest log file
    local oldest_log="${base_name}.$((MAX_LOG_FILES-1)).$extension"
    [ -f "$oldest_log" ] && rm -f "$oldest_log"
    
    # Rotate existing log files
    for ((i=MAX_LOG_FILES-2; i>=1; i--)); do
        local current_log="${base_name}.$i.$extension"
        local next_log="${base_name}.$((i+1)).$extension"
        [ -f "$current_log" ] && mv "$current_log" "$next_log"
    done
    
    # Move current log to .1
    local first_rotated="${base_name}.1.$extension"
    [ -f "$LOG_FILE" ] && mv "$LOG_FILE" "$first_rotated"
    
    # Create new log file
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"
    
    log_info "日志文件已轮转"
}

# Clean old log files (beyond retention policy)
clean_old_logs() {
    local retention_days="${1:-30}"
    
    find "$LOG_DIR" -name "*.log*" -type f -mtime +"$retention_days" -exec rm -f {} \;
    log_info "清理了 ${retention_days} 天前的日志文件"
}

# Log function entry/exit for debugging
log_function_entry() {
    local function_name="$1"
    local args="$2"
    
    # Sanitize arguments
    local sanitized_args=$(sanitize_sensitive_data "$args")
    
    log_debug "进入函数: $function_name($sanitized_args)"
}

log_function_exit() {
    local function_name="$1"
    local return_code="$2"
    local result="$3"
    
    # Sanitize result
    local sanitized_result=$(sanitize_sensitive_data "$result")
    
    log_debug "退出函数: $function_name (返回码: $return_code, 结果: $sanitized_result)"
}

# Log security event
log_security_event() {
    local event_type="$1"
    local description="$2"
    local severity="${3:-WARN}"
    
    write_log "$severity" "安全事件 [$event_type]: $description"
}

# Initialize logging when this file is sourced
init_logging