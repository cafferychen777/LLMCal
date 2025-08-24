# LLMCal Installation Guide

This comprehensive guide will walk you through installing and configuring LLMCal on your macOS system.

## 📋 Table of Contents

- [System Requirements](#system-requirements)
- [Pre-Installation Checklist](#pre-installation-checklist)
- [Step-by-Step Installation](#step-by-step-installation)
- [Configuration](#configuration)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Uninstallation](#uninstallation)
- [Advanced Setup](#advanced-setup)

## 💻 System Requirements

### Minimum Requirements

| Component | Requirement | Notes |
|-----------|-------------|-------|
| **Operating System** | macOS 10.15 Catalina | Earlier versions not supported |
| **PopClip** | Version 2022.5+ | Available from [popclip.app](https://www.popclip.app) |
| **Memory** | 256 MB available RAM | For extension operation |
| **Storage** | 50 MB free space | For extension and logs |
| **Network** | Internet connection | For API communication |

### Recommended Requirements

| Component | Recommendation | Benefits |
|-----------|----------------|----------|
| **Operating System** | macOS 11.0 Big Sur+ | Better performance and compatibility |
| **PopClip** | Latest version | Latest features and bug fixes |
| **Memory** | 512 MB+ available RAM | Smoother operation |
| **Storage** | 100 MB+ free space | Room for logs and updates |
| **Network** | Stable broadband | Faster API responses |

### Dependencies

- **Anthropic API Account** - Required for AI processing
- **Calendar.app** - Built-in macOS calendar application
- **System Permissions** - Accessibility and calendar access

## ✅ Pre-Installation Checklist

Before installing LLMCal, ensure you have:

### 1. macOS System Check
```bash
# Check macOS version
sw_vers

# Example output:
# ProductName:    macOS
# ProductVersion: 11.6.1
# BuildVersion:   20G224
```

### 2. PopClip Installation
1. Visit [popclip.app](https://www.popclip.app)
2. Download PopClip for macOS
3. Install PopClip following the official instructions
4. Grant necessary system permissions

### 3. Anthropic API Setup
1. Go to [console.anthropic.com](https://console.anthropic.com)
2. Sign up or log in to your account
3. Navigate to API Keys section
4. Create a new API key
5. Copy and save your API key securely

### 4. System Permissions Check
Ensure these permissions are granted:
- **Accessibility** - For PopClip to function
- **Full Disk Access** - For calendar integration
- **Calendar** - For event creation

## 🚀 Step-by-Step Installation

### Method 1: Download and Install (Recommended)

#### Step 1: Download LLMCal
1. Go to [LLMCal Releases](https://github.com/cafferychen777/LLMCal/releases)
2. Download the latest `LLMCal.popclipext.zip`
3. Verify the download is complete and not corrupted

#### Step 2: Install Extension
1. **Double-click** the downloaded `LLMCal.popclipext.zip` file
2. The extension will automatically open in PopClip
3. Click **"Install Extension"** when prompted
4. The extension will appear in PopClip's extensions list

#### Step 3: Configure API Key
1. **Right-click** the PopClip icon in your menu bar
2. Select **"Extensions"** from the menu
3. Find **"LLMCal"** in the extensions list
4. Click the **settings icon** (gear) next to LLMCal
5. Enter your **Anthropic API key** in the settings field
6. Click **"Save"** to apply changes

### Method 2: Manual Installation

#### Step 1: Clone Repository
```bash
# Clone the repository
git clone https://github.com/cafferychen777/LLMCal.git
cd LLMCal
```

#### Step 2: Prepare Extension
```bash
# Create extension package
zip -r LLMCal.popclipext.zip LLMCal.popclipext/
```

#### Step 3: Install Extension
```bash
# Open with PopClip
open LLMCal.popclipext.zip
```

## ⚙️ Configuration

### Basic Configuration

#### 1. API Key Setup
The most critical configuration step:

```bash
# Method 1: Through PopClip GUI
# 1. PopClip menu → Extensions → LLMCal → Settings
# 2. Enter your Anthropic API key
# 3. Save settings

# Method 2: Environment Variable (Advanced)
export ANTHROPIC_API_KEY="your_api_key_here"
```

#### 2. Calendar Permissions
Ensure Calendar.app has necessary permissions:

1. **System Settings** → **Privacy & Security** → **Calendar**
2. Make sure **PopClip** and **Calendar** are enabled
3. If not listed, click **"+"** to add them

#### 3. Language Settings
LLMCal automatically detects your system language:

```bash
# Check current language
defaults read .GlobalPreferences AppleLanguages

# Supported languages: en, zh, es, fr, de, ja
```

### Advanced Configuration

#### Environment Configuration File
Create `~/.llmcal/config` for advanced settings:

```bash
# Create config directory
mkdir -p ~/.llmcal

# Create configuration file
cat > ~/.llmcal/config << EOF
# LLMCal Advanced Configuration

# API Configuration
ANTHROPIC_API_KEY=your_api_key_here
ANTHROPIC_MODEL=claude-3-sonnet-20240229

# Timezone Settings
DEFAULT_TIMEZONE=America/New_York
AUTO_DETECT_TIMEZONE=true

# Logging Configuration
LOG_LEVEL=info
LOG_FILE=~/.llmcal/logs/llmcal.log
MAX_LOG_SIZE=10M
LOG_RETENTION_DAYS=30

# Performance Settings
API_TIMEOUT=30
MAX_RETRIES=3
CACHE_RESPONSES=true
CACHE_TTL=3600

# Calendar Settings
DEFAULT_CALENDAR=Calendar
DEFAULT_REMINDER_MINUTES=15
AUTO_ADD_LOCATION=true

# Language Settings
LANGUAGE=auto
FALLBACK_LANGUAGE=en

# Debug Settings
DEBUG_MODE=false
VERBOSE_LOGGING=false
EOF
```

#### Network Configuration
For corporate networks or proxies:

```bash
# Add to ~/.llmcal/config
HTTP_PROXY=http://proxy.company.com:8080
HTTPS_PROXY=https://proxy.company.com:8080
NO_PROXY=localhost,127.0.0.1
```

## ✨ Verification

### Quick Test
1. **Select text** in any application: "Meeting tomorrow at 2pm"
2. **PopClip menu** should appear
3. **Click calendar icon** in PopClip menu
4. **Verify** event creation success message
5. **Check Calendar.app** for the new event

### Comprehensive Testing

#### Test 1: Basic Event Creation
```bash
# Test text examples
"Team standup tomorrow 9am for 30 minutes"
"Lunch with client next Friday at noon"
"Weekly review every Monday at 2pm"
```

#### Test 2: Complex Events
```bash
# Test with meeting links
"Product demo next Tuesday 3pm with client@example.com, 1 hour on Zoom https://zoom.us/j/123"

# Test recurring events
"Daily standup every weekday at 9am for 15 minutes"

# Test with locations
"Board meeting Thursday 10am in Conference Room A, remind me 30 minutes before"
```

#### Test 3: Language Support
Switch your system language and test with native language text:
- **Chinese**: "明天下午两点开会"
- **Spanish**: "Reunión mañana a las 2pm"
- **French**: "Réunion demain à 14h"

### Validation Commands

```bash
# Check PopClip extensions
ls ~/Library/Application\ Support/PopClip/Extensions/

# Check logs
tail -f ~/.llmcal/logs/llmcal.log

# Test API connectivity
curl -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
     -H "Content-Type: application/json" \
     https://api.anthropic.com/v1/messages
```

## 🔧 Troubleshooting

### Common Installation Issues

#### Issue 1: Extension Not Appearing
**Symptoms**: LLMCal doesn't show in PopClip menu

**Solutions**:
```bash
# 1. Restart PopClip
killall PopClip && open -a PopClip

# 2. Check extension directory
ls ~/Library/Application\ Support/PopClip/Extensions/

# 3. Reinstall extension
rm -rf ~/Library/Application\ Support/PopClip/Extensions/LLMCal.popclipext
# Then reinstall using Method 1
```

#### Issue 2: API Key Not Working
**Symptoms**: "Invalid API key" error

**Solutions**:
1. **Verify API key** at [console.anthropic.com](https://console.anthropic.com)
2. **Check for extra spaces** in the key
3. **Regenerate API key** if necessary
4. **Restart PopClip** after updating

#### Issue 3: Calendar Permissions
**Symptoms**: Events not appearing in calendar

**Solutions**:
1. **System Settings** → **Privacy & Security** → **Calendar**
2. **Enable PopClip** in the calendar apps list
3. **Restart Calendar.app**
4. **Try creating event manually** to test permissions

#### Issue 4: Network Connectivity
**Symptoms**: "API request failed" error

**Solutions**:
```bash
# Test internet connectivity
ping api.anthropic.com

# Test API endpoint
curl -I https://api.anthropic.com/v1/messages

# Check firewall settings
sudo pfctl -s all | grep anthropic
```

### Log Analysis

#### Enable Debug Logging
```bash
# Add to ~/.llmcal/config
DEBUG_MODE=true
LOG_LEVEL=debug
```

#### Common Log Patterns
```bash
# Successful operation
grep "Event created successfully" ~/.llmcal/logs/llmcal.log

# API errors
grep "API request failed" ~/.llmcal/logs/llmcal.log

# Permission errors
grep "Permission denied" ~/.llmcal/logs/llmcal.log

# Network errors
grep "Network error" ~/.llmcal/logs/llmcal.log
```

### Getting Help

If troubleshooting doesn't resolve your issue:

1. **Check logs** for specific error messages
2. **Search existing issues** on [GitHub Issues](https://github.com/cafferychen777/LLMCal/issues)
3. **Create a new issue** with:
   - macOS version
   - PopClip version
   - Error messages
   - Log excerpts
   - Steps to reproduce

## 🗑️ Uninstallation

### Complete Removal

#### Step 1: Remove Extension
```bash
# Remove from PopClip
rm -rf ~/Library/Application\ Support/PopClip/Extensions/LLMCal.popclipext
```

#### Step 2: Remove Configuration
```bash
# Remove configuration files
rm -rf ~/.llmcal/

# Remove environment variables (if set)
unset ANTHROPIC_API_KEY
```

#### Step 3: Clean Logs
```bash
# Remove log files
rm -rf ~/Library/Logs/LLMCal/
```

#### Step 4: Restart PopClip
```bash
# Restart PopClip to reflect changes
killall PopClip && open -a PopClip
```

### Partial Removal (Keep Configuration)
```bash
# Only remove extension, keep settings
rm -rf ~/Library/Application\ Support/PopClip/Extensions/LLMCal.popclipext
```

## 🔧 Advanced Setup

### Development Installation

For developers who want to modify LLMCal:

```bash
# Clone repository
git clone https://github.com/cafferychen777/LLMCal.git
cd LLMCal

# Create symlink for development
ln -s "$(pwd)/LLMCal.popclipext" \
      ~/Library/Application\ Support/PopClip/Extensions/

# Install demo dependencies
cd demo
npm install
npm run dev
```

### Enterprise Deployment

For organizations deploying LLMCal:

#### 1. Centralized Configuration
```bash
# Create organization config template
cat > /etc/llmcal/config.template << EOF
# Organization LLMCal Configuration
ANTHROPIC_API_KEY={{API_KEY}}
DEFAULT_TIMEZONE={{TIMEZONE}}
LOG_LEVEL=info
ENTERPRISE_MODE=true
EOF
```

#### 2. Automated Installation Script
```bash
#!/bin/bash
# deploy_llmcal.sh - Enterprise deployment script

set -euo pipefail

# Configuration
readonly EXTENSION_URL="https://github.com/cafferychen777/LLMCal/releases/latest/download/LLMCal.popclipext.zip"
readonly CONFIG_TEMPLATE="/etc/llmcal/config.template"

# Install extension
install_extension() {
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # Download extension
    curl -L "$EXTENSION_URL" -o "$temp_dir/extension.zip"
    
    # Install for user
    open "$temp_dir/extension.zip"
    
    echo "Extension installed successfully"
}

# Configure for user
configure_extension() {
    local api_key="$1"
    local timezone="${2:-America/New_York}"
    
    # Create user configuration
    mkdir -p ~/.llmcal
    sed "s/{{API_KEY}}/$api_key/g; s/{{TIMEZONE}}/$timezone/g" \
        "$CONFIG_TEMPLATE" > ~/.llmcal/config
    
    echo "Configuration completed"
}

# Main execution
main() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <api_key> [timezone]"
        exit 1
    fi
    
    install_extension
    configure_extension "$1" "${2:-}"
}

main "$@"
```

### Integration with Other Tools

#### Alfred Workflow Integration
```bash
# Create Alfred workflow that uses LLMCal
# workflow.sh
#!/bin/bash
export POPCLIP_TEXT="{query}"
export POPCLIP_OPTION_ANTHROPIC_API_KEY="$API_KEY"
./calendar.sh
```

#### Raycast Extension Integration
```typescript
// raycast-llmcal.tsx
import { Form, ActionPanel, Action, showToast, Toast } from "@raycast/api";
import { exec } from "child_process";

export default function Command() {
  const handleSubmit = (values: { text: string }) => {
    const env = {
      POPCLIP_TEXT: values.text,
      POPCLIP_OPTION_ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY,
    };
    
    exec("./calendar.sh", { env }, (error, stdout) => {
      if (error) {
        showToast(Toast.Style.Failure, "Error", error.message);
      } else {
        showToast(Toast.Style.Success, "Success", stdout);
      }
    });
  };

  return (
    <Form
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Create Event" onSubmit={handleSubmit} />
        </ActionPanel>
      }
    >
      <Form.TextArea id="text" title="Event Description" />
    </Form>
  );
}
```

## 🎯 Next Steps

After successful installation:

1. **Explore features** using the [Demo Application](https://cafferychen777.github.io/LLMCal/)
2. **Read the API documentation** in [docs/API.md](API.md)
3. **Learn development** with [docs/DEVELOPMENT.md](DEVELOPMENT.md)
4. **Join the community** on [GitHub Discussions](https://github.com/cafferychen777/LLMCal/discussions)

## 📚 Additional Resources

- **User Guide**: [README.md](../README.md)
- **API Reference**: [docs/API.md](API.md)
- **Development Guide**: [docs/DEVELOPMENT.md](DEVELOPMENT.md)
- **Troubleshooting**: [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Contributing**: [CONTRIBUTING.md](../CONTRIBUTING.md)

---

**Need help?** Open an issue on [GitHub Issues](https://github.com/cafferychen777/LLMCal/issues) or ask in [GitHub Discussions](https://github.com/cafferychen777/LLMCal/discussions).