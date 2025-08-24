# LLMCal API Documentation

This document provides comprehensive API documentation for the LLMCal PopClip extension and its components.

## 📋 Table of Contents

- [Overview](#overview)
- [PopClip Extension API](#popclip-extension-api)
- [Calendar Script API](#calendar-script-api)
- [Internationalization API](#internationalization-api)
- [Configuration API](#configuration-api)
- [Error Handling](#error-handling)
- [Examples](#examples)
- [Integration Guide](#integration-guide)

## 🔍 Overview

LLMCal consists of several interconnected components:

1. **PopClip Extension** - User interface integration
2. **Calendar Script** - Core processing logic
3. **AI Integration** - Anthropic Claude Sonnet 4 API communication
4. **Calendar Integration** - Apple Calendar event creation
5. **Internationalization** - Multi-language support

### Architecture Diagram

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User Input    │    │  PopClip Ext    │    │  Calendar.sh    │
│  (Text Select)  │───▶│   Interface     │───▶│   Core Logic    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                       ┌─────────────────┐            │
                       │  Anthropic API  │◀───────────┤
                       │ (Claude Sonnet 4)│            │
                       └─────────────────┘            │
                                                       │
                       ┌─────────────────┐            │
                       │ Apple Calendar  │◀───────────┘
                       │    (Events)     │
                       └─────────────────┘
```

## 🔌 PopClip Extension API

### Extension Manifest (Config.json)

The PopClip extension is configured through `Config.json`:

```json
{
  "identifier": "com.llmcal.popclip",
  "name": "LLMCal",
  "description": "AI-powered calendar event creator",
  "popclipVersion": 2022,
  "actions": [
    {
      "title": "Add to Calendar",
      "icon": "calendar.png",
      "shell": "calendar.sh",
      "requirements": ["text"],
      "options": [
        {
          "identifier": "anthropicApiKey",
          "label": "Anthropic API Key",
          "type": "string",
          "description": "Your Anthropic API key for Claude Sonnet 4"
        }
      ]
    }
  ]
}
```

### Extension Properties

| Property | Type | Description |
|----------|------|-------------|
| `identifier` | string | Unique extension identifier |
| `name` | string | Display name in PopClip |
| `description` | string | Extension description |
| `popclipVersion` | number | Required PopClip version |
| `actions` | array | Available actions |

### Action Properties

| Property | Type | Description |
|----------|------|-------------|
| `title` | string | Action display name |
| `icon` | string | Icon file name |
| `shell` | string | Script to execute |
| `requirements` | array | Required conditions (`text`, `paste`, etc.) |
| `options` | array | User configuration options |

## 📜 Calendar Script API

### Main Entry Point

**File**: `calendar.sh`

**Purpose**: Main processing script that handles text input and creates calendar events.

#### Environment Variables

| Variable | Type | Description | Required |
|----------|------|-------------|----------|
| `POPCLIP_TEXT` | string | Selected text input | Yes |
| `POPCLIP_OPTION_ANTHROPIC_API_KEY` | string | Anthropic API key | Yes |
| `POPCLIP_BUNDLE_PATH` | string | Extension bundle path | Yes |

#### Return Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 0 | Success | Event created successfully |
| 1 | Invalid Input | No text selected or invalid input |
| 2 | API Error | Anthropic API request failed |
| 3 | Calendar Error | Failed to create calendar event |
| 4 | Configuration Error | Missing or invalid configuration |

### Core Functions

#### `log(message)`
**Purpose**: Write log entry with timestamp

**Parameters**:
- `message` (string): Message to log

**Example**:
```bash
log "Starting event creation process"
```

#### `get_language()`
**Purpose**: Detect system language

**Returns**: Language code (`en`, `zh`, `es`, `fr`, `de`, `ja`)

**Example**:
```bash
language=$(get_language)
echo "Detected language: $language"
```

#### `get_translation(key)`
**Purpose**: Get localized text for a key

**Parameters**:
- `key` (string): Translation key

**Returns**: Localized text string

**Example**:
```bash
success_msg=$(get_translation "success")
echo "$success_msg"
```

#### `call_anthropic_api(text)`
**Purpose**: Send text to Anthropic API for processing

**Parameters**:
- `text` (string): Input text to process

**Returns**: JSON response from API

**Example**:
```bash
response=$(call_anthropic_api "$POPCLIP_TEXT")
```

#### `parse_ai_response(response)`
**Purpose**: Extract event details from AI response

**Parameters**:
- `response` (string): JSON response from API

**Returns**: Parsed event data

**Example**:
```bash
event_data=$(parse_ai_response "$api_response")
```

#### `create_calendar_event(event_data)`
**Purpose**: Create event in Apple Calendar

**Parameters**:
- `event_data` (string): JSON event data

**Returns**: Success/failure status

**Example**:
```bash
create_calendar_event "$parsed_data"
```

### Event Data Format

The event data follows this JSON schema:

```json
{
  "title": "string",
  "startDate": "YYYY-MM-DD",
  "startTime": "HH:MM",
  "endDate": "YYYY-MM-DD", 
  "endTime": "HH:MM",
  "location": "string",
  "description": "string",
  "url": "string",
  "attendees": ["email1@example.com", "email2@example.com"],
  "reminders": [
    {
      "type": "alert",
      "minutes": 15
    }
  ],
  "recurrence": {
    "frequency": "daily|weekly|monthly|yearly",
    "interval": 1,
    "endDate": "YYYY-MM-DD"
  }
}
```

### Event Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `title` | string | Yes | Event title |
| `startDate` | string | Yes | Start date (ISO format) |
| `startTime` | string | Yes | Start time (24h format) |
| `endDate` | string | No | End date (defaults to start date) |
| `endTime` | string | No | End time (calculated from duration) |
| `location` | string | No | Event location |
| `description` | string | No | Event description |
| `url` | string | No | Meeting URL or related link |
| `attendees` | array | No | List of attendee email addresses |
| `reminders` | array | No | Reminder configurations |
| `recurrence` | object | No | Recurring event settings |

## 🌐 Internationalization API

### Translation File Format

**File**: `i18n.json`

```json
{
  "en": {
    "success": "Event successfully added to calendar",
    "error": "Failed to add event to calendar",
    "api_error": "API request failed",
    "invalid_key": "Invalid API key",
    "no_text": "No text selected",
    "processing": "Processing your request..."
  },
  "zh": {
    "success": "已成功添加事件到日历",
    "error": "添加事件到日历失败",
    "api_error": "API 请求失败",
    "invalid_key": "无效的 API 密钥",
    "no_text": "未选择文本",
    "processing": "正在处理您的请求..."
  }
}
```

### Supported Languages

| Language | Code | Status |
|----------|------|--------|
| English | `en` | ✅ Complete |
| Chinese | `zh` | ✅ Complete |
| Spanish | `es` | ✅ Complete |
| French | `fr` | 🔄 In Progress |
| German | `de` | 🔄 In Progress |
| Japanese | `ja` | 🔄 In Progress |

### Translation Keys

| Key | Purpose | Example |
|-----|---------|---------|
| `success` | Event creation success | "Event added successfully" |
| `error` | Generic error message | "Failed to add event" |
| `api_error` | API communication error | "API request failed" |
| `invalid_key` | Invalid API key error | "Invalid API key" |
| `no_text` | No text selected | "No text selected" |
| `processing` | Processing indicator | "Processing your request..." |

## ⚙️ Configuration API

### Environment Configuration

LLMCal can be configured through environment variables or configuration files.

#### Environment Variables

```bash
# Required
export ANTHROPIC_API_KEY="your_api_key_here"

# Optional
export DEFAULT_TIMEZONE="America/New_York"
export LOG_LEVEL="info"  # debug, info, warn, error
export LOG_FILE="/tmp/llmcal.log"
export LANGUAGE="en"     # Override system language
```

#### Configuration File

**Location**: `~/.llmcal/config`

```bash
# LLMCal Configuration
ANTHROPIC_API_KEY=your_api_key_here
DEFAULT_TIMEZONE=America/New_York
LOG_LEVEL=info
LOG_FILE=/tmp/llmcal.log
LANGUAGE=en

# Advanced Settings
CALENDAR_NAME="LLMCal Events"
MAX_RETRIES=3
TIMEOUT_SECONDS=30
```

### Configuration Loading Order

1. PopClip extension options (highest priority)
2. Environment variables
3. Configuration file `~/.llmcal/config`
4. Default values (lowest priority)

## 🚨 Error Handling

### Error Response Format

All errors return JSON in this format:

```json
{
  "error": true,
  "code": "ERROR_CODE",
  "message": "Human readable error message",
  "details": {
    "timestamp": "2025-01-24T10:30:00Z",
    "request_id": "req_123456",
    "additional_info": "Extra context"
  }
}
```

### Error Codes

| Code | HTTP Status | Description | Recovery |
|------|-------------|-------------|----------|
| `INVALID_INPUT` | 400 | No text selected or invalid input | Select text and try again |
| `MISSING_API_KEY` | 401 | API key not provided | Configure API key in settings |
| `INVALID_API_KEY` | 401 | API key is invalid or expired | Update API key in settings |
| `API_RATE_LIMIT` | 429 | Too many API requests | Wait and retry |
| `API_TIMEOUT` | 408 | API request timed out | Check network and retry |
| `CALENDAR_PERMISSION` | 403 | No calendar access permission | Grant calendar permissions |
| `CALENDAR_ERROR` | 500 | Failed to create calendar event | Check calendar app and retry |
| `PARSING_ERROR` | 422 | Failed to parse AI response | Try rephrasing the input |
| `NETWORK_ERROR` | 503 | Network connectivity issue | Check internet connection |

### Error Handling Best Practices

1. **Always check return codes** in scripts
2. **Provide meaningful error messages** to users
3. **Log errors** for debugging purposes
4. **Implement retry logic** for transient failures
5. **Gracefully degrade** when possible

## 💡 Examples

### Basic Event Creation

```bash
#!/bin/bash

# Input text
text="Team meeting tomorrow at 2pm for 1 hour"

# Set required environment variables
export POPCLIP_TEXT="$text"
export POPCLIP_OPTION_ANTHROPIC_API_KEY="your_api_key"
export POPCLIP_BUNDLE_PATH="/path/to/extension"

# Execute calendar script
./calendar.sh

# Check result
if [ $? -eq 0 ]; then
    echo "Event created successfully!"
else
    echo "Failed to create event"
fi
```

### Custom API Integration

```python
import subprocess
import json
import os

def create_calendar_event(text, api_key):
    """Create calendar event using LLMCal."""
    
    # Set environment
    env = os.environ.copy()
    env.update({
        'POPCLIP_TEXT': text,
        'POPCLIP_OPTION_ANTHROPIC_API_KEY': api_key,
        'POPCLIP_BUNDLE_PATH': '/path/to/LLMCal.popclipext'
    })
    
    # Execute script
    result = subprocess.run(
        ['./calendar.sh'],
        cwd='/path/to/LLMCal.popclipext',
        env=env,
        capture_output=True,
        text=True
    )
    
    return {
        'success': result.returncode == 0,
        'output': result.stdout,
        'error': result.stderr
    }

# Usage
result = create_calendar_event(
    "Weekly standup every Monday at 9am",
    "your_anthropic_api_key"
)

if result['success']:
    print("Event created:", result['output'])
else:
    print("Error:", result['error'])
```

### Batch Event Creation

```bash
#!/bin/bash

# Batch create events from file
events_file="events.txt"

while IFS= read -r event_text; do
    echo "Creating event: $event_text"
    
    export POPCLIP_TEXT="$event_text"
    ./calendar.sh
    
    if [ $? -eq 0 ]; then
        echo "✅ Created successfully"
    else
        echo "❌ Failed to create"
    fi
    
    # Wait between requests to respect rate limits
    sleep 2
done < "$events_file"
```

### Testing API Integration

```bash
#!/bin/bash

# Test script for API integration
test_api_integration() {
    local test_cases=(
        "Meeting tomorrow at 2pm"
        "Weekly standup every Monday at 9am"
        "Lunch with client next Friday at noon"
        "Team retrospective last Friday of month at 3pm"
    )
    
    for test_case in "${test_cases[@]}"; do
        echo "Testing: $test_case"
        
        export POPCLIP_TEXT="$test_case"
        result=$(./calendar.sh 2>&1)
        
        if [ $? -eq 0 ]; then
            echo "✅ PASS: $result"
        else
            echo "❌ FAIL: $result"
        fi
    done
}

test_api_integration
```

## 🔗 Integration Guide

### Web Application Integration

```javascript
class LLMCalIntegration {
    constructor(extensionPath) {
        this.extensionPath = extensionPath;
    }
    
    async createEvent(text, apiKey) {
        const { spawn } = require('child_process');
        
        return new Promise((resolve, reject) => {
            const process = spawn('./calendar.sh', [], {
                cwd: this.extensionPath,
                env: {
                    ...process.env,
                    POPCLIP_TEXT: text,
                    POPCLIP_OPTION_ANTHROPIC_API_KEY: apiKey,
                    POPCLIP_BUNDLE_PATH: this.extensionPath
                }
            });
            
            let output = '';
            let error = '';
            
            process.stdout.on('data', (data) => {
                output += data.toString();
            });
            
            process.stderr.on('data', (data) => {
                error += data.toString();
            });
            
            process.on('close', (code) => {
                if (code === 0) {
                    resolve({ success: true, output });
                } else {
                    reject({ success: false, error, code });
                }
            });
        });
    }
}

// Usage
const llmcal = new LLMCalIntegration('/path/to/extension');

llmcal.createEvent(
    'Team meeting tomorrow at 2pm',
    'your_api_key'
).then(result => {
    console.log('Success:', result);
}).catch(error => {
    console.error('Error:', error);
});
```

### Mobile App Integration (iOS/macOS)

```swift
import Foundation

class LLMCalIntegration {
    let extensionPath: String
    
    init(extensionPath: String) {
        self.extensionPath = extensionPath
    }
    
    func createEvent(text: String, apiKey: String, completion: @escaping (Result<String, Error>) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "\(extensionPath)/calendar.sh")
        
        process.environment = [
            "POPCLIP_TEXT": text,
            "POPCLIP_OPTION_ANTHROPIC_API_KEY": apiKey,
            "POPCLIP_BUNDLE_PATH": extensionPath
        ]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            
            if process.terminationStatus == 0 {
                completion(.success(output))
            } else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let error = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                completion(.failure(NSError(domain: "LLMCal", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: error])))
            }
        } catch {
            completion(.failure(error))
        }
    }
}

// Usage
let llmcal = LLMCalIntegration(extensionPath: "/path/to/extension")

llmcal.createEvent(text: "Team meeting tomorrow at 2pm", apiKey: "your_api_key") { result in
    switch result {
    case .success(let output):
        print("Success: \(output)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

## 📊 Performance Considerations

### Optimization Tips

1. **Cache API responses** when possible
2. **Batch multiple requests** to reduce API calls
3. **Use connection pooling** for HTTP requests
4. **Implement request deduplication**
5. **Set appropriate timeouts**

### Rate Limiting

- **Anthropic API**: Respect rate limits (varies by plan)
- **Calendar Operations**: Batch when creating multiple events
- **Logging**: Use log levels to control verbosity

### Memory Usage

- **Shell Scripts**: Minimize variable retention
- **JSON Processing**: Use streaming parsers for large responses
- **Temporary Files**: Clean up after processing

---

For more information, see:
- [Installation Guide](INSTALLATION.md)
- [Development Guide](DEVELOPMENT.md)  
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Contributing Guide](../CONTRIBUTING.md)