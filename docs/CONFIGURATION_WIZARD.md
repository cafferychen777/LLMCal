# LLMCal Configuration Wizard

This guide provides a step-by-step configuration wizard to help you set up LLMCal perfectly for your needs.

## 🧙‍♂️ Configuration Wizard

### Prerequisites Check

Before starting, let's verify you have everything needed:

```bash
#!/bin/bash
# Configuration Wizard - Prerequisites Check

echo "🔍 LLMCal Configuration Wizard - Prerequisites Check"
echo "=================================================="

# Check macOS version
echo "📱 Checking macOS version..."
os_version=$(sw_vers -productVersion)
echo "   macOS version: $os_version"
if [[ $(echo "$os_version" | cut -d. -f1) -lt 11 ]]; then
    echo "   ⚠️  Warning: macOS 11+ recommended for best performance"
else
    echo "   ✅ macOS version compatible"
fi

# Check PopClip installation
echo "🖱️  Checking PopClip installation..."
if pgrep -x "PopClip" > /dev/null; then
    echo "   ✅ PopClip is running"
    popclip_path="/Applications/PopClip.app"
    if [[ -d "$popclip_path" ]]; then
        popclip_version=$(mdls -name kMDItemVersion "$popclip_path" 2>/dev/null | cut -d'"' -f2)
        echo "   PopClip version: ${popclip_version:-Unknown}"
    fi
else
    echo "   ❌ PopClip is not running"
    echo "   👉 Please install PopClip from https://www.popclip.app"
fi

# Check network connectivity
echo "🌐 Checking network connectivity..."
if curl -s --connect-timeout 5 https://api.anthropic.com > /dev/null 2>&1; then
    echo "   ✅ Can reach Anthropic API"
else
    echo "   ❌ Cannot reach Anthropic API"
    echo "   👉 Check your internet connection or firewall settings"
fi

echo ""
echo "Prerequisites check complete!"
```

### Step 1: Basic Setup

#### 1.1 Choose Your Configuration Method

**Option A: Automatic Setup (Recommended)**
- Guided wizard with defaults
- Best for most users
- Quick 5-minute setup

**Option B: Custom Setup (Advanced)**
- Full control over all settings
- Best for power users
- 15-minute detailed setup

**Option C: Corporate Setup**
- Proxy and network settings
- Domain-specific configurations
- IT-friendly deployment

---

### 🟢 Option A: Automatic Setup

#### Step A1: API Key Setup

```bash
#!/bin/bash
# Automatic API Key Configuration

echo "🔑 API Key Configuration"
echo "======================="

# Check if API key already exists
if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    echo "   ℹ️  API key found in environment"
    echo "   Do you want to use the existing key? (y/n)"
    read -r use_existing
    if [[ $use_existing != "y" ]]; then
        unset ANTHROPIC_API_KEY
    fi
fi

if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
    echo "   👉 Please enter your Anthropic API key:"
    echo "   (Get one from https://console.anthropic.com)"
    read -rs api_key
    
    # Validate API key format
    if [[ $api_key =~ ^sk-ant-api[0-9]{2}- ]]; then
        echo "   ✅ API key format looks correct"
        export ANTHROPIC_API_KEY="$api_key"
    else
        echo "   ⚠️  API key format unusual (should start with sk-ant-)"
        echo "   Continue anyway? (y/n)"
        read -r continue_anyway
        if [[ $continue_anyway == "y" ]]; then
            export ANTHROPIC_API_KEY="$api_key"
        else
            echo "   ❌ Configuration cancelled"
            exit 1
        fi
    fi
fi

# Test API key
echo "   🧪 Testing API key..."
test_response=$(curl -s -w "%{http_code}" \
    -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
    -H "Content-Type: application/json" \
    -H "anthropic-version: 2023-06-01" \
    -d '{"model":"claude-3-haiku-20240307","max_tokens":10,"messages":[{"role":"user","content":"test"}]}' \
    https://api.anthropic.com/v1/messages)

http_code="${test_response: -3}"
if [[ "$http_code" == "200" ]]; then
    echo "   ✅ API key is working!"
else
    echo "   ❌ API key test failed (HTTP $http_code)"
    echo "   Please check your key and try again"
    exit 1
fi
```

#### Step A2: Auto-detect Settings

```bash
#!/bin/bash
# Auto-detect optimal settings

echo "🔍 Auto-detecting optimal settings..."
echo "===================================="

# Detect timezone
echo "   📍 Detecting timezone..."
timezone=$(readlink /etc/localtime | sed 's#.*/zoneinfo/##')
echo "   Detected timezone: $timezone"

# Detect language
echo "   🌍 Detecting language..."
language=$(defaults read .GlobalPreferences AppleLanguages | head -1 | tr -d '", ' | cut -d'-' -f1)
echo "   Detected language: $language"

# Detect calendar app
echo "   📅 Checking calendar setup..."
if osascript -e 'tell application "Calendar" to get name of calendars' > /dev/null 2>&1; then
    echo "   ✅ Calendar app is accessible"
    calendar_count=$(osascript -e 'tell application "Calendar" to count calendars')
    echo "   Available calendars: $calendar_count"
else
    echo "   ❌ Calendar app access needed"
    echo "   👉 Please grant calendar permissions when prompted"
fi

# Generate configuration
cat > ~/.llmcal/config << EOF
# LLMCal Auto-generated Configuration
# Generated on $(date)

# API Configuration
ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY

# Regional Settings
DEFAULT_TIMEZONE=$timezone
LANGUAGE=$language

# Performance Settings
API_TIMEOUT=30
MAX_RETRIES=3
CACHE_RESPONSES=true

# Calendar Settings
DEFAULT_CALENDAR=Calendar
DEFAULT_REMINDER_MINUTES=15

# Logging
LOG_LEVEL=info
LOG_FILE=$HOME/.llmcal/logs/llmcal.log

# Generated by automatic setup
SETUP_VERSION=1.0
SETUP_DATE=$(date -Iseconds)
EOF

echo "   ✅ Configuration saved to ~/.llmcal/config"
```

---

### 🔧 Option B: Custom Setup

#### Step B1: Detailed API Configuration

```bash
#!/bin/bash
# Custom API Configuration

echo "🔧 Custom API Configuration"
echo "==========================="

# API Key
echo "1. API Key Setup"
echo "   Enter your Anthropic API key:"
read -rs api_key

# Model Selection
echo ""
echo "2. Model Selection"
echo "   Available models:"
echo "   1) claude-3-haiku-20240307 (Fast, economical)"
echo "   2) claude-3-sonnet-20240229 (Balanced, recommended)"
echo "   3) claude-3-opus-20240229 (Most capable, slower)"
echo "   Choose model (1-3):"
read -r model_choice

case $model_choice in
    1) model="claude-3-haiku-20240307" ;;
    2) model="claude-3-sonnet-20240229" ;;
    3) model="claude-3-opus-20240229" ;;
    *) model="claude-3-sonnet-20240229" ;;
esac

# Performance Settings
echo ""
echo "3. Performance Settings"
echo "   API timeout (seconds, recommended: 30):"
read -r timeout
timeout=${timeout:-30}

echo "   Max retries (recommended: 3):"
read -r retries
retries=${retries:-3}

echo "   Enable response caching? (y/n):"
read -r cache
cache_enabled=$([[ $cache == "y" ]] && echo "true" || echo "false")

# Save configuration
export ANTHROPIC_API_KEY="$api_key"
export MODEL_NAME="$model"
export API_TIMEOUT="$timeout"
export MAX_RETRIES="$retries"
export CACHE_RESPONSES="$cache_enabled"
```

#### Step B2: Advanced Calendar Settings

```bash
#!/bin/bash
# Advanced Calendar Configuration

echo "📅 Advanced Calendar Configuration"
echo "=================================="

# List available calendars
echo "1. Available Calendars:"
calendars=$(osascript -e 'tell application "Calendar" to get name of every calendar' 2>/dev/null || echo "Calendar access needed")
echo "$calendars"

echo ""
echo "2. Default Calendar"
echo "   Enter the name of your preferred calendar (or press Enter for 'Calendar'):"
read -r default_calendar
default_calendar=${default_calendar:-Calendar}

echo ""
echo "3. Default Reminder Settings"
echo "   Default reminder time (minutes before event):"
echo "   0) No reminder"
echo "   5) 5 minutes"
echo "   15) 15 minutes (recommended)"
echo "   30) 30 minutes"
echo "   60) 1 hour"
echo "   Enter minutes:"
read -r reminder_minutes
reminder_minutes=${reminder_minutes:-15}

echo ""
echo "4. Recurring Event Preferences"
echo "   How should recurring events be handled?"
echo "   1) Create single occurrence only"
echo "   2) Create full recurring series (recommended)"
echo "   Choose option (1-2):"
read -r recurring_option
recurring_full=$([[ $recurring_option == "2" ]] && echo "true" || echo "false")

export DEFAULT_CALENDAR="$default_calendar"
export DEFAULT_REMINDER_MINUTES="$reminder_minutes"
export CREATE_RECURRING_SERIES="$recurring_full"
```

#### Step B3: Localization Settings

```bash
#!/bin/bash
# Localization Configuration

echo "🌍 Localization Configuration"
echo "============================="

echo "1. Language Settings"
echo "   Available languages:"
echo "   en) English"
echo "   zh) 中文 (Chinese)"
echo "   es) Español (Spanish)"
echo "   fr) Français (French)"
echo "   de) Deutsch (German)"
echo "   ja) 日本語 (Japanese)"
echo "   auto) Auto-detect (recommended)"
echo "   Choose language:"
read -r language
language=${language:-auto}

echo ""
echo "2. Timezone Configuration"
echo "   Current system timezone: $(readlink /etc/localtime | sed 's#.*/zoneinfo/##')"
echo "   Use system timezone? (y/n):"
read -r use_system_tz

if [[ $use_system_tz == "y" ]]; then
    timezone=$(readlink /etc/localtime | sed 's#.*/zoneinfo/##')
else
    echo "   Common timezones:"
    echo "   America/New_York (EST/EDT)"
    echo "   America/Los_Angeles (PST/PDT)"
    echo "   Europe/London (GMT/BST)"
    echo "   Europe/Paris (CET/CEST)"
    echo "   Asia/Tokyo (JST)"
    echo "   Enter timezone:"
    read -r timezone
fi

echo ""
echo "3. Date/Time Format"
echo "   Preferred time format:"
echo "   1) 12-hour (2:30 PM)"
echo "   2) 24-hour (14:30)"
echo "   Choose format (1-2):"
read -r time_format
time_24h=$([[ $time_format == "2" ]] && echo "true" || echo "false")

export LANGUAGE="$language"
export DEFAULT_TIMEZONE="$timezone"
export USE_24H_FORMAT="$time_24h"
```

---

### 🏢 Option C: Corporate Setup

#### Step C1: Network Configuration

```bash
#!/bin/bash
# Corporate Network Configuration

echo "🏢 Corporate Network Configuration"
echo "=================================="

echo "1. Proxy Settings"
echo "   Does your network use a proxy? (y/n):"
read -r use_proxy

if [[ $use_proxy == "y" ]]; then
    echo "   HTTP Proxy (e.g., http://proxy.company.com:8080):"
    read -r http_proxy
    
    echo "   HTTPS Proxy (usually same as HTTP):"
    read -r https_proxy
    https_proxy=${https_proxy:-$http_proxy}
    
    echo "   No proxy for (comma-separated, e.g., localhost,127.0.0.1,.company.com):"
    read -r no_proxy
    
    export HTTP_PROXY="$http_proxy"
    export HTTPS_PROXY="$https_proxy"
    export NO_PROXY="$no_proxy"
fi

echo ""
echo "2. Security Settings"
echo "   Custom CA certificates needed? (y/n):"
read -r custom_ca

if [[ $custom_ca == "y" ]]; then
    echo "   Path to CA certificate bundle:"
    read -r ca_bundle_path
    export REQUESTS_CA_BUNDLE="$ca_bundle_path"
fi

echo ""
echo "3. Domain Settings"
echo "   Company domain (for automatic attendee detection):"
read -r company_domain
export COMPANY_DOMAIN="$company_domain"
```

#### Step C2: Deployment Settings

```bash
#!/bin/bash
# Corporate Deployment Settings

echo "📦 Corporate Deployment Configuration"
echo "===================================="

echo "1. Central Configuration"
echo "   Use central configuration server? (y/n):"
read -r central_config

if [[ $central_config == "y" ]]; then
    echo "   Configuration server URL:"
    read -r config_server_url
    export CONFIG_SERVER_URL="$config_server_url"
fi

echo ""
echo "2. Logging and Monitoring"
echo "   Send logs to central server? (y/n):"
read -r central_logging

if [[ $central_logging == "y" ]]; then
    echo "   Log server URL:"
    read -r log_server_url
    export LOG_SERVER_URL="$log_server_url"
fi

echo ""
echo "3. Policy Settings"
echo "   Enforce calendar naming convention? (y/n):"
read -r enforce_naming

if [[ $enforce_naming == "y" ]]; then
    echo "   Calendar name prefix (e.g., 'CORP-'):"
    read -r calendar_prefix
    export CALENDAR_PREFIX="$calendar_prefix"
fi
```

---

## 🔧 Configuration Management

### Save Configuration

```bash
#!/bin/bash
# Save all configuration settings

save_configuration() {
    local config_file="$HOME/.llmcal/config"
    
    echo "💾 Saving configuration to $config_file"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$config_file")"
    
    # Write configuration
    cat > "$config_file" << EOF
# LLMCal Configuration File
# Generated on $(date)

# API Settings
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
MODEL_NAME=${MODEL_NAME:-claude-3-sonnet-20240229}
API_TIMEOUT=${API_TIMEOUT:-30}
MAX_RETRIES=${MAX_RETRIES:-3}
CACHE_RESPONSES=${CACHE_RESPONSES:-true}

# Regional Settings
DEFAULT_TIMEZONE=${DEFAULT_TIMEZONE}
LANGUAGE=${LANGUAGE:-auto}
USE_24H_FORMAT=${USE_24H_FORMAT:-false}

# Calendar Settings
DEFAULT_CALENDAR=${DEFAULT_CALENDAR:-Calendar}
DEFAULT_REMINDER_MINUTES=${DEFAULT_REMINDER_MINUTES:-15}
CREATE_RECURRING_SERIES=${CREATE_RECURRING_SERIES:-true}

# Network Settings
HTTP_PROXY=${HTTP_PROXY:-}
HTTPS_PROXY=${HTTPS_PROXY:-}
NO_PROXY=${NO_PROXY:-}
REQUESTS_CA_BUNDLE=${REQUESTS_CA_BUNDLE:-}

# Corporate Settings
COMPANY_DOMAIN=${COMPANY_DOMAIN:-}
CONFIG_SERVER_URL=${CONFIG_SERVER_URL:-}
LOG_SERVER_URL=${LOG_SERVER_URL:-}
CALENDAR_PREFIX=${CALENDAR_PREFIX:-}

# Logging
LOG_LEVEL=${LOG_LEVEL:-info}
LOG_FILE=${LOG_FILE:-$HOME/.llmcal/logs/llmcal.log}
MAX_LOG_SIZE=${MAX_LOG_SIZE:-10485760}  # 10MB

# Metadata
CONFIG_VERSION=1.0
CREATED_DATE=$(date -Iseconds)
SETUP_METHOD=${SETUP_METHOD:-wizard}
EOF
    
    echo "✅ Configuration saved successfully!"
}
```

### Validate Configuration

```bash
#!/bin/bash
# Validate configuration settings

validate_configuration() {
    echo "🔍 Validating configuration..."
    
    local config_file="$HOME/.llmcal/config"
    local errors=0
    
    # Check if config file exists
    if [[ ! -f "$config_file" ]]; then
        echo "❌ Configuration file not found: $config_file"
        return 1
    fi
    
    # Source configuration
    source "$config_file"
    
    # Validate API key
    if [[ -z "$ANTHROPIC_API_KEY" ]]; then
        echo "❌ ANTHROPIC_API_KEY not set"
        ((errors++))
    elif ! curl -s -f -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
         https://api.anthropic.com/v1/messages > /dev/null 2>&1; then
        echo "❌ API key validation failed"
        ((errors++))
    else
        echo "✅ API key is valid"
    fi
    
    # Validate timezone
    if [[ -n "$DEFAULT_TIMEZONE" ]]; then
        if [[ -f "/usr/share/zoneinfo/$DEFAULT_TIMEZONE" ]]; then
            echo "✅ Timezone is valid: $DEFAULT_TIMEZONE"
        else
            echo "⚠️  Timezone might be invalid: $DEFAULT_TIMEZONE"
        fi
    fi
    
    # Validate calendar access
    if osascript -e 'tell application "Calendar" to get name of calendars' > /dev/null 2>&1; then
        echo "✅ Calendar access is working"
    else
        echo "❌ Calendar access permission needed"
        ((errors++))
    fi
    
    # Check log directory
    local log_dir
    log_dir=$(dirname "$LOG_FILE")
    if [[ ! -d "$log_dir" ]]; then
        echo "📁 Creating log directory: $log_dir"
        mkdir -p "$log_dir"
    fi
    echo "✅ Log directory exists: $log_dir"
    
    if [[ $errors -eq 0 ]]; then
        echo "🎉 Configuration validation passed!"
        return 0
    else
        echo "❌ Configuration validation failed with $errors errors"
        return 1
    fi
}
```

### Test Configuration

```bash
#!/bin/bash
# Test configuration with sample event

test_configuration() {
    echo "🧪 Testing configuration with sample event..."
    
    # Set test environment
    export POPCLIP_TEXT="Test meeting tomorrow at 2pm for 1 hour"
    export POPCLIP_BUNDLE_PATH="$(dirname "$0")"
    
    # Source configuration
    source "$HOME/.llmcal/config"
    
    # Test API call
    echo "   Testing API call..."
    local response
    response=$(curl -s -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
        -H "Content-Type: application/json" \
        -H "anthropic-version: 2023-06-01" \
        -d '{
            "model": "'${MODEL_NAME:-claude-3-sonnet-20240229}'",
            "max_tokens": 1024,
            "messages": [
                {
                    "role": "user",
                    "content": "Convert this to calendar event JSON: '"$POPCLIP_TEXT"'"
                }
            ]
        }' \
        https://api.anthropic.com/v1/messages)
    
    if echo "$response" | jq -e '.content[0].text' > /dev/null 2>&1; then
        echo "   ✅ API call successful"
    else
        echo "   ❌ API call failed"
        return 1
    fi
    
    # Test calendar access
    echo "   Testing calendar access..."
    if osascript -e "tell application \"Calendar\" to make new event at end of events of calendar \"$DEFAULT_CALENDAR\" with properties {summary:\"LLMCal Test\"}" > /dev/null 2>&1; then
        echo "   ✅ Calendar access successful"
        # Clean up test event
        osascript -e "tell application \"Calendar\" to delete (every event of calendar \"$DEFAULT_CALENDAR\" whose summary is \"LLMCal Test\")" > /dev/null 2>&1
    else
        echo "   ❌ Calendar access failed"
        return 1
    fi
    
    echo "🎉 Configuration test passed!"
}
```

## 📋 Quick Setup Scripts

### One-Line Installer

```bash
# Quick setup for experienced users
curl -fsSL https://raw.githubusercontent.com/cafferychen777/LLMCal/main/scripts/quick-setup.sh | bash
```

### Interactive Setup

```bash
#!/bin/bash
# Interactive configuration script

main() {
    echo "🧙‍♂️ LLMCal Configuration Wizard"
    echo "================================"
    echo ""
    echo "Choose your setup method:"
    echo "1) Quick setup (5 minutes)"
    echo "2) Custom setup (15 minutes)"
    echo "3) Corporate setup (Advanced)"
    echo "4) Restore from backup"
    echo ""
    read -rp "Enter choice (1-4): " choice
    
    case $choice in
        1) quick_setup ;;
        2) custom_setup ;;
        3) corporate_setup ;;
        4) restore_backup ;;
        *) echo "Invalid choice. Exiting."; exit 1 ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

---

## 🔧 Maintenance

### Update Configuration

```bash
#!/bin/bash
# Update existing configuration

update_configuration() {
    echo "🔄 Configuration Update Wizard"
    echo "=============================="
    
    local config_file="$HOME/.llmcal/config"
    
    if [[ ! -f "$config_file" ]]; then
        echo "❌ No existing configuration found"
        echo "👉 Run initial setup first"
        return 1
    fi
    
    # Backup existing config
    cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ Current configuration backed up"
    
    # Show current settings
    echo ""
    echo "Current configuration:"
    echo "====================="
    grep -E '^[A-Z_]+=.*' "$config_file" | head -10
    echo ""
    
    # Ask what to update
    echo "What would you like to update?"
    echo "1) API settings"
    echo "2) Calendar settings"
    echo "3) Language settings"
    echo "4) Network settings"
    echo "5) All settings"
    echo ""
    read -rp "Enter choice (1-5): " update_choice
    
    case $update_choice in
        1) update_api_settings ;;
        2) update_calendar_settings ;;
        3) update_language_settings ;;
        4) update_network_settings ;;
        5) run_full_setup ;;
        *) echo "Invalid choice"; return 1 ;;
    esac
}
```

### Backup and Restore

```bash
#!/bin/bash
# Backup and restore configuration

backup_configuration() {
    local backup_dir="$HOME/.llmcal/backups"
    local backup_file="$backup_dir/config_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    mkdir -p "$backup_dir"
    
    tar -czf "$backup_file" -C "$HOME" .llmcal/config .llmcal/logs 2>/dev/null || true
    
    echo "✅ Configuration backed up to: $backup_file"
    
    # Keep only last 10 backups
    ls -t "$backup_dir"/config_backup_*.tar.gz | tail -n +11 | xargs rm -f 2>/dev/null || true
}

restore_configuration() {
    local backup_dir="$HOME/.llmcal/backups"
    
    echo "📁 Available backups:"
    ls -la "$backup_dir"/config_backup_*.tar.gz 2>/dev/null | nl
    
    echo ""
    read -rp "Enter backup number to restore: " backup_num
    
    local backup_file
    backup_file=$(ls -t "$backup_dir"/config_backup_*.tar.gz | sed -n "${backup_num}p")
    
    if [[ -f "$backup_file" ]]; then
        tar -xzf "$backup_file" -C "$HOME"
        echo "✅ Configuration restored from: $backup_file"
        validate_configuration
    else
        echo "❌ Backup file not found"
        return 1
    fi
}
```

---

## 🎯 Summary

After completing the configuration wizard, you should have:

1. ✅ **Working API connection** to Anthropic Claude
2. ✅ **Calendar permissions** properly set up
3. ✅ **Language and timezone** configured
4. ✅ **Performance settings** optimized
5. ✅ **Backup system** in place

Your LLMCal is now ready to use! Try selecting some text like "Meeting tomorrow at 2pm" and watch the magic happen.

---

**Need help?** Check out our [Troubleshooting Guide](TROUBLESHOOTING.md) or [Installation Guide](INSTALLATION.md).