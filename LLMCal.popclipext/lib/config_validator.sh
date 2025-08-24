#!/bin/bash

# Configuration Validator for LLMCal
# Provides validation for configuration and credentials

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/security.sh"
source "$SCRIPT_DIR/logger.sh"

# Configuration validation rules
declare -A CONFIG_RULES=(
    ["ANTHROPIC_API_KEY"]="required,format:anthropic_key"
    ["ZOOM_ACCOUNT_ID"]="optional,format:zoom_account"
    ["ZOOM_CLIENT_ID"]="optional,format:zoom_client,required_if:zoom_enabled"
    ["ZOOM_CLIENT_SECRET"]="optional,format:zoom_secret,required_if:zoom_enabled"
    ["ZOOM_EMAIL"]="optional,format:email,required_if:zoom_enabled"
    ["ZOOM_NAME"]="optional,min_length:1,required_if:zoom_enabled"
)

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
    if [[ ! "$secret" =~ ^[A-Za-z0-9_-]{10,}$ ]]; then
        echo "Zoom客户端密钥格式不正确"
        return 1
    fi
    
    # Check minimum strength
    if ! validate_credential_strength "Zoom Client Secret" "$secret"; then
        echo "Zoom客户端密钥强度不足"
        return 1
    fi
    
    return 0
}

validate_email() {
    local email="$1"
    
    # Basic email validation
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "邮箱地址格式不正确"
        return 1
    fi
    
    return 0
}

validate_min_length() {
    local value="$1"
    local min_length="$2"
    
    if [ ${#value} -lt "$min_length" ]; then
        echo "值长度不足，最少需要 $min_length 个字符"
        return 1
    fi
    
    return 0
}

# Check if zoom is enabled based on configuration
is_zoom_enabled() {
    # Check if any zoom-related variables are set (indicating zoom is intended to be used)
    [ -n "$ZOOM_ACCOUNT_ID" ] || [ -n "$ZOOM_CLIENT_ID" ] || [ -n "$ZOOM_CLIENT_SECRET" ]
}

# Parse validation rule
parse_rule() {
    local rule="$1"
    local rules_array
    
    IFS=',' read -ra rules_array <<< "$rule"
    
    for rule_item in "${rules_array[@]}"; do
        echo "$rule_item"
    done
}

# Validate single configuration item
validate_config_item() {
    local key="$1"
    local value="$2"
    local rules="$3"
    local errors=()
    
    log_debug "验证配置项: $key"
    
    # Parse rules
    while IFS= read -r rule; do
        case "$rule" in
            "required")
                if [ -z "$value" ]; then
                    errors+=("$key 是必需的")
                fi
                ;;
            "optional")
                # Skip validation if value is empty for optional fields
                if [ -z "$value" ]; then
                    return 0
                fi
                ;;
            "format:anthropic_key")
                if [ -n "$value" ] && ! validate_anthropic_key "$value"; then
                    errors+=("$(validate_anthropic_key "$value" 2>&1)")
                fi
                ;;
            "format:zoom_account")
                if [ -n "$value" ] && ! validate_zoom_account "$value"; then
                    errors+=("$(validate_zoom_account "$value" 2>&1)")
                fi
                ;;
            "format:zoom_client")
                if [ -n "$value" ] && ! validate_zoom_client "$value"; then
                    errors+=("$(validate_zoom_client "$value" 2>&1)")
                fi
                ;;
            "format:zoom_secret")
                if [ -n "$value" ] && ! validate_zoom_secret "$value"; then
                    errors+=("$(validate_zoom_secret "$value" 2>&1)")
                fi
                ;;
            "format:email")
                if [ -n "$value" ] && ! validate_email "$value"; then
                    errors+=("$(validate_email "$value" 2>&1)")
                fi
                ;;
            "min_length:"*)
                local min_len="${rule#min_length:}"
                if [ -n "$value" ] && ! validate_min_length "$value" "$min_len"; then
                    errors+=("$(validate_min_length "$value" "$min_len" 2>&1)")
                fi
                ;;
            "required_if:zoom_enabled")
                if is_zoom_enabled && [ -z "$value" ]; then
                    errors+=("启用Zoom时 $key 是必需的")
                fi
                ;;
        esac
    done < <(parse_rule "$rules")
    
    # Report errors
    if [ ${#errors[@]} -gt 0 ]; then
        for error in "${errors[@]}"; do
            log_error "配置验证错误: $error"
            echo "错误: $error" >&2
        done
        return 1
    fi
    
    return 0
}

# Validate all configuration
validate_configuration() {
    local validation_errors=0
    local key
    local value
    local rules
    
    log_info "开始配置验证"
    
    # Validate each configured rule
    for key in "${!CONFIG_RULES[@]}"; do
        rules="${CONFIG_RULES[$key]}"
        
        # Get value from environment (check both standard and POPCLIP_ prefixed versions)
        if [ -n "${!key}" ]; then
            value="${!key}"
        else
            local popclip_key="POPCLIP_OPTION_${key}"
            value="${!popclip_key}"
        fi
        
        if ! validate_config_item "$key" "$value" "$rules"; then
            ((validation_errors++))
        fi
    done
    
    # Additional cross-validation checks
    if is_zoom_enabled; then
        log_info "检测到Zoom配置，验证Zoom相关设置"
        
        # Check that if any zoom credential is provided, all required ones are provided
        local zoom_fields=("ZOOM_ACCOUNT_ID" "ZOOM_CLIENT_ID" "ZOOM_CLIENT_SECRET")
        local provided_fields=0
        
        for field in "${zoom_fields[@]}"; do
            local field_value
            if [ -n "${!field}" ]; then
                field_value="${!field}"
            else
                local popclip_field="POPCLIP_OPTION_${field}"
                field_value="${!popclip_field}"
            fi
            
            if [ -n "$field_value" ]; then
                ((provided_fields++))
            fi
        done
        
        if [ "$provided_fields" -gt 0 ] && [ "$provided_fields" -lt 3 ]; then
            log_error "Zoom配置不完整：需要提供所有Zoom凭据（ACCOUNT_ID, CLIENT_ID, CLIENT_SECRET）"
            echo "错误: Zoom配置不完整，需要提供所有必需的凭据" >&2
            ((validation_errors++))
        fi
    fi
    
    # Report validation results
    if [ "$validation_errors" -eq 0 ]; then
        log_info "配置验证通过"
        return 0
    else
        log_error "配置验证失败，发现 $validation_errors 个错误"
        return 1
    fi
}

# Test API connectivity (optional validation)
test_api_connectivity() {
    local test_errors=0
    
    log_info "测试API连接性"
    
    # Test Anthropic API
    if [ -n "$POPCLIP_OPTION_ANTHROPIC_API_KEY" ]; then
        log_debug "测试Anthropic API连接"
        
        local test_response
        test_response=$(curl -s -o /dev/null -w "%{http_code}" \
            -X POST "https://api.anthropic.com/v1/messages" \
            -H "x-api-key: $POPCLIP_OPTION_ANTHROPIC_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -H "content-type: application/json" \
            -d '{"model":"claude-3-haiku-20240307","max_tokens":1,"messages":[{"role":"user","content":"test"}]}')
        
        if [[ "$test_response" =~ ^(200|400)$ ]]; then
            log_info "Anthropic API连接正常"
        else
            log_error "Anthropic API连接失败 (HTTP $test_response)"
            ((test_errors++))
        fi
    fi
    
    # Test Zoom API (if configured)
    if is_zoom_enabled && [ -n "$POPCLIP_OPTION_ZOOM_CLIENT_ID" ] && [ -n "$POPCLIP_OPTION_ZOOM_CLIENT_SECRET" ]; then
        log_debug "测试Zoom API连接"
        
        local auth_token
        auth_token=$(echo -n "$POPCLIP_OPTION_ZOOM_CLIENT_ID:$POPCLIP_OPTION_ZOOM_CLIENT_SECRET" | base64)
        
        local test_response
        test_response=$(curl -s -o /dev/null -w "%{http_code}" \
            -X POST "https://zoom.us/oauth/token?grant_type=account_credentials&account_id=$POPCLIP_OPTION_ZOOM_ACCOUNT_ID" \
            -H "Authorization: Basic $auth_token")
        
        if [ "$test_response" = "200" ]; then
            log_info "Zoom API连接正常"
        else
            log_error "Zoom API连接失败 (HTTP $test_response)"
            ((test_errors++))
        fi
    fi
    
    return $test_errors
}

# Main validation function
run_validation() {
    local validate_connectivity="${1:-false}"
    
    log_info "启动配置验证过程"
    
    # Validate configuration
    if ! validate_configuration; then
        log_critical "配置验证失败，请检查错误并修正配置"
        return 1
    fi
    
    # Test connectivity if requested
    if [ "$validate_connectivity" = "true" ]; then
        if ! test_api_connectivity; then
            log_warn "API连接性测试失败，但配置格式正确"
            return 2  # Different exit code for connectivity issues
        fi
    fi
    
    log_info "配置验证完成"
    return 0
}