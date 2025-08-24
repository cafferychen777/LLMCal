# LLMCal Development Guide

This guide provides comprehensive information for developers working on or contributing to LLMCal.

## 📋 Table of Contents

- [Development Environment Setup](#development-environment-setup)
- [Project Architecture](#project-architecture)
- [Development Workflow](#development-workflow)
- [Code Structure](#code-structure)
- [API Integration](#api-integration)
- [Testing](#testing)
- [Debugging](#debugging)
- [Performance Optimization](#performance-optimization)
- [Deployment](#deployment)
- [Best Practices](#best-practices)

## 🛠️ Development Environment Setup

### Prerequisites

#### System Requirements
- **macOS 10.15+** (for full development and testing)
- **Xcode Command Line Tools** (`xcode-select --install`)
- **Homebrew** (package manager)
- **Git** (version control)

#### Development Tools
```bash
# Install essential tools
brew install node npm jq shellcheck
brew install --cask popclip

# Install development utilities
npm install -g typescript eslint prettier
pip3 install anthropic

# Install testing tools
npm install -g jest @types/jest
brew install bats-core
```

### Project Setup

#### 1. Clone and Setup
```bash
# Clone the repository
git clone https://github.com/cafferychen777/LLMCal.git
cd LLMCal

# Install dependencies
npm install

# Install demo dependencies
cd demo
npm install
cd ..

# Setup git hooks
cp scripts/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

#### 2. Environment Configuration
```bash
# Create development environment file
cat > .env.development << EOF
# Development Configuration
ANTHROPIC_API_KEY=your_development_api_key
DEFAULT_TIMEZONE=America/New_York
LOG_LEVEL=debug
DEBUG_MODE=true

# Development URLs
API_BASE_URL=https://api.anthropic.com
DEMO_URL=http://localhost:3000

# Testing Configuration
TEST_API_KEY=test_api_key
MOCK_API_RESPONSES=false
EOF

# Load environment
source .env.development
```

#### 3. Development Database
```bash
# Create development logs directory
mkdir -p ~/.llmcal/logs/development
mkdir -p ~/.llmcal/test-data

# Initialize test data
cat > ~/.llmcal/test-data/events.json << EOF
[
  {
    "input": "Team meeting tomorrow at 2pm",
    "expected": {
      "title": "Team meeting",
      "startTime": "14:00",
      "duration": 60
    }
  },
  {
    "input": "Weekly standup every Monday 9am for 30 min",
    "expected": {
      "title": "Weekly standup",
      "recurrence": "weekly",
      "duration": 30
    }
  }
]
EOF
```

### IDE Configuration

#### Visual Studio Code Setup
```json
// .vscode/settings.json
{
  "typescript.preferences.importModuleSpecifier": "relative",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "files.associations": {
    "*.sh": "shellscript"
  },
  "shellcheck.enable": true,
  "shellformat.useEditorConfig": true
}
```

```json
// .vscode/extensions.json
{
  "recommendations": [
    "ms-vscode.vscode-typescript-next",
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "timonwong.shellcheck",
    "foxundermoon.shell-format",
    "bradlc.vscode-tailwindcss"
  ]
}
```

## 🏗️ Project Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    LLMCal Architecture                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │   PopClip   │───▶│    Shell    │───▶│ Anthropic   │    │
│  │ Extension   │    │   Scripts   │    │     API     │    │
│  └─────────────┘    └─────────────┘    └─────────────┘    │
│         │                   │                   │          │
│         │                   │                   │          │
│         ▼                   ▼                   ▼          │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │    User     │    │   Apple     │    │    Demo     │    │
│  │ Interface   │    │  Calendar   │    │    App      │    │
│  └─────────────┘    └─────────────┘    └─────────────┘    │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                     Data Flow                               │
│                                                             │
│  User Text → PopClip → Shell → API → Parser → Calendar     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Component Architecture

#### 1. PopClip Extension Layer
```
LLMCal.popclipext/
├── Config.json          # Extension manifest
├── calendar.sh          # Main script entry point
├── i18n.json           # Internationalization data
├── assets/             # Icons and resources
│   ├── calendar.png    # Extension icon
│   └── logo.png       # Logo assets
└── lib/               # Utility libraries
    ├── api.sh         # API communication
    ├── parser.sh      # Response parsing
    ├── calendar.sh    # Calendar integration
    └── utils.sh       # Common utilities
```

#### 2. Demo Application Layer
```
demo/
├── src/
│   ├── components/     # React components
│   │   ├── Calendar.tsx
│   │   ├── EventForm.tsx
│   │   └── Animation.tsx
│   ├── utils/         # Utility functions
│   │   ├── api.ts     # API helpers
│   │   └── parser.ts  # Text parsing
│   ├── hooks/         # Custom React hooks
│   │   ├── useAnimation.ts
│   │   └── useCalendar.ts
│   └── styles/        # CSS and styling
├── public/            # Static assets
└── dist/             # Built application
```

#### 3. Documentation Layer
```
docs/
├── API.md            # API documentation
├── DEVELOPMENT.md    # This file
├── INSTALLATION.md   # Installation guide
└── TROUBLESHOOTING.md # Troubleshooting guide
```

### Data Models

#### Event Model
```typescript
interface CalendarEvent {
  title: string;
  startDate: string;        // ISO date format
  startTime: string;        // 24-hour format
  endDate?: string;         // Optional, defaults to startDate
  endTime?: string;         // Calculated from duration
  duration?: number;        // Minutes
  location?: string;        // Physical or virtual location
  description?: string;     // Event description
  url?: string;             // Meeting link or related URL
  attendees?: string[];     // Email addresses
  reminders?: Reminder[];   // Alert configurations
  recurrence?: Recurrence;  // Recurring pattern
  timezone?: string;        // Timezone identifier
  allDay?: boolean;         // All-day event flag
}
```

#### Reminder Model
```typescript
interface Reminder {
  type: 'alert' | 'email' | 'popup';
  minutes: number;          // Minutes before event
  message?: string;         // Custom reminder message
}
```

#### Recurrence Model
```typescript
interface Recurrence {
  frequency: 'daily' | 'weekly' | 'monthly' | 'yearly';
  interval: number;         // Every N frequencies
  daysOfWeek?: number[];    // For weekly (0=Sunday, 6=Saturday)
  dayOfMonth?: number;      // For monthly
  monthOfYear?: number;     // For yearly
  endDate?: string;         // When recurrence stops
  count?: number;          // Number of occurrences
}
```

## 🔄 Development Workflow

### Branch Strategy

#### Main Branches
- **`main`** - Production-ready code
- **`develop`** - Integration branch for features
- **`release/x.y.z`** - Release preparation branches

#### Feature Branches
```bash
# Feature development
git checkout -b feature/add-google-calendar-support develop

# Bug fixes
git checkout -b fix/timezone-parsing-error develop

# Documentation
git checkout -b docs/update-api-documentation develop

# Hotfixes (from main)
git checkout -b hotfix/security-vulnerability main
```

### Development Process

#### 1. Feature Development Cycle
```bash
# Start new feature
git checkout develop
git pull origin develop
git checkout -b feature/new-feature

# Development work
# ... code, test, commit ...

# Prepare for merge
git checkout develop
git pull origin develop
git checkout feature/new-feature
git rebase develop

# Create pull request
git push origin feature/new-feature
# Open PR on GitHub
```

#### 2. Code Review Process
1. **Automated Checks** - CI/CD pipeline runs tests
2. **Peer Review** - At least one developer reviews
3. **Documentation Review** - Ensure docs are updated
4. **Integration Testing** - Test in development environment
5. **Approval and Merge** - Merge to develop branch

#### 3. Release Process
```bash
# Create release branch
git checkout develop
git pull origin develop
git checkout -b release/1.2.0

# Update version numbers
./scripts/update-version.sh 1.2.0

# Run full test suite
npm test
./scripts/test-all.sh

# Create release
git checkout main
git merge release/1.2.0
git tag v1.2.0
git push origin main --tags

# Update develop
git checkout develop
git merge main
git push origin develop
```

## 📁 Code Structure

### Shell Script Organization

#### Main Script (`calendar.sh`)
```bash
#!/bin/bash
set -euo pipefail

# Configuration and setup
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="${SCRIPT_DIR}/lib"

# Source utility libraries
source "${LIB_DIR}/utils.sh"
source "${LIB_DIR}/api.sh"
source "${LIB_DIR}/parser.sh"
source "${LIB_DIR}/calendar.sh"

# Main execution function
main() {
    local input_text="${POPCLIP_TEXT:-}"
    
    # Validate input
    validate_input "$input_text" || exit 1
    
    # Process with AI
    local api_response
    api_response=$(call_anthropic_api "$input_text") || exit 2
    
    # Parse response
    local event_data
    event_data=$(parse_ai_response "$api_response") || exit 3
    
    # Create calendar event
    create_calendar_event "$event_data" || exit 4
    
    # Success feedback
    echo "$(get_translation "success")"
}

# Error handling
trap 'handle_error $? $LINENO' ERR

# Execute main function
main "$@"
```

#### Utility Library (`lib/utils.sh`)
```bash
#!/bin/bash

# Logging functionality
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "${timestamp} [${level}] ${message}" >> "$LOG_FILE"
    
    # Also output to stderr for errors
    if [[ "$level" == "ERROR" ]]; then
        echo "${message}" >&2
    fi
}

# Input validation
validate_input() {
    local text="$1"
    
    if [[ -z "$text" ]]; then
        log "ERROR" "No text provided"
        return 1
    fi
    
    if [[ ${#text} -gt 2000 ]]; then
        log "ERROR" "Text too long (max 2000 characters)"
        return 1
    fi
    
    return 0
}

# Language detection
get_language() {
    local sys_lang
    sys_lang=$(defaults read .GlobalPreferences AppleLanguages 2>/dev/null | \
               head -1 | tr -d '",' | cut -d'-' -f1)
    
    case "$sys_lang" in
        zh) echo "zh" ;;
        es) echo "es" ;;
        fr) echo "fr" ;;
        de) echo "de" ;;
        ja) echo "ja" ;;
        *) echo "en" ;;
    esac
}

# Translation system
get_translation() {
    local key="$1"
    local lang
    lang=$(get_language)
    local translations_file="${POPCLIP_BUNDLE_PATH}/i18n.json"
    
    if [[ -f "$translations_file" ]]; then
        jq -r ".${lang}.${key} // .en.${key}" "$translations_file" 2>/dev/null || \
        echo "Translation not found: $key"
    else
        # Fallback translations
        case "$key" in
            "success") echo "Event added successfully" ;;
            "error") echo "Failed to add event" ;;
            *) echo "Unknown message" ;;
        esac
    fi
}
```

### React Component Structure

#### Main Demo Component
```typescript
// demo/src/llmcal-demo.tsx
import React, { useState, useEffect, useCallback } from 'react';
import { Calendar, Clock, Check, ChevronRight } from 'lucide-react';

interface Message {
  sender: 'me' | 'friend';
  text: string;
  timestamp: Date;
}

interface CalendarEvent {
  title: string;
  startTime: Date;
  endTime: Date;
  location?: string;
}

const LLMCalDemo: React.FC = () => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [isTyping, setIsTyping] = useState(false);
  const [selectedText, setSelectedText] = useState<Message | null>(null);
  const [showMenu, setShowMenu] = useState(false);
  
  // Animation and interaction logic
  const handleTextSelect = useCallback(() => {
    // Implementation
  }, []);
  
  const handleAddToCalendar = useCallback(() => {
    // Implementation
  }, []);
  
  return (
    <div className="llmcal-demo">
      {/* Component JSX */}
    </div>
  );
};

export default LLMCalDemo;
```

## 🔌 API Integration

### Anthropic API Client

#### API Configuration
```bash
# API settings
readonly API_BASE_URL="https://api.anthropic.com"
readonly API_VERSION="v1"
readonly MODEL_NAME="claude-3-sonnet-20240229"
readonly MAX_TOKENS="1024"
readonly TEMPERATURE="0.3"
```

#### API Request Function
```bash
call_anthropic_api() {
    local input_text="$1"
    local api_key="${POPCLIP_OPTION_ANTHROPIC_API_KEY:-$ANTHROPIC_API_KEY}"
    
    if [[ -z "$api_key" ]]; then
        log "ERROR" "API key not provided"
        return 1
    fi
    
    local payload
    payload=$(create_api_payload "$input_text")
    
    local response
    response=$(curl -s -w "%{http_code}" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $api_key" \
        -H "anthropic-version: 2023-06-01" \
        -d "$payload" \
        "${API_BASE_URL}/${API_VERSION}/messages")
    
    local http_code="${response: -3}"
    local body="${response%???}"
    
    if [[ "$http_code" != "200" ]]; then
        log "ERROR" "API request failed with code $http_code: $body"
        return 2
    fi
    
    echo "$body"
}

create_api_payload() {
    local input_text="$1"
    
    jq -n \
        --arg model "$MODEL_NAME" \
        --arg input "$input_text" \
        --argjson max_tokens "$MAX_TOKENS" \
        --argjson temperature "$TEMPERATURE" \
        '{
            model: $model,
            max_tokens: $max_tokens,
            temperature: $temperature,
            messages: [
                {
                    role: "user",
                    content: $input
                }
            ],
            system: "You are an AI assistant that converts natural language text into structured calendar event data. Always respond with valid JSON containing event details like title, start time, duration, location, attendees, and any other relevant information."
        }'
}
```

### Response Processing

#### JSON Parser
```bash
parse_ai_response() {
    local response="$1"
    
    # Extract content from API response
    local content
    content=$(echo "$response" | jq -r '.content[0].text' 2>/dev/null)
    
    if [[ -z "$content" || "$content" == "null" ]]; then
        log "ERROR" "Failed to extract content from API response"
        return 1
    fi
    
    # Parse JSON content
    local event_json
    event_json=$(echo "$content" | jq '.' 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        log "ERROR" "Invalid JSON in API response"
        return 1
    fi
    
    # Validate required fields
    validate_event_json "$event_json" || return 1
    
    echo "$event_json"
}

validate_event_json() {
    local json="$1"
    
    # Check required fields
    local title
    title=$(echo "$json" | jq -r '.title // empty')
    if [[ -z "$title" ]]; then
        log "ERROR" "Missing required field: title"
        return 1
    fi
    
    local start_date
    start_date=$(echo "$json" | jq -r '.startDate // empty')
    if [[ -z "$start_date" ]]; then
        log "ERROR" "Missing required field: startDate"
        return 1
    fi
    
    local start_time
    start_time=$(echo "$json" | jq -r '.startTime // empty')
    if [[ -z "$start_time" ]]; then
        log "ERROR" "Missing required field: startTime"
        return 1
    fi
    
    return 0
}
```

## 🧪 Testing

### Test Structure

```
tests/
├── unit/                 # Unit tests
│   ├── utils.test.js    # Utility function tests
│   ├── parser.test.js   # Parser tests
│   └── api.test.js      # API tests
├── integration/         # Integration tests
│   ├── calendar.test.sh # Calendar integration
│   ├── popclip.test.sh  # PopClip integration
│   └── e2e.test.js      # End-to-end tests
├── fixtures/            # Test data
│   ├── api-responses/   # Mock API responses
│   ├── events/          # Sample events
│   └── inputs/          # Test inputs
└── helpers/             # Test utilities
    ├── mock-api.js      # API mocking
    ├── calendar-mock.sh # Calendar mocking
    └── test-utils.js    # Common utilities
```

### Unit Testing

#### Shell Script Testing with Bats
```bash
#!/usr/bin/env bats
# tests/unit/utils.test.bats

load '../helpers/test-helper'

@test "get_language returns correct language code" {
    # Mock system defaults
    function defaults() {
        echo '("en-US", "zh-CN")'
    }
    export -f defaults
    
    source "${SCRIPT_DIR}/lib/utils.sh"
    
    result=$(get_language)
    [ "$result" = "en" ]
}

@test "validate_input rejects empty text" {
    source "${SCRIPT_DIR}/lib/utils.sh"
    
    run validate_input ""
    [ "$status" -eq 1 ]
}

@test "validate_input accepts valid text" {
    source "${SCRIPT_DIR}/lib/utils.sh"
    
    run validate_input "Meeting tomorrow at 2pm"
    [ "$status" -eq 0 ]
}

@test "get_translation returns correct text" {
    # Create mock translation file
    cat > "${BATS_TMPDIR}/i18n.json" << EOF
{
  "en": {
    "success": "Event created successfully"
  }
}
EOF
    
    export POPCLIP_BUNDLE_PATH="${BATS_TMPDIR}"
    source "${SCRIPT_DIR}/lib/utils.sh"
    
    result=$(get_translation "success")
    [ "$result" = "Event created successfully" ]
}
```

#### JavaScript Testing with Jest
```javascript
// tests/unit/parser.test.js
import { parseEventText, validateEventData } from '../../src/utils/parser';

describe('parseEventText', () => {
  test('should parse basic meeting text', () => {
    const input = 'Team meeting tomorrow at 2pm for 1 hour';
    const result = parseEventText(input);
    
    expect(result.title).toBe('Team meeting');
    expect(result.duration).toBe(60);
    expect(result.startTime).toMatch(/14:00/);
  });
  
  test('should handle meeting URLs', () => {
    const input = 'Zoom meeting at 3pm https://zoom.us/j/123456';
    const result = parseEventText(input);
    
    expect(result.url).toBe('https://zoom.us/j/123456');
    expect(result.location).toBe('Zoom');
  });
  
  test('should parse recurring events', () => {
    const input = 'Weekly standup every Monday at 9am';
    const result = parseEventText(input);
    
    expect(result.recurrence.frequency).toBe('weekly');
    expect(result.recurrence.daysOfWeek).toContain(1); // Monday
  });
});

describe('validateEventData', () => {
  test('should validate required fields', () => {
    const event = {
      title: 'Test Meeting',
      startDate: '2025-01-25',
      startTime: '14:00'
    };
    
    expect(validateEventData(event)).toBe(true);
  });
  
  test('should reject missing title', () => {
    const event = {
      startDate: '2025-01-25',
      startTime: '14:00'
    };
    
    expect(validateEventData(event)).toBe(false);
  });
});
```

### Integration Testing

#### Calendar Integration Test
```bash
#!/usr/bin/env bats
# tests/integration/calendar.test.bats

load '../helpers/test-helper'

setup() {
    # Create test calendar
    osascript -e 'tell application "Calendar" to make new calendar with properties {name:"LLMCal Test"}'
}

teardown() {
    # Clean up test calendar
    osascript -e 'tell application "Calendar" to delete calendar "LLMCal Test"'
}

@test "creates simple event in calendar" {
    export POPCLIP_TEXT="Test meeting tomorrow at 2pm"
    export POPCLIP_OPTION_ANTHROPIC_API_KEY="$TEST_API_KEY"
    export CALENDAR_NAME="LLMCal Test"
    
    run "${SCRIPT_DIR}/calendar.sh"
    
    [ "$status" -eq 0 ]
    [ "$output" = "Event created successfully" ]
    
    # Verify event was created
    event_count=$(osascript -e 'tell application "Calendar" to count events of calendar "LLMCal Test"')
    [ "$event_count" -eq 1 ]
}
```

### Performance Testing

#### Load Testing Script
```bash
#!/bin/bash
# tests/performance/load-test.sh

readonly TEST_DURATION=60  # seconds
readonly CONCURRENT_REQUESTS=5
readonly TEST_EVENTS=(
    "Meeting tomorrow at 2pm"
    "Weekly standup every Monday at 9am"
    "Lunch with client next Friday at noon"
)

run_performance_test() {
    local start_time
    start_time=$(date +%s)
    local end_time=$((start_time + TEST_DURATION))
    local request_count=0
    local success_count=0
    
    echo "Starting performance test for ${TEST_DURATION} seconds..."
    
    while [[ $(date +%s) -lt $end_time ]]; do
        for i in $(seq 1 $CONCURRENT_REQUESTS); do
            {
                local test_text="${TEST_EVENTS[$((RANDOM % ${#TEST_EVENTS[@]}))]}"
                export POPCLIP_TEXT="$test_text"
                
                if ./calendar.sh >/dev/null 2>&1; then
                    ((success_count++))
                fi
                ((request_count++))
            } &
        done
        wait
        
        sleep 1
    done
    
    local duration=$(($(date +%s) - start_time))
    local success_rate=$((success_count * 100 / request_count))
    
    echo "Performance test results:"
    echo "Duration: ${duration}s"
    echo "Total requests: $request_count"
    echo "Successful requests: $success_count"
    echo "Success rate: ${success_rate}%"
    echo "Requests per second: $((request_count / duration))"
}

run_performance_test
```

## 🐛 Debugging

### Debug Configuration

#### Enable Debug Mode
```bash
# Set environment variables
export DEBUG_MODE=true
export LOG_LEVEL=debug
export VERBOSE_LOGGING=true

# Or add to configuration file
echo "DEBUG_MODE=true" >> ~/.llmcal/config
echo "LOG_LEVEL=debug" >> ~/.llmcal/config
```

#### Debug Logging
```bash
# Enhanced logging function
debug_log() {
    if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
        local function_name="${FUNCNAME[1]}"
        local line_number="${BASH_LINENO[0]}"
        echo "[DEBUG] ${function_name}:${line_number} - $*" >&2
    fi
}

# Usage in functions
some_function() {
    debug_log "Starting function with parameters: $*"
    
    # Function logic here
    
    debug_log "Function completed successfully"
}
```

### Common Debug Scenarios

#### 1. API Request Debugging
```bash
debug_api_request() {
    local payload="$1"
    local api_key="$2"
    
    debug_log "API Request Debug:"
    debug_log "Payload: $payload"
    debug_log "API Key length: ${#api_key}"
    debug_log "API Endpoint: $API_BASE_URL"
    
    # Make request with verbose output
    local response
    response=$(curl -v \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $api_key" \
        -d "$payload" \
        "$API_BASE_URL/v1/messages" 2>&1)
    
    debug_log "Raw Response: $response"
    
    echo "$response"
}
```

#### 2. Calendar Event Debugging
```bash
debug_calendar_event() {
    local event_data="$1"
    
    debug_log "Calendar Event Debug:"
    debug_log "Event JSON: $event_data"
    
    # Validate each field
    local title
    title=$(echo "$event_data" | jq -r '.title')
    debug_log "Title: $title"
    
    local start_date
    start_date=$(echo "$event_data" | jq -r '.startDate')
    debug_log "Start Date: $start_date"
    
    local start_time
    start_time=$(echo "$event_data" | jq -r '.startTime')
    debug_log "Start Time: $start_time"
}
```

### Debugging Tools

#### Log Analysis Scripts
```bash
#!/bin/bash
# scripts/analyze-logs.sh

readonly LOG_FILE="$HOME/.llmcal/logs/llmcal.log"

analyze_errors() {
    echo "=== Error Analysis ==="
    grep -i error "$LOG_FILE" | tail -20
}

analyze_performance() {
    echo "=== Performance Analysis ==="
    grep "Duration:" "$LOG_FILE" | awk '{print $3}' | \
    awk '{sum+=$1; count++} END {print "Average:", sum/count "ms"}'
}

analyze_api_calls() {
    echo "=== API Call Analysis ==="
    grep "API request" "$LOG_FILE" | wc -l | \
    xargs echo "Total API calls:"
    
    grep "API request failed" "$LOG_FILE" | wc -l | \
    xargs echo "Failed API calls:"
}

# Run all analyses
analyze_errors
analyze_performance
analyze_api_calls
```

## 🚀 Performance Optimization

### Shell Script Optimization

#### Reduce Subshells
```bash
# Inefficient - creates subshell
result=$(some_command)

# Better - use here-string when possible
some_command <<< "$input" > tmpfile
result=$(cat tmpfile)

# Best - direct assignment when possible
read -r result < <(some_command)
```

#### Efficient JSON Processing
```bash
# Cache jq operations
readonly JQ_QUERY='.title, .startDate, .startTime'

parse_event_efficient() {
    local json="$1"
    
    # Single jq call for multiple values
    local values
    mapfile -t values < <(echo "$json" | jq -r "$JQ_QUERY")
    
    local title="${values[0]}"
    local start_date="${values[1]}"
    local start_time="${values[2]}"
    
    # Use values...
}
```

#### Batch Operations
```bash
# Process multiple events efficiently
batch_create_events() {
    local event_list="$1"
    
    # Build AppleScript for batch creation
    local applescript="tell application \"Calendar\""
    
    while IFS= read -r event_json; do
        local event_script
        event_script=$(build_event_applescript "$event_json")
        applescript="$applescript
        $event_script"
    done <<< "$event_list"
    
    applescript="$applescript
    end tell"
    
    # Execute batch operation
    osascript -e "$applescript"
}
```

### React Component Optimization

#### Memoization
```typescript
// Memoize expensive calculations
const memoizedEventData = useMemo(() => {
  return parseEventText(inputText);
}, [inputText]);

// Memoize callbacks
const handleEventCreate = useCallback((text: string) => {
  return createCalendarEvent(text);
}, []);

// Memoize components
const EventCard = memo(({ event }: { event: CalendarEvent }) => {
  return <div>{event.title}</div>;
});
```

#### Virtual Scrolling
```typescript
// For large event lists
import { FixedSizeList as List } from 'react-window';

const EventList = ({ events }: { events: CalendarEvent[] }) => {
  const renderItem = ({ index, style }: any) => (
    <div style={style}>
      <EventCard event={events[index]} />
    </div>
  );
  
  return (
    <List
      height={400}
      itemCount={events.length}
      itemSize={80}
    >
      {renderItem}
    </List>
  );
};
```

## 📦 Deployment

### Build Process

#### Build Scripts
```bash
#!/bin/bash
# scripts/build.sh

set -euo pipefail

readonly VERSION="${1:-dev}"
readonly BUILD_DIR="build"
readonly DIST_DIR="dist"

build_extension() {
    echo "Building PopClip extension..."
    
    # Clean previous builds
    rm -rf "$BUILD_DIR" "$DIST_DIR"
    mkdir -p "$BUILD_DIR" "$DIST_DIR"
    
    # Copy extension files
    cp -r LLMCal.popclipext "$BUILD_DIR/"
    
    # Process i18n files
    ./scripts/process-i18n.sh "$BUILD_DIR/LLMCal.popclipext/i18n.json"
    
    # Optimize shell scripts
    ./scripts/optimize-scripts.sh "$BUILD_DIR/LLMCal.popclipext/"
    
    # Create package
    cd "$BUILD_DIR"
    zip -r "../$DIST_DIR/LLMCal.popclipext.zip" LLMCal.popclipext/
    cd ..
    
    echo "Extension built successfully: $DIST_DIR/LLMCal.popclipext.zip"
}

build_demo() {
    echo "Building demo application..."
    
    cd demo
    npm run build
    cd ..
    
    # Copy demo build to dist
    cp -r demo/dist "$DIST_DIR/demo"
    
    echo "Demo built successfully: $DIST_DIR/demo"
}

build_docs() {
    echo "Building documentation..."
    
    # Generate API docs
    ./scripts/generate-api-docs.sh
    
    # Copy docs
    cp -r docs "$DIST_DIR/"
    
    echo "Documentation built successfully: $DIST_DIR/docs"
}

# Build all components
build_extension
build_demo
build_docs

echo "Build completed successfully!"
echo "Version: $VERSION"
echo "Build directory: $DIST_DIR"
```

### CI/CD Pipeline

#### GitHub Actions Configuration
```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: |
        npm install
        cd demo && npm install
        brew install shellcheck jq bats-core
    
    - name: Run linting
      run: |
        npm run lint
        shellcheck LLMCal.popclipext/*.sh
    
    - name: Run tests
      run: |
        npm test
        bats tests/unit/
    
    - name: Build project
      run: ./scripts/build.sh ${{ github.sha }}
    
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: build-artifacts
        path: dist/

  release:
    needs: test
    runs-on: macos-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Download artifacts
      uses: actions/download-artifact@v3
      with:
        name: build-artifacts
        path: dist/
    
    - name: Create release
      uses: softprops/action-gh-release@v1
      if: startsWith(github.ref, 'refs/tags/')
      with:
        files: dist/LLMCal.popclipext.zip
        draft: false
        prerelease: false
```

## 📋 Best Practices

### Code Quality

#### Shell Script Standards
1. **Always use strict mode**: `set -euo pipefail`
2. **Quote variables**: Use `"$variable"` instead of `$variable`
3. **Use readonly for constants**: `readonly CONSTANT_VALUE="value"`
4. **Validate inputs**: Check parameters before using them
5. **Handle errors gracefully**: Use proper error handling and cleanup

#### JavaScript/TypeScript Standards
1. **Use TypeScript**: Strong typing prevents runtime errors
2. **Follow ESLint rules**: Consistent code style and quality
3. **Write unit tests**: Test coverage should be > 80%
4. **Use meaningful names**: Functions and variables should be self-documenting
5. **Handle async operations**: Proper error handling for promises

### Security

#### API Key Management
1. **Never commit API keys**: Use environment variables or secure storage
2. **Rotate keys regularly**: Update API keys periodically
3. **Use least privilege**: Only request necessary permissions
4. **Validate inputs**: Sanitize all user inputs

#### Data Privacy
1. **Minimize data collection**: Only collect necessary information
2. **Secure data transmission**: Use HTTPS for all API calls
3. **No persistent storage**: Don't store sensitive user data
4. **Audit logging**: Log security-relevant events

### Performance

#### General Guidelines
1. **Measure before optimizing**: Use profiling tools
2. **Cache when appropriate**: Cache expensive operations
3. **Batch operations**: Reduce API calls and system operations
4. **Use efficient algorithms**: Choose appropriate data structures
5. **Monitor resource usage**: Track memory and CPU usage

---

For more information, see:
- [API Documentation](API.md)
- [Installation Guide](INSTALLATION.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Contributing Guide](../CONTRIBUTING.md)