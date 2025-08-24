# LLMCal Security Guide

This document outlines the security measures implemented in LLMCal and best practices for secure usage.

## 🔒 Security Features

### 1. Credential Management
- **No Hardcoded Credentials**: All API keys and sensitive data have been removed from source code
- **Environment Variable Support**: Secure loading from `.env` files and system environment variables
- **PopClip Integration**: Secure credential handling through PopClip's encrypted options system
- **Credential Validation**: Format validation and strength checking for API keys

### 2. Secure Logging
- **Log Sanitization**: Automatic removal of sensitive data from all log entries
- **API Request/Response Logging**: Safe logging with credential redaction
- **Structured Logging**: Multiple log levels (DEBUG, INFO, WARN, ERROR, CRITICAL)
- **Log Rotation**: Automatic log file rotation with size limits
- **Restricted Permissions**: Log files created with 600 permissions (owner read/write only)

### 3. Secure File Handling
- **Temporary Files**: Secure creation and cleanup of temporary files
- **File Permissions**: Automatic setting of restrictive permissions on sensitive files
- **Secure Cleanup**: Overwrite temporary files with random data before deletion

### 4. Configuration Validation
- **Format Validation**: Validation of API key formats and credential strength
- **Dependency Checking**: Verification of required credentials based on features used
- **Connectivity Testing**: Optional API connectivity validation

## 🚨 Security Improvements Made

### Before (Security Issues)
```json
// Config.json - INSECURE
{
  "zoom_account_id": {
    "default": "COoBTtIEQ-ynFT_zpUL6jw"  // ❌ Hardcoded credential
  }
}
```

```bash
# test_cases.sh - INSECURE
export POPCLIP_OPTION_ANTHROPIC_API_KEY="sk-ant-api03-37F5..." # ❌ Hardcoded API key
```

```bash
# calendar.sh - INSECURE
log "API 响应: $RESPONSE"  # ❌ Logs sensitive API responses
```

### After (Secure)
```json
// Config.json - SECURE
{
  "zoom_account_id": {
    "description": "Enter your Zoom Account ID",
    "secure": true  // ✅ No default values, marked as secure
  }
}
```

```bash
# test_cases.sh - SECURE
if [ -z "$ANTHROPIC_API_KEY" ]; then
    log "Error: Missing ANTHROPIC_API_KEY environment variable"  # ✅ Environment variable required
    exit 1
fi
```

```bash
# calendar.sh - SECURE
log_api_response "$http_code" "" "$(sanitize_json_response "$response")"  # ✅ Sanitized logging
```

## 🛠 Setup Instructions

### Option 1: Automated Setup (Recommended)
```bash
# Run the security setup wizard
./setup_security.sh
```

### Option 2: Manual Setup

1. **Create Environment File**
   ```bash
   cp .env.example .env
   chmod 600 .env
   ```

2. **Configure API Keys**
   ```bash
   # Edit .env file
   nano .env
   
   # Add your credentials:
   ANTHROPIC_API_KEY=your_actual_api_key_here
   ZOOM_ACCOUNT_ID=your_zoom_account_id
   ZOOM_CLIENT_ID=your_zoom_client_id
   ZOOM_CLIENT_SECRET=your_zoom_client_secret
   ```

3. **Validate Configuration**
   ```bash
   source LLMCal.popclipext/lib/config_validator.sh
   run_validation true
   ```

## 🔐 Environment Variables

### Required
- `ANTHROPIC_API_KEY`: Your Anthropic Claude API key

### Optional (Zoom Integration)
- `ZOOM_ACCOUNT_ID`: Your Zoom account ID
- `ZOOM_CLIENT_ID`: Your Zoom app client ID  
- `ZOOM_CLIENT_SECRET`: Your Zoom app client secret
- `ZOOM_EMAIL`: Email associated with Zoom account
- `ZOOM_NAME`: Display name for Zoom meetings

### Logging Configuration
- `LOG_LEVEL`: Logging level (DEBUG, INFO, WARN, ERROR, CRITICAL) - default: INFO
- `MAX_LOG_SIZE`: Maximum log file size in bytes - default: 10MB
- `MAX_LOG_FILES`: Number of rotated log files to keep - default: 5

## 🚫 Security Best Practices

### DO ✅
- Use environment variables or PopClip secure options for credentials
- Set restrictive file permissions (600) on sensitive files
- Regularly rotate API keys
- Monitor log files for security events
- Keep the extension updated
- Use the provided security validation tools

### DON'T ❌
- Hardcode credentials in source files
- Commit `.env` files to version control
- Share log files containing sensitive data
- Use weak or predictable API keys
- Run the extension with elevated privileges unnecessarily

## 📝 Security Logging

The security logging system automatically:
- Redacts API keys, tokens, and credentials from all log entries
- Sanitizes email addresses (partial redaction)
- Removes long alphanumeric strings that might be credentials
- Logs security events with appropriate severity levels

### Log Levels
- **DEBUG**: Detailed information for troubleshooting
- **INFO**: General information about operations
- **WARN**: Warning conditions that should be noted
- **ERROR**: Error conditions that need attention
- **CRITICAL**: Critical issues that require immediate action

## 🔍 Security Validation

### Automatic Checks
The system automatically validates:
- API key format correctness
- Credential strength and complexity
- Required vs optional credential dependencies
- File permission security
- Configuration completeness

### Manual Security Check
```bash
# Run comprehensive security check
source LLMCal.popclipext/lib/config_validator.sh
run_validation true
```

## 🚨 Incident Response

If you suspect a security issue:

1. **Immediate Actions**
   - Rotate all affected API keys immediately
   - Check log files for suspicious activity
   - Review recent extension usage

2. **Investigation**
   - Check git history for accidentally committed credentials
   - Scan all files for hardcoded secrets
   - Review access logs from API providers

3. **Prevention**
   - Update to latest version with security fixes
   - Re-run security validation
   - Review and update security practices

## 🔄 Security Updates

### Version History
- **v2.0**: Comprehensive security overhaul
  - Removed all hardcoded credentials
  - Implemented secure logging with sanitization
  - Added configuration validation
  - Added secure file handling
  - Created security utilities library

### Keeping Updated
- Monitor for security updates
- Review CHANGELOG.md for security-related changes
- Re-run security validation after updates

## 🆘 Security Support

For security-related questions or to report security issues:
1. Check this documentation first
2. Run the built-in security validation tools
3. Review log files for error messages
4. Open an issue in the project repository (for non-sensitive issues)

## 📋 Security Checklist

Before using LLMCal in production:

- [ ] Removed all hardcoded credentials from source code
- [ ] Created `.env` file with proper permissions (600)
- [ ] Configured all required API keys
- [ ] Ran security validation successfully
- [ ] Verified logging sanitization is working
- [ ] Added `.env` to `.gitignore`
- [ ] Set up log rotation and monitoring
- [ ] Reviewed file permissions on all extension files
- [ ] Tested API connectivity with validation tools
- [ ] Documented credential rotation procedures

---

**Note**: Security is an ongoing process. Regularly review and update your security practices, credentials, and keep the extension updated with the latest security improvements.