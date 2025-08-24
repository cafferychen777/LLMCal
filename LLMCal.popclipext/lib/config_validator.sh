#!/bin/bash

# Configuration Validator for LLMCal - Bash 3.2 Compatible Version
# Provides validation for configuration and credentials

# Source required utilities
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
source "$SCRIPT_DIR/security.sh"
source "$SCRIPT_DIR/logger.sh"

# Get validation rules for a config key
get_config_rules() {
    local key="$1"
    case "$key" in
        "ANTHROPIC_API_KEY")
            echo "required,format:anthropic_key"
            ;;
        "ZOOM_ACCOUNT_ID")
            echo "optional,format:zoom_account"
            ;;
        "ZOOM_CLIENT_ID")
            echo "optional,format:zoom_client,required_if:zoom_enabled"
            ;;
        "ZOOM_CLIENT_SECRET")
            echo "optional,format:zoom_secret,required_if:zoom_enabled"
            ;;
        "ZOOM_EMAIL")
            echo "optional,format:email,required_if:zoom_enabled"
            ;;
        "ZOOM_NAME")
            echo "optional,min_length:1,required_if:zoom_enabled"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Validation functions for different formats
validate_anthropic_key() {
    local key="$1"
    
    # Check format: sk-ant-api03-[95 characters]
    if [[ ! "$key" =~ ^sk-ant-api03-[A-Za-z0-9_-]{95}$ ]]; then
        echo "Anthropic API密钥格式不正确。应为 sk-ant-api03-[95个字符]"
        return 1
    fi
    
    return 0
}

validate_zoom_account() {
    local account_id="$1"
    
    # Zoom account ID format (typically alphanumeric with dashes/underscores)
    if [[ ! "$account_id" =~ ^[A-Za-z0-9_-]{10,50}$ ]]; then
        echo "Zoom账户ID格式不正确"
        return 1
    fi
    
    return 0
}

validate_zoom_client() {
    local client_id="$1"
    
    # Zoom client ID format
    if [[ ! "$client_id" =~ ^[A-Za-z0-9_-]{10,50}$ ]]; then
        echo "Zoom客户端ID格式不正确"
        return 1
    fi
    
    return 0
}

validate_zoom_secret() {
    local secret="$1"
    
    # Zoom client secret format
    if [[ ! "$secret" =~ ^[A-Za-z0-9_-]{10,100}$ ]]; then
        echo "Zoom客户端密钥格式不正确"
        return 1
    fi
    
    return 0
}

validate_email() {
    local email="$1"
    
    # Basic email validation
    if [[ ! "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        echo "电子邮件地址格式不正确"
        return 1
    fi
    
    return 0
}

# Check if Zoom is enabled
is_zoom_enabled() {
    # Check if any Zoom credential is provided
    if [[ -n "${POPCLIP_OPTION_ZOOM_ACCOUNT_ID:-}" ]] || \
       [[ -n "${POPCLIP_OPTION_ZOOM_CLIENT_ID:-}" ]] || \
       [[ -n "${POPCLIP_OPTION_ZOOM_CLIENT_SECRET:-}" ]]; then
        return 0  # true - Zoom is enabled
    fi
    return 1  # false - Zoom is not enabled
}

# Validate a single configuration value
validate_config_value() {
    local key="$1"
    local value="$2"
    local rules=$(get_config_rules "$key")
    
    if [[ -z "$rules" ]]; then
        return 0  # No rules defined, consider valid
    fi
    
    local IFS=','
    for rule in $rules; do
        case "$rule" in
            "required")
                if [[ -z "$value" ]]; then
                    echo "$key 是必需的配置"
                    return 1
                fi
                ;;
            "optional")
                # Optional fields can be empty
                ;;
            "format:anthropic_key")
                if [[ -n "$value" ]] && ! validate_anthropic_key "$value"; then
                    return 1
                fi
                ;;
            "format:zoom_account")
                if [[ -n "$value" ]] && ! validate_zoom_account "$value"; then
                    return 1
                fi
                ;;
            "format:zoom_client")
                if [[ -n "$value" ]] && ! validate_zoom_client "$value"; then
                    return 1
                fi
                ;;
            "format:zoom_secret")
                if [[ -n "$value" ]] && ! validate_zoom_secret "$value"; then
                    return 1
                fi
                ;;
            "format:email")
                if [[ -n "$value" ]] && ! validate_email "$value"; then
                    return 1
                fi
                ;;
            "min_length:"*)
                local min_len="${rule#min_length:}"
                if [[ -n "$value" ]] && [[ ${#value} -lt $min_len ]]; then
                    echo "$key 至少需要 $min_len 个字符"
                    return 1
                fi
                ;;
            "required_if:zoom_enabled")
                if is_zoom_enabled && [[ -z "$value" ]]; then
                    echo "$key 在启用Zoom功能时是必需的"
                    return 1
                fi
                ;;
        esac
    done
    
    return 0
}

# Validate all configuration
validate_all_config() {
    local has_errors=0
    local error_messages=""
    
    log_info "验证配置..."
    
    # List of all config keys to validate
    local config_keys=(
        "ANTHROPIC_API_KEY"
        "ZOOM_ACCOUNT_ID"
        "ZOOM_CLIENT_ID"
        "ZOOM_CLIENT_SECRET"
        "ZOOM_EMAIL"
        "ZOOM_NAME"
    )
    
    for key in "${config_keys[@]}"; do
        # Convert key to PopClip option format
        local popclip_key="POPCLIP_OPTION_$key"
        local value="${!popclip_key:-}"
        
        if ! error_msg=$(validate_config_value "$key" "$value" 2>&1); then
            has_errors=1
            error_messages="$error_messages\n- $error_msg"
            log_error "配置验证失败: $error_msg"
        fi
    done
    
    if [[ $has_errors -eq 1 ]]; then
        echo -e "配置验证失败:$error_messages"
        return 1
    fi
    
    log_info "配置验证成功"
    return 0
}

# Test API connectivity (optional)
test_api_connectivity() {
    local api_key="${POPCLIP_OPTION_ANTHROPIC_API_KEY:-}"
    
    if [[ -z "$api_key" ]]; then
        echo "无法测试API连接: 缺少API密钥"
        return 1
    fi
    
    log_info "测试Anthropic API连接..."
    
    # Simple connectivity test
    local response=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "https://api.anthropic.com/v1/messages" \
        -H "x-api-key: $api_key" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d '{"model": "claude-3-5-haiku-20241022", "max_tokens": 10, "messages": [{"role": "user", "content": "test"}]}' \
        --connect-timeout 5)
    
    case "$response" in
        200|201)
            log_info "API连接测试成功"
            return 0
            ;;
        401)
            log_error "API密钥无效"
            echo "API密钥无效，请检查您的Anthropic API密钥"
            return 1
            ;;
        429)
            log_warn "API速率限制"
            echo "API速率限制，请稍后再试"
            return 1
            ;;
        *)
            log_error "API连接失败: HTTP $response"
            echo "无法连接到Anthropic API (HTTP $response)"
            return 1
            ;;
    esac
}

# Cross-validate related configurations
cross_validate_config() {
    log_info "执行配置交叉验证..."
    
    # If Zoom is partially configured, ensure all required fields are present
    if is_zoom_enabled; then
        local zoom_fields=(
            "POPCLIP_OPTION_ZOOM_CLIENT_ID"
            "POPCLIP_OPTION_ZOOM_CLIENT_SECRET"
        )
        
        local missing_fields=""
        for field in "${zoom_fields[@]}"; do
            if [[ -z "${!field:-}" ]]; then
                missing_fields="$missing_fields $field"
            fi
        done
        
        if [[ -n "$missing_fields" ]]; then
            echo "Zoom配置不完整，缺少:$missing_fields"
            return 1
        fi
    fi
    
    return 0
}

# Main validation function
validate_configuration() {
    log_info "开始配置验证..."
    
    # Step 1: Validate all individual configurations
    if ! validate_all_config; then
        return 1
    fi
    
    # Step 2: Cross-validate related configurations
    if ! cross_validate_config; then
        return 1
    fi
    
    # Step 3: Optional API connectivity test
    # Uncomment to enable:
    # if ! test_api_connectivity; then
    #     log_warn "API连接测试失败，但继续执行"
    # fi
    
    log_info "配置验证完成"
    return 0
}

# Export functions
export -f validate_configuration
export -f validate_config_value
export -f test_api_connectivity