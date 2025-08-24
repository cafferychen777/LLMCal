#!/bin/bash

# Security Setup Script for LLMCal
# This script helps users set up secure environment variables and validate configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
POPCLIP_EXT_DIR="$PROJECT_ROOT/LLMCal.popclipext"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

print_header() {
    echo
    print_status "$BLUE" "=============================================="
    print_status "$BLUE" "$1"
    print_status "$BLUE" "=============================================="
    echo
}

# Check if .env file exists
check_env_file() {
    if [ -f "$PROJECT_ROOT/.env" ]; then
        print_status "$GREEN" "✓ .env文件已存在"
        return 0
    else
        print_status "$YELLOW" "! .env文件不存在"
        return 1
    fi
}

# Create .env file from template
create_env_file() {
    if [ ! -f "$PROJECT_ROOT/.env.example" ]; then
        print_status "$RED" "错误：找不到 .env.example 模板文件"
        exit 1
    fi
    
    print_status "$BLUE" "正在创建 .env 文件..."
    cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
    chmod 600 "$PROJECT_ROOT/.env"
    print_status "$GREEN" "✓ .env文件已创建，权限已设置为600"
}

# Prompt for API keys
prompt_for_credentials() {
    print_header "API凭据配置"
    
    echo "请提供以下API凭据（按Enter跳过可选项）："
    echo
    
    # Anthropic API Key
    echo -n "Anthropic API Key (必需): "
    read -s anthropic_key
    echo
    
    if [ -n "$anthropic_key" ]; then
        sed -i '' "s/ANTHROPIC_API_KEY=.*/ANTHROPIC_API_KEY=$anthropic_key/" "$PROJECT_ROOT/.env"
        print_status "$GREEN" "✓ Anthropic API Key已设置"
    else
        print_status "$RED" "错误：Anthropic API Key是必需的"
        exit 1
    fi
    
    echo
    echo "Zoom集成配置 (可选，如不需要请跳过)："
    
    # Zoom credentials
    echo -n "Zoom Account ID (可选): "
    read zoom_account_id
    
    echo -n "Zoom Client ID (可选): "
    read zoom_client_id
    
    echo -n "Zoom Client Secret (可选): "
    read -s zoom_client_secret
    echo
    
    echo -n "Zoom Email (可选): "
    read zoom_email
    
    echo -n "Zoom Display Name (可选): "
    read zoom_name
    
    # Update .env file
    if [ -n "$zoom_account_id" ]; then
        sed -i '' "s/ZOOM_ACCOUNT_ID=.*/ZOOM_ACCOUNT_ID=$zoom_account_id/" "$PROJECT_ROOT/.env"
    fi
    
    if [ -n "$zoom_client_id" ]; then
        sed -i '' "s/ZOOM_CLIENT_ID=.*/ZOOM_CLIENT_ID=$zoom_client_id/" "$PROJECT_ROOT/.env"
    fi
    
    if [ -n "$zoom_client_secret" ]; then
        sed -i '' "s/ZOOM_CLIENT_SECRET=.*/ZOOM_CLIENT_SECRET=$zoom_client_secret/" "$PROJECT_ROOT/.env"
    fi
    
    if [ -n "$zoom_email" ]; then
        sed -i '' "s/ZOOM_EMAIL=.*/ZOOM_EMAIL=$zoom_email/" "$PROJECT_ROOT/.env"
    fi
    
    if [ -n "$zoom_name" ]; then
        sed -i '' "s/ZOOM_NAME=.*/ZOOM_NAME=$zoom_name/" "$PROJECT_ROOT/.env"
    fi
    
    print_status "$GREEN" "✓ 凭据配置完成"
}

# Validate configuration
validate_config() {
    print_header "配置验证"
    
    # Source the environment loader and validator
    if ! source "$POPCLIP_EXT_DIR/lib/env_loader.sh"; then
        print_status "$RED" "错误：无法加载环境变量管理器"
        exit 1
    fi
    
    if ! source "$POPCLIP_EXT_DIR/lib/config_validator.sh"; then
        print_status "$RED" "错误：无法加载配置验证器"
        exit 1
    fi
    
    # Initialize environment
    init_env
    
    # Run validation
    if run_validation true; then
        print_status "$GREEN" "✓ 配置验证通过"
        return 0
    else
        print_status "$RED" "✗ 配置验证失败"
        return 1
    fi
}

# Check file permissions
check_permissions() {
    print_header "权限检查"
    
    local issues_found=0
    
    # Check .env file permissions
    if [ -f "$PROJECT_ROOT/.env" ]; then
        local perms=$(stat -f "%Lp" "$PROJECT_ROOT/.env" 2>/dev/null)
        if [ "$perms" != "600" ]; then
            print_status "$YELLOW" "! .env文件权限不安全 ($perms)，正在修复..."
            chmod 600 "$PROJECT_ROOT/.env"
            print_status "$GREEN" "✓ .env文件权限已修复为600"
        else
            print_status "$GREEN" "✓ .env文件权限正常"
        fi
    fi
    
    # Check script permissions
    for script in "$POPCLIP_EXT_DIR"/lib/*.sh "$POPCLIP_EXT_DIR/calendar.sh"; do
        if [ -f "$script" ] && [ ! -x "$script" ]; then
            print_status "$YELLOW" "! 脚本文件不可执行: $(basename "$script")，正在修复..."
            chmod +x "$script"
            ((issues_found++))
        fi
    done
    
    if [ $issues_found -eq 0 ]; then
        print_status "$GREEN" "✓ 所有脚本权限正常"
    else
        print_status "$GREEN" "✓ 已修复 $issues_found 个权限问题"
    fi
}

# Run security check
run_security_check() {
    print_header "安全检查"
    
    local warnings=0
    
    # Check for hardcoded credentials in files
    print_status "$BLUE" "检查硬编码凭据..."
    
    if grep -r "sk-ant-api03-" "$POPCLIP_EXT_DIR" --exclude-dir=test_logs >/dev/null 2>&1; then
        print_status "$RED" "✗ 发现硬编码的Anthropic API密钥"
        ((warnings++))
    fi
    
    if grep -r -E "(COoBTtIEQ|3V73guRvQ3yLZauBeAjSw|Iu527ASeZbOuQso403XYN35X14JH4BVd)" "$POPCLIP_EXT_DIR" --exclude-dir=test_logs >/dev/null 2>&1; then
        print_status "$RED" "✗ 发现硬编码的Zoom凭据"
        ((warnings++))
    fi
    
    if [ $warnings -eq 0 ]; then
        print_status "$GREEN" "✓ 未发现硬编码凭据"
    fi
    
    # Check .gitignore
    if grep -q ".env" "$PROJECT_ROOT/.gitignore"; then
        print_status "$GREEN" "✓ .gitignore已正确配置"
    else
        print_status "$YELLOW" "! .gitignore中缺少.env配置"
        ((warnings++))
    fi
    
    return $warnings
}

# Main function
main() {
    print_header "LLMCal 安全配置向导"
    
    echo "此向导将帮助您安全地配置LLMCal扩展。"
    echo
    
    # Step 1: Check and create .env file
    if ! check_env_file; then
        echo "是否创建新的.env文件？(y/n): "
        read -r create_env
        if [[ "$create_env" =~ ^[Yy] ]]; then
            create_env_file
            prompt_for_credentials
        else
            print_status "$YELLOW" "跳过.env文件创建"
        fi
    else
        echo "是否重新配置API凭据？(y/n): "
        read -r reconfig
        if [[ "$reconfig" =~ ^[Yy] ]]; then
            prompt_for_credentials
        fi
    fi
    
    # Step 2: Check permissions
    check_permissions
    
    # Step 3: Validate configuration
    if [ -f "$PROJECT_ROOT/.env" ]; then
        validate_config
    else
        print_status "$YELLOW" "跳过配置验证（无.env文件）"
    fi
    
    # Step 4: Security check
    local security_warnings
    security_warnings=$(run_security_check)
    
    # Summary
    print_header "配置完成"
    
    if [ "$security_warnings" -eq 0 ]; then
        print_status "$GREEN" "🎉 安全配置完成！LLMCal已准备就绪。"
    else
        print_status "$YELLOW" "⚠️  配置完成，但发现 $security_warnings 个安全警告，请检查上述输出。"
    fi
    
    echo
    echo "下一步："
    echo "1. 将LLMCal.popclipext文件夹安装到PopClip"
    echo "2. 在PopClip中配置API密钥（如果未使用.env文件）"
    echo "3. 测试扩展功能"
    echo
    echo "如需帮助，请查看README.md文件。"
}

# Run main function
main "$@"