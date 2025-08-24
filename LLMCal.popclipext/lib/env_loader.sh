#!/bin/bash

# Environment Variable Loader for LLMCal
# Provides secure loading and validation of environment variables

# Load environment variables from .env file if it exists
load_env_file() {
    local env_file="${1:-.env}"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(dirname "$script_dir")"
    local env_path="$project_root/$env_file"
    
    if [ -f "$env_path" ]; then
        # Source the .env file, but only export lines that look like KEY=value
        while IFS= read -r line; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${line// }" ]] && continue
            
            # Extract key=value pairs
            if [[ "$line" =~ ^[[:space:]]*([A-Z_][A-Z0-9_]*)=(.*)$ ]]; then
                local key="${BASH_REMATCH[1]}"
                local value="${BASH_REMATCH[2]}"
                
                # Remove surrounding quotes if present
                value="${value#\"}"
                value="${value%\"}"
                value="${value#\'}"
                value="${value%\'}"
                
                export "$key"="$value"
            fi
        done < "$env_path"
        return 0
    else
        return 1
    fi
}

# Validate required environment variables
validate_env_vars() {
    local required_vars=("$@")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo "错误：缺少必需的环境变量:" >&2
        printf '%s\n' "${missing_vars[@]}" >&2
        return 1
    fi
    
    return 0
}

# Check if API key format is valid
validate_api_key_format() {
    local key_name="$1"
    local key_value="$2"
    
    case "$key_name" in
        "ANTHROPIC_API_KEY"|"POPCLIP_OPTION_ANTHROPIC_API_KEY")
            if [[ ! "$key_value" =~ ^sk-ant-api03-[A-Za-z0-9_-]{95}$ ]]; then
                echo "警告：$key_name 格式可能不正确" >&2
                return 1
            fi
            ;;
        "ZOOM_CLIENT_ID"|"POPCLIP_OPTION_ZOOM_CLIENT_ID")
            if [[ ! "$key_value" =~ ^[A-Za-z0-9_-]{10,}$ ]]; then
                echo "警告：$key_name 格式可能不正确" >&2
                return 1
            fi
            ;;
        "ZOOM_CLIENT_SECRET"|"POPCLIP_OPTION_ZOOM_CLIENT_SECRET")
            if [[ ! "$key_value" =~ ^[A-Za-z0-9_-]{10,}$ ]]; then
                echo "警告：$key_name 格式可能不正确" >&2
                return 1
            fi
            ;;
    esac
    
    return 0
}

# Set up environment variables for PopClip
setup_popclip_env() {
    # Map standard environment variables to PopClip format
    if [ -n "$ANTHROPIC_API_KEY" ] && [ -z "$POPCLIP_OPTION_ANTHROPIC_API_KEY" ]; then
        export POPCLIP_OPTION_ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
    fi
    
    if [ -n "$ZOOM_ACCOUNT_ID" ] && [ -z "$POPCLIP_OPTION_ZOOM_ACCOUNT_ID" ]; then
        export POPCLIP_OPTION_ZOOM_ACCOUNT_ID="$ZOOM_ACCOUNT_ID"
    fi
    
    if [ -n "$ZOOM_CLIENT_ID" ] && [ -z "$POPCLIP_OPTION_ZOOM_CLIENT_ID" ]; then
        export POPCLIP_OPTION_ZOOM_CLIENT_ID="$ZOOM_CLIENT_ID"
    fi
    
    if [ -n "$ZOOM_CLIENT_SECRET" ] && [ -z "$POPCLIP_OPTION_ZOOM_CLIENT_SECRET" ]; then
        export POPCLIP_OPTION_ZOOM_CLIENT_SECRET="$ZOOM_CLIENT_SECRET"
    fi
    
    if [ -n "$ZOOM_EMAIL" ] && [ -z "$POPCLIP_OPTION_ZOOM_EMAIL" ]; then
        export POPCLIP_OPTION_ZOOM_EMAIL="$ZOOM_EMAIL"
    fi
    
    if [ -n "$ZOOM_NAME" ] && [ -z "$POPCLIP_OPTION_ZOOM_NAME" ]; then
        export POPCLIP_OPTION_ZOOM_NAME="$ZOOM_NAME"
    fi
}

# Initialize environment with validation
init_env() {
    local env_file="${1:-.env}"
    
    # Try to load from .env file
    if ! load_env_file "$env_file"; then
        echo "警告：未找到 $env_file 文件，将使用系统环境变量" >&2
    fi
    
    # Set up PopClip environment variables
    setup_popclip_env
    
    # Validate API key formats
    [ -n "$POPCLIP_OPTION_ANTHROPIC_API_KEY" ] && validate_api_key_format "POPCLIP_OPTION_ANTHROPIC_API_KEY" "$POPCLIP_OPTION_ANTHROPIC_API_KEY"
    [ -n "$POPCLIP_OPTION_ZOOM_CLIENT_ID" ] && validate_api_key_format "POPCLIP_OPTION_ZOOM_CLIENT_ID" "$POPCLIP_OPTION_ZOOM_CLIENT_ID"
    [ -n "$POPCLIP_OPTION_ZOOM_CLIENT_SECRET" ] && validate_api_key_format "POPCLIP_OPTION_ZOOM_CLIENT_SECRET" "$POPCLIP_OPTION_ZOOM_CLIENT_SECRET"
    
    return 0
}