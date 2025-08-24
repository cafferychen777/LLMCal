#!/bin/bash

# Security Utilities for LLMCal
# Provides functions for secure handling of sensitive data

# Sanitize sensitive information from strings
sanitize_sensitive_data() {
    local input="$1"
    local output="$input"
    
    # Sanitize API keys
    output=$(echo "$output" | sed -E 's/sk-ant-api03-[A-Za-z0-9_-]{95}/[ANTHROPIC_API_KEY_REDACTED]/g')
    
    # Sanitize Zoom credentials
    output=$(echo "$output" | sed -E 's/"access_token":"[^"]+"/\"access_token\":\"[ACCESS_TOKEN_REDACTED]\"/g')
    output=$(echo "$output" | sed -E 's/"refresh_token":"[^"]+"/\"refresh_token\":\"[REFRESH_TOKEN_REDACTED]\"/g')
    
    # Sanitize email addresses (partially)
    output=$(echo "$output" | sed -E 's/([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/***@\2/g')
    
    # Sanitize long alphanumeric strings that might be credentials (20+ chars)
    output=$(echo "$output" | sed -E 's/[A-Za-z0-9_-]{20,}/[CREDENTIAL_REDACTED]/g')
    
    # Sanitize URLs with credentials
    output=$(echo "$output" | sed -E 's/(https?:\/\/[^:\/]+:)[^@]+@/\1[REDACTED]@/g')
    
    echo "$output"
}

# Sanitize JSON response for logging
sanitize_json_response() {
    local json="$1"
    local sanitized="$json"
    
    # Sanitize common credential fields in JSON
    sanitized=$(echo "$sanitized" | sed -E 's/"(api_key|access_token|refresh_token|client_secret|password|token)":\s*"[^"]+"/"\1": "[REDACTED]"/g')
    
    # Sanitize Authorization headers
    sanitized=$(echo "$sanitized" | sed -E 's/"Authorization":\s*"[^"]+"/\"Authorization\": \"[REDACTED]\"/g')
    
    # Apply general sanitization
    sanitized=$(sanitize_sensitive_data "$sanitized")
    
    echo "$sanitized"
}

# Check if a string contains sensitive data
contains_sensitive_data() {
    local input="$1"
    
    # Check for API key patterns
    if [[ "$input" =~ sk-ant-api03-[A-Za-z0-9_-]{95} ]]; then
        return 0
    fi
    
    # Check for long base64-like strings (potential tokens)
    if [[ "$input" =~ [A-Za-z0-9+/]{50,}={0,2} ]]; then
        return 0
    fi
    
    # Check for JWT tokens
    if [[ "$input" =~ eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+ ]]; then
        return 0
    fi
    
    return 1
}

# Validate credential strength
validate_credential_strength() {
    local cred_name="$1"
    local cred_value="$2"
    local warnings=()
    
    # Check minimum length
    if [ ${#cred_value} -lt 16 ]; then
        warnings+=("$cred_name 长度过短（建议至少16个字符）")
    fi
    
    # Check for common weak patterns
    if [[ "$cred_value" =~ ^[0-9]+$ ]]; then
        warnings+=("$cred_name 仅包含数字，安全性较低")
    fi
    
    if [[ "$cred_value" =~ ^[a-zA-Z]+$ ]]; then
        warnings+=("$cred_name 仅包含字母，安全性较低")
    fi
    
    # Check for dictionary words or common patterns
    case "$cred_value" in
        *password*|*123456*|*qwerty*|*admin*)
            warnings+=("$cred_name 包含常见弱密码模式")
            ;;
    esac
    
    # Output warnings if any
    if [ ${#warnings[@]} -gt 0 ]; then
        printf '%s\n' "${warnings[@]}" >&2
        return 1
    fi
    
    return 0
}

# Secure cleanup of temporary files
secure_cleanup() {
    local files=("$@")
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            # Overwrite with random data before deletion
            if command -v shred >/dev/null 2>&1; then
                shred -vfz -n 3 "$file" 2>/dev/null || rm -f "$file"
            elif command -v gshred >/dev/null 2>&1; then  # GNU shred on macOS
                gshred -vfz -n 3 "$file" 2>/dev/null || rm -f "$file"
            else
                # Fallback: overwrite with random data
                dd if=/dev/urandom of="$file" bs=1024 count=1 2>/dev/null || true
                rm -f "$file"
            fi
        fi
    done
}

# Create secure temporary file
create_secure_temp_file() {
    local prefix="${1:-llmcal}"
    local temp_file
    
    # Create temporary file with restricted permissions
    temp_file=$(mktemp "/tmp/${prefix}.XXXXXX") || return 1
    
    # Set restrictive permissions (owner read/write only)
    chmod 600 "$temp_file" || {
        rm -f "$temp_file"
        return 1
    }
    
    echo "$temp_file"
}

# Mask sensitive environment variables for logging
mask_env_vars() {
    local env_output="$1"
    
    # Mask API keys and tokens
    env_output=$(echo "$env_output" | sed -E 's/(ANTHROPIC_API_KEY|.*TOKEN.*|.*SECRET.*|.*PASSWORD.*)=.*/\1=[REDACTED]/g')
    
    echo "$env_output"
}

# Check file permissions for security
check_file_security() {
    local file_path="$1"
    local warnings=()
    
    if [ ! -f "$file_path" ]; then
        echo "文件不存在: $file_path" >&2
        return 1
    fi
    
    # Get file permissions
    local perms=$(stat -f "%Lp" "$file_path" 2>/dev/null || stat -c "%a" "$file_path" 2>/dev/null)
    
    # Check if file is readable by others
    if [[ "$perms" =~ [0-9][0-9][1-7] ]]; then
        warnings+=("文件 $file_path 可被其他用户读取")
    fi
    
    # Check if file is writable by group or others
    if [[ "$perms" =~ [0-9][2-7][0-9] ]] || [[ "$perms" =~ [0-9][0-9][2-7] ]]; then
        warnings+=("文件 $file_path 可被非所有者写入")
    fi
    
    # Output warnings
    if [ ${#warnings[@]} -gt 0 ]; then
        printf '%s\n' "${warnings[@]}" >&2
        return 1
    fi
    
    return 0
}

# Secure string comparison (constant time)
secure_string_compare() {
    local str1="$1"
    local str2="$2"
    local result=0
    local i
    
    # If lengths differ, comparison fails
    if [ ${#str1} -ne ${#str2} ]; then
        return 1
    fi
    
    # Compare each character
    for ((i=0; i<${#str1}; i++)); do
        if [ "${str1:i:1}" != "${str2:i:1}" ]; then
            result=1
        fi
    done
    
    return $result
}