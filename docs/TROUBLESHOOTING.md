# LLMCal Troubleshooting Guide

This comprehensive guide helps you diagnose and resolve common issues with LLMCal.

## 📋 Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Installation Issues](#installation-issues)
- [Configuration Problems](#configuration-problems)
- [API-Related Issues](#api-related-issues)
- [Calendar Integration Problems](#calendar-integration-problems)
- [PopClip Extension Issues](#popclip-extension-issues)
- [Performance Issues](#performance-issues)
- [Language and Localization](#language-and-localization)
- [Network and Connectivity](#network-and-connectivity)
- [Advanced Troubleshooting](#advanced-troubleshooting)
- [Getting Help](#getting-help)

## 🔍 Quick Diagnostics

### System Health Check

Run this diagnostic script to check your system:

```bash
#!/bin/bash
# LLMCal System Diagnostic Script

echo "=== LLMCal System Diagnostics ==="
echo "Date: $(date)"
echo

# Check macOS version
echo "macOS Version:"
sw_vers
echo

# Check PopClip installation
echo "PopClip Status:"
if pgrep -x "PopClip" > /dev/null; then
    echo "✅ PopClip is running"
    popclip_version=$(mdls -name kMDItemVersion /Applications/PopClip.app 2>/dev/null | cut -d'"' -f2)
    echo "PopClip Version: ${popclip_version:-Unknown}"
else
    echo "❌ PopClip is not running"
fi
echo

# Check LLMCal extension
echo "LLMCal Extension:"
extension_path="$HOME/Library/Application Support/PopClip/Extensions/LLMCal.popclipext"
if [[ -d "$extension_path" ]]; then
    echo "✅ Extension installed at: $extension_path"
    if [[ -f "$extension_path/calendar.sh" ]]; then
        echo "✅ Main script found"
        if [[ -x "$extension_path/calendar.sh" ]]; then
            echo "✅ Script is executable"
        else
            echo "❌ Script is not executable"
        fi
    else
        echo "❌ Main script missing"
    fi
else
    echo "❌ Extension not found"
fi
echo

# Check API key configuration
echo "API Configuration:"
if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    echo "✅ Environment API key set (length: ${#ANTHROPIC_API_KEY})"
else
    echo "ℹ️ No environment API key (check PopClip settings)"
fi
echo

# Check calendar permissions
echo "Calendar Permissions:"
calendar_access=$(sqlite3 "$HOME/Library/Application Support/com.apple.TCC/TCC.db" \
    "SELECT allowed FROM access WHERE service='kTCCServiceCalendar' AND client LIKE '%PopClip%'" 2>/dev/null || echo "unknown")
case "$calendar_access" in
    1) echo "✅ Calendar access granted" ;;
    0) echo "❌ Calendar access denied" ;;
    *) echo "ℹ️ Calendar access status unknown" ;;
esac
echo

# Check network connectivity
echo "Network Connectivity:"
if curl -s --connect-timeout 5 https://api.anthropic.com > /dev/null; then
    echo "✅ Can reach Anthropic API"
else
    echo "❌ Cannot reach Anthropic API"
fi

echo
echo "=== Diagnostic Complete ==="
```

### Quick Fixes Checklist

Before diving into detailed troubleshooting, try these quick fixes:

- [ ] **Restart PopClip**: Quit and reopen PopClip
- [ ] **Restart Calendar.app**: Force quit and reopen Calendar
- [ ] **Check API key**: Verify your Anthropic API key is correct
- [ ] **Grant permissions**: Ensure PopClip has calendar and accessibility access
- [ ] **Test with simple text**: Try "Meeting tomorrow at 2pm"
- [ ] **Check internet connection**: Ensure you can access the internet

## 🛠️ Installation Issues

### Issue: Extension Won't Install

**Symptoms**:
- Double-clicking `.popclipext.zip` doesn't open PopClip
- PopClip says "Failed to install extension"
- Extension doesn't appear in PopClip's extensions list

**Diagnosis**:
```bash
# Check if file is corrupted
unzip -t LLMCal.popclipext.zip

# Check PopClip is running
pgrep -x "PopClip"

# Check file associations
defaults read com.pilotmoon.popclip.mac
```

**Solutions**:

1. **Manual Installation**:
```bash
# Extract manually
unzip LLMCal.popclipext.zip

# Move to extensions directory
mv LLMCal.popclipext ~/Library/Application\ Support/PopClip/Extensions/

# Restart PopClip
killall PopClip && open -a PopClip
```

2. **Reset PopClip Extensions**:
```bash
# Backup existing extensions
cp -r ~/Library/Application\ Support/PopClip/Extensions/ ~/Desktop/PopClip-Backup/

# Remove all extensions
rm -rf ~/Library/Application\ Support/PopClip/Extensions/*

# Restart PopClip and reinstall
killall PopClip && open -a PopClip
```

3. **Check PopClip Version**:
```bash
# Get PopClip version
mdls -name kMDItemVersion /Applications/PopClip.app

# LLMCal requires PopClip 2022.5 or later
```

### Issue: Extension Appears but Doesn't Work

**Symptoms**:
- LLMCal appears in PopClip menu
- Clicking the icon does nothing or shows error
- No calendar events are created

**Diagnosis**:
```bash
# Check script permissions
ls -la ~/Library/Application\ Support/PopClip/Extensions/LLMCal.popclipext/calendar.sh

# Test script manually
export POPCLIP_TEXT="test meeting tomorrow at 2pm"
export POPCLIP_OPTION_ANTHROPIC_API_KEY="your_key"
./calendar.sh
```

**Solutions**:

1. **Fix Permissions**:
```bash
chmod +x ~/Library/Application\ Support/PopClip/Extensions/LLMCal.popclipext/calendar.sh
```

2. **Check Dependencies**:
```bash
# Ensure jq is available
which jq || brew install jq

# Check curl is working
curl --version
```

## ⚙️ Configuration Problems

### Issue: API Key Not Working

**Symptoms**:
- "Invalid API key" error message
- API requests failing consistently
- Authentication errors in logs

**Diagnosis**:
```bash
# Test API key manually
curl -H "Authorization: Bearer YOUR_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"model":"claude-3-sonnet-20240229","max_tokens":10,"messages":[{"role":"user","content":"test"}]}' \
     https://api.anthropic.com/v1/messages
```

**Solutions**:

1. **Verify API Key**:
   - Log in to [console.anthropic.com](https://console.anthropic.com)
   - Check if key is active and has credits
   - Regenerate key if necessary

2. **Check Key Format**:
   - API key should start with `sk-ant-`
   - Remove any extra spaces or characters
   - Ensure key is complete (not truncated)

3. **Update Configuration**:
```bash
# Clear PopClip settings
defaults delete com.pilotmoon.popclip.mac

# Restart PopClip and reconfigure
killall PopClip && open -a PopClip
```

### Issue: Language Not Detected Correctly

**Symptoms**:
- Interface shows wrong language
- Error messages in unexpected language
- Translation not working

**Diagnosis**:
```bash
# Check system language
defaults read .GlobalPreferences AppleLanguages

# Test language detection
./calendar.sh <<< "echo $(get_language)"
```

**Solutions**:

1. **Override Language**:
```bash
# Set environment variable
export LANGUAGE="en"  # or zh, es, fr, de, ja

# Or add to config file
echo "LANGUAGE=en" >> ~/.llmcal/config
```

2. **Update Translation File**:
```bash
# Check i18n.json exists and is valid
jq '.' ~/Library/Application\ Support/PopClip/Extensions/LLMCal.popclipext/i18n.json
```

## 🔌 API-Related Issues

### Issue: API Requests Timing Out

**Symptoms**:
- "Request timed out" errors
- Long delays before error messages
- Intermittent failures

**Diagnosis**:
```bash
# Test API response time
time curl -H "Authorization: Bearer YOUR_API_KEY" \
          -H "Content-Type: application/json" \
          -d '{"model":"claude-3-sonnet-20240229","max_tokens":10,"messages":[{"role":"user","content":"test"}]}' \
          https://api.anthropic.com/v1/messages
```

**Solutions**:

1. **Increase Timeout**:
```bash
# Add to ~/.llmcal/config
API_TIMEOUT=60  # Increase to 60 seconds
```

2. **Check Network**:
```bash
# Test basic connectivity
ping api.anthropic.com

# Test with verbose curl
curl -v https://api.anthropic.com/v1/messages
```

3. **Configure Proxy** (if needed):
```bash
# Add proxy settings to config
HTTP_PROXY=http://proxy.company.com:8080
HTTPS_PROXY=https://proxy.company.com:8080
```

### Issue: Rate Limiting

**Symptoms**:
- "Rate limit exceeded" errors
- HTTP 429 responses
- Temporary API blocks

**Solutions**:

1. **Implement Retry Logic**:
```bash
# Add to ~/.llmcal/config
MAX_RETRIES=5
RETRY_DELAY=2  # seconds
EXPONENTIAL_BACKOFF=true
```

2. **Reduce Request Frequency**:
- Wait between multiple requests
- Cache responses when possible
- Use batch processing for multiple events

3. **Check API Plan**:
- Verify your Anthropic plan limits
- Consider upgrading if needed
- Monitor usage in console

### Issue: Invalid JSON Response

**Symptoms**:
- "Failed to parse API response" errors
- Malformed event data
- JSON parsing errors

**Diagnosis**:
```bash
# Enable debug mode to see raw responses
export DEBUG_MODE=true
export LOG_LEVEL=debug

# Run with debug logging
./calendar.sh
```

**Solutions**:

1. **Improve API Prompt**:
- Make system prompt more specific
- Add format requirements
- Include examples in prompt

2. **Add Response Validation**:
```bash
# Validate JSON before parsing
validate_json_response() {
    local response="$1"
    
    if ! echo "$response" | jq empty 2>/dev/null; then
        log "ERROR" "Invalid JSON in response"
        return 1
    fi
    
    return 0
}
```

## 📅 Calendar Integration Problems

### Issue: Events Not Appearing in Calendar

**Symptoms**:
- Success message appears but no calendar event
- Events created in wrong calendar
- Events appear with incorrect data

**Diagnosis**:
```bash
# Test AppleScript directly
osascript -e 'tell application "Calendar" to get name of calendars'

# Check calendar permissions
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db \
  "SELECT service, client, allowed FROM access WHERE service='kTCCServiceCalendar'"
```

**Solutions**:

1. **Grant Calendar Permissions**:
   - System Settings → Privacy & Security → Calendar
   - Add PopClip to allowed applications
   - Restart both PopClip and Calendar.app

2. **Specify Target Calendar**:
```bash
# Add to ~/.llmcal/config
DEFAULT_CALENDAR="LLMCal Events"

# Create dedicated calendar
osascript -e 'tell application "Calendar" to make new calendar with properties {name:"LLMCal Events"}'
```

3. **Debug AppleScript**:
```bash
# Test event creation manually
osascript -e '
tell application "Calendar"
    set targetCalendar to calendar "Calendar"
    set newEvent to make new event at end of events of targetCalendar
    set summary of newEvent to "Test Event"
    set start date of newEvent to (current date)
    set end date of newEvent to (current date) + 3600
end tell'
```

### Issue: Timezone Problems

**Symptoms**:
- Events created in wrong timezone
- Time appears incorrectly in calendar
- Timezone conversion errors

**Solutions**:

1. **Set Default Timezone**:
```bash
# Add to ~/.llmcal/config
DEFAULT_TIMEZONE="America/New_York"

# Or detect automatically
AUTO_DETECT_TIMEZONE=true
```

2. **Debug Timezone Detection**:
```bash
# Check system timezone
sudo systemsetup -gettimezone

# Test timezone conversion
date -j -f "%Y-%m-%d %H:%M" "2025-01-25 14:00" +"%s"
```

### Issue: Recurring Events Not Working

**Symptoms**:
- Only single event created for recurring text
- Recurrence pattern ignored
- Incorrect repeat settings

**Solutions**:

1. **Improve Recurrence Parsing**:
- Enhance AI prompt for recurring events
- Add specific examples in system prompt
- Validate recurrence data before calendar creation

2. **Test Recurrence Manually**:
```bash
# Test AppleScript recurrence
osascript -e '
tell application "Calendar"
    set newEvent to make new event at end of events of calendar "Calendar"
    set summary of newEvent to "Recurring Test"
    set start date of newEvent to (current date)
    set recurrence of newEvent to "FREQ=WEEKLY"
end tell'
```

## 📱 PopClip Extension Issues

### Issue: PopClip Menu Not Appearing

**Symptoms**:
- No PopClip menu when selecting text
- PopClip icon not in menu bar
- Extension not responding to text selection

**Solutions**:

1. **Check PopClip Status**:
```bash
# Verify PopClip is running
pgrep -x "PopClip"

# If not running, start it
open -a PopClip
```

2. **Grant Accessibility Permissions**:
   - System Settings → Privacy & Security → Accessibility
   - Enable PopClip
   - Restart PopClip after granting permissions

3. **Reset PopClip Preferences**:
```bash
# Backup preferences
cp ~/Library/Preferences/com.pilotmoon.popclip.mac.plist ~/Desktop/

# Reset preferences
defaults delete com.pilotmoon.popclip.mac

# Restart PopClip
killall PopClip && open -a PopClip
```

### Issue: Extension Icon Not Visible

**Symptoms**:
- Other extensions appear but not LLMCal
- Calendar icon missing from menu
- Extension disabled or hidden

**Solutions**:

1. **Check Extension Status**:
   - Open PopClip preferences
   - Look for LLMCal in extensions list
   - Ensure it's enabled (not grayed out)

2. **Reinstall Extension**:
```bash
# Remove extension
rm -rf ~/Library/Application\ Support/PopClip/Extensions/LLMCal.popclipext

# Reinstall from zip file
open LLMCal.popclipext.zip
```

3. **Check Icon File**:
```bash
# Verify icon exists
ls -la ~/Library/Application\ Support/PopClip/Extensions/LLMCal.popclipext/calendar.png
```

## 🚀 Performance Issues

### Issue: Slow Response Times

**Symptoms**:
- Long delays before calendar event creation
- PopClip menu becomes unresponsive
- Timeout errors

**Diagnosis**:
```bash
# Time the operation
time (echo "test meeting" | ./calendar.sh)

# Check system resources
top -l 1 | grep -E "(CPU|Memory)"
```

**Solutions**:

1. **Optimize API Requests**:
```bash
# Reduce max tokens for faster response
MAX_TOKENS=512  # Instead of 1024

# Use faster model if available
MODEL_NAME="claude-3-haiku-20240307"
```

2. **Cache Responses**:
```bash
# Enable response caching
CACHE_RESPONSES=true
CACHE_TTL=3600  # 1 hour

# Cache directory
mkdir -p ~/.llmcal/cache
```

3. **Parallel Processing**:
```bash
# Process multiple events in parallel
process_events_parallel() {
    local events=("$@")
    
    for event in "${events[@]}"; do
        (
            export POPCLIP_TEXT="$event"
            ./calendar.sh
        ) &
    done
    
    wait  # Wait for all background processes
}
```

### Issue: High Memory Usage

**Symptoms**:
- System becomes slow during operation
- Memory warnings from macOS
- PopClip crashes or becomes unresponsive

**Solutions**:

1. **Optimize Shell Scripts**:
```bash
# Avoid large variables
# Instead of storing entire file in variable:
# content=$(cat large_file.json)

# Use streaming processing:
jq '.events[]' large_file.json | while read -r event; do
    process_event "$event"
done
```

2. **Clear Logs Regularly**:
```bash
# Add log rotation
rotate_logs() {
    local log_file="$HOME/.llmcal/logs/llmcal.log"
    
    if [[ -f "$log_file" && $(wc -c < "$log_file") -gt 10485760 ]]; then  # 10MB
        mv "$log_file" "${log_file}.old"
        touch "$log_file"
    fi
}
```

## 🌍 Language and Localization

### Issue: Missing Translations

**Symptoms**:
- Text appears in English instead of system language
- "Translation not found" errors
- Mixed languages in interface

**Solutions**:

1. **Update Translation File**:
```bash
# Check current translations
jq '.fr' ~/Library/Application\ Support/PopClip/Extensions/LLMCal.popclipext/i18n.json

# Add missing translations
jq '.fr.new_key = "Nouvelle traduction"' i18n.json > temp.json && mv temp.json i18n.json
```

2. **Test Translation System**:
```bash
# Test translation function
source lib/utils.sh
get_translation "success"
```

### Issue: Character Encoding Problems

**Symptoms**:
- Non-English characters appear as squares or question marks
- Calendar events with garbled text
- Encoding errors in logs

**Solutions**:

1. **Set Proper Encoding**:
```bash
# Ensure UTF-8 encoding
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Check file encoding
file -I ~/Library/Application\ Support/PopClip/Extensions/LLMCal.popclipext/i18n.json
```

2. **Fix JSON Encoding**:
```bash
# Convert to UTF-8 if needed
iconv -f ISO-8859-1 -t UTF-8 i18n.json > i18n_utf8.json
```

## 🌐 Network and Connectivity

### Issue: Corporate Firewall Blocking API

**Symptoms**:
- API requests fail in corporate environment
- Works at home but not at office
- SSL/TLS certificate errors

**Solutions**:

1. **Configure Proxy Settings**:
```bash
# Add to ~/.llmcal/config
HTTP_PROXY=http://proxy.company.com:8080
HTTPS_PROXY=https://proxy.company.com:8080
NO_PROXY=localhost,127.0.0.1,.company.com
```

2. **Test Proxy Configuration**:
```bash
# Test with curl
curl --proxy http://proxy.company.com:8080 https://api.anthropic.com

# Test SSL certificates
curl -v https://api.anthropic.com
```

3. **Alternative Solutions**:
- Request IT to whitelist `api.anthropic.com`
- Use VPN connection when available
- Work with IT to configure proxy authentication

### Issue: DNS Resolution Problems

**Symptoms**:
- "Could not resolve host" errors
- API calls fail intermittently
- DNS timeouts

**Solutions**:

1. **Test DNS Resolution**:
```bash
# Test DNS lookup
nslookup api.anthropic.com

# Try different DNS servers
nslookup api.anthropic.com 8.8.8.8
```

2. **Configure DNS**:
```bash
# Use Google DNS
sudo networksetup -setdnsservers Wi-Fi 8.8.8.8 8.8.4.4

# Flush DNS cache
sudo dscacheutil -flushcache
```

## 🔧 Advanced Troubleshooting

### Enable Debug Mode

For detailed troubleshooting, enable comprehensive debugging:

```bash
# Create debug configuration
cat > ~/.llmcal/debug.conf << EOF
# Debug Configuration
DEBUG_MODE=true
LOG_LEVEL=debug
VERBOSE_LOGGING=true
TRACE_EXECUTION=true

# Enhanced logging
LOG_API_REQUESTS=true
LOG_API_RESPONSES=true
LOG_CALENDAR_OPERATIONS=true

# Debug output locations
DEBUG_LOG_FILE="$HOME/.llmcal/logs/debug.log"
API_LOG_FILE="$HOME/.llmcal/logs/api.log"
CALENDAR_LOG_FILE="$HOME/.llmcal/logs/calendar.log"
EOF

# Load debug configuration
source ~/.llmcal/debug.conf
```

### Log Analysis Tools

#### Parse and Analyze Logs
```bash
#!/bin/bash
# scripts/analyze-debug-logs.sh

readonly LOG_DIR="$HOME/.llmcal/logs"

analyze_api_calls() {
    echo "=== API Call Analysis ==="
    
    # Count total API calls
    echo "Total API calls: $(grep -c "Making API request" "$LOG_DIR/debug.log")"
    
    # Count failures
    echo "Failed API calls: $(grep -c "API request failed" "$LOG_DIR/debug.log")"
    
    # Average response time
    grep "API response time:" "$LOG_DIR/debug.log" | \
    awk '{sum += $4; count++} END {print "Average response time:", sum/count "ms"}'
}

analyze_calendar_events() {
    echo "=== Calendar Event Analysis ==="
    
    # Count successful events
    echo "Successful events: $(grep -c "Event created successfully" "$LOG_DIR/debug.log")"
    
    # Count failures
    echo "Failed events: $(grep -c "Failed to create event" "$LOG_DIR/debug.log")"
    
    # Most common errors
    echo "Common errors:"
    grep "ERROR" "$LOG_DIR/debug.log" | \
    cut -d: -f3- | sort | uniq -c | sort -nr | head -5
}

analyze_performance() {
    echo "=== Performance Analysis ==="
    
    # Execution times
    grep "Total execution time:" "$LOG_DIR/debug.log" | \
    awk '{
        times[NR] = $4;
        sum += $4;
        if (NR == 1 || $4 < min) min = $4;
        if (NR == 1 || $4 > max) max = $4;
    }
    END {
        print "Average execution time:", sum/NR "ms";
        print "Min execution time:", min "ms";
        print "Max execution time:", max "ms";
    }'
}

# Run all analyses
analyze_api_calls
echo
analyze_calendar_events
echo
analyze_performance
```

### System Profiling

#### Resource Usage Monitor
```bash
#!/bin/bash
# scripts/monitor-resources.sh

monitor_llmcal_performance() {
    local duration=${1:-60}  # Default 60 seconds
    local interval=5
    
    echo "Monitoring LLMCal performance for ${duration} seconds..."
    echo "Timestamp,CPU%,Memory(MB),Network(KB/s)"
    
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    
    while [[ $(date +%s) -lt $end_time ]]; do
        local timestamp=$(date '+%H:%M:%S')
        
        # Get PopClip process stats
        local stats=$(ps -p $(pgrep PopClip) -o %cpu,rss,time | tail -1)
        local cpu=$(echo "$stats" | awk '{print $1}')
        local memory_kb=$(echo "$stats" | awk '{print $2}')
        local memory_mb=$((memory_kb / 1024))
        
        # Get network usage (simplified)
        local network=$(netstat -b | grep -i anthropic | wc -l)
        
        echo "$timestamp,$cpu,$memory_mb,$network"
        
        sleep $interval
    done
}

# Usage: ./monitor-resources.sh 120  # Monitor for 2 minutes
monitor_llmcal_performance "$@"
```

### Recovery Procedures

#### Complete System Reset
```bash
#!/bin/bash
# scripts/reset-llmcal.sh

reset_llmcal_completely() {
    echo "🔄 Performing complete LLMCal reset..."
    
    # Stop PopClip
    echo "Stopping PopClip..."
    killall PopClip 2>/dev/null
    
    # Backup current configuration
    echo "Backing up configuration..."
    mkdir -p ~/Desktop/LLMCal-Backup-$(date +%Y%m%d-%H%M%S)
    cp -r ~/.llmcal ~/Desktop/LLMCal-Backup-$(date +%Y%m%d-%H%M%S)/ 2>/dev/null
    
    # Remove all LLMCal files
    echo "Removing LLMCal files..."
    rm -rf ~/.llmcal
    rm -rf ~/Library/Application\ Support/PopClip/Extensions/LLMCal.popclipext
    rm -rf ~/Library/Logs/LLMCal
    
    # Reset PopClip preferences for LLMCal
    echo "Resetting PopClip preferences..."
    defaults delete com.pilotmoon.popclip.mac 2>/dev/null || true
    
    # Restart PopClip
    echo "Restarting PopClip..."
    open -a PopClip
    
    echo "✅ Reset complete. Please reinstall LLMCal extension."
}

# Confirm before reset
read -p "This will completely reset LLMCal. Continue? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    reset_llmcal_completely
else
    echo "Reset cancelled."
fi
```

## 🆘 Getting Help

### Before Seeking Help

1. **Check this troubleshooting guide** thoroughly
2. **Search existing issues** on [GitHub Issues](https://github.com/cafferychen777/LLMCal/issues)
3. **Run diagnostic script** and gather output
4. **Enable debug logging** and capture relevant logs
5. **Test with minimal configuration** to isolate the problem

### Creating a Good Support Request

When opening an issue or asking for help, include:

#### System Information
```bash
# Gather system information
echo "=== System Information ==="
echo "macOS Version: $(sw_vers -productVersion)"
echo "PopClip Version: $(mdls -name kMDItemVersion /Applications/PopClip.app 2>/dev/null | cut -d'"' -f2)"
echo "LLMCal Version: [Check release version]"
echo
```

#### Error Details
- **Exact error message** (copy and paste, don't paraphrase)
- **Steps to reproduce** the problem
- **Expected vs actual behavior**
- **Screenshots** if UI-related

#### Log Information
```bash
# Collect relevant logs
echo "=== Recent Log Entries ==="
tail -50 ~/.llmcal/logs/llmcal.log

echo "=== Debug Information ==="
# Include debug output if available
```

#### Configuration Details
- API key status (don't include the actual key)
- Language settings
- Custom configuration options
- Network environment (corporate, home, etc.)

### Support Channels

1. **GitHub Issues** - For bugs and feature requests
   - [https://github.com/cafferychen777/LLMCal/issues](https://github.com/cafferychen777/LLMCal/issues)

2. **GitHub Discussions** - For questions and general help
   - [https://github.com/cafferychen777/LLMCal/discussions](https://github.com/cafferychen777/LLMCal/discussions)

3. **Documentation** - Check all documentation first
   - [README.md](../README.md)
   - [API.md](API.md)
   - [INSTALLATION.md](INSTALLATION.md)
   - [DEVELOPMENT.md](DEVELOPMENT.md)

### Community Resources

- **Wiki** - Community-maintained troubleshooting tips
- **Discord/Slack** - Real-time community support (if available)
- **Stack Overflow** - Tag questions with `llmcal` and `popclip`

---

**Still having issues?** Don't hesitate to reach out. The LLMCal community is here to help!