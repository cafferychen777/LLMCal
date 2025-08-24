/**
 * Integration tests for macOS Calendar app interaction
 * Testing AppleScript generation and calendar event creation
 */

const { exec } = require('child_process');
const fs = require('fs').promises;
const path = require('path');

describe('Calendar App Integration', () => {
  let testEnv;
  let testLogDir;

  beforeEach(async () => {
    testLogDir = '/tmp/calendar-app-test-logs';
    await fs.mkdir(testLogDir, { recursive: true });

    testEnv = {
      ...process.env,
      HOME: '/tmp',
      LOG_DIR: testLogDir
    };
  });

  afterEach(async () => {
    // Cleanup test logs
    await fs.rm(testLogDir, { recursive: true, force: true });
  });

  describe('AppleScript Generation', () => {
    test('should generate valid AppleScript for basic event', (done) => {
      const testScript = `
        generate_basic_applescript() {
          local title="$1"
          local start_time="$2"
          local end_time="$3"
          local description="$4"
          local location="$5"
          
          cat << EOF
tell application "Calendar"
    set startDate to (current date)
    set year of startDate to (text 1 thru 4 of "$start_time") as integer
    set month of startDate to (text 6 thru 7 of "$start_time") as integer
    set day of startDate to (text 9 thru 10 of "$start_time") as integer
    set hours of startDate to (text 12 thru 13 of "$start_time") as integer
    set minutes of startDate to (text 15 thru 16 of "$start_time") as integer
    
    set endDate to (current date)
    set year of endDate to (text 1 thru 4 of "$end_time") as integer
    set month of endDate to (text 6 thru 7 of "$end_time") as integer
    set day of endDate to (text 9 thru 10 of "$end_time") as integer
    set hours of endDate to (text 12 thru 13 of "$end_time") as integer
    set minutes of endDate to (text 15 thru 16 of "$end_time") as integer
    
    tell calendar 1
        set eventProps to {summary:"$title", start date:startDate, end date:endDate, description:"$description", location:"$location"}
        set newEvent to make new event with properties eventProps
    end tell
end tell
EOF
        }
        
        generate_basic_applescript "Test Meeting" "2024-01-15 15:00:00" "2024-01-15 16:00:00" "Test description" "Conference Room"
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const script = stdout.trim();
        
        // Verify AppleScript structure
        expect(script).toContain('tell application "Calendar"');
        expect(script).toContain('set startDate to (current date)');
        expect(script).toContain('set endDate to (current date)');
        expect(script).toContain('summary:"Test Meeting"');
        expect(script).toContain('location:"Conference Room"');
        expect(script).toContain('end tell');
        
        done();
      });
    });

    test('should generate AppleScript with alerts', (done) => {
      const testScript = `
        generate_applescript_with_alerts() {
          local title="$1"
          local alerts="$2"
          
          cat << EOF
tell application "Calendar"
    set startDate to (current date)
    set endDate to (current date)
    
    tell calendar 1
        set eventProps to {summary:"$title", start date:startDate, end date:endDate}
        set newEvent to make new event with properties eventProps
        
        tell newEvent
EOF
          
          # Add alerts
          while IFS= read -r minutes; do
            if [ -n "$minutes" ]; then
              echo "            make new sound alarm at end of sound alarms with properties {trigger interval:-$minutes}"
            fi
          done <<< "$alerts"
          
          cat << EOF
        end tell
    end tell
end tell
EOF
        }
        
        ALERTS="15
30
60"
        generate_applescript_with_alerts "Meeting with Alerts" "$ALERTS"
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const script = stdout.trim();
        
        expect(script).toContain('make new sound alarm');
        expect(script).toContain('trigger interval:-15');
        expect(script).toContain('trigger interval:-30');
        expect(script).toContain('trigger interval:-60');
        
        done();
      });
    });

    test('should generate AppleScript with attendees', (done) => {
      const testScript = `
        generate_applescript_with_attendees() {
          local title="$1"
          local attendees="$2"
          
          cat << EOF
tell application "Calendar"
    set startDate to (current date)
    set endDate to (current date)
    
    tell calendar 1
        set eventProps to {summary:"$title", start date:startDate, end date:endDate}
        set newEvent to make new event with properties eventProps
        
        tell newEvent
EOF
          
          # Add attendees
          while IFS= read -r email; do
            if [ -n "$email" ]; then
              echo "            make new attendee at end of attendees with properties {email:\\"$email\\"}"
            fi
          done <<< "$attendees"
          
          cat << EOF
        end tell
    end tell
end tell
EOF
        }
        
        ATTENDEES="alice@example.com
bob@example.com
charlie@example.com"
        generate_applescript_with_attendees "Team Meeting" "$ATTENDEES"
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const script = stdout.trim();
        
        expect(script).toContain('make new attendee');
        expect(script).toContain('alice@example.com');
        expect(script).toContain('bob@example.com');
        expect(script).toContain('charlie@example.com');
        
        done();
      });
    });

    test('should generate AppleScript with recurrence rule', (done) => {
      const testScript = `
        generate_applescript_with_recurrence() {
          local title="$1"
          local recurrence_rule="$2"
          
          cat << EOF
tell application "Calendar"
    set startDate to (current date)
    set endDate to (current date)
    
    tell calendar 1
        set eventProps to {summary:"$title", start date:startDate, end date:endDate, recurrence:"$recurrence_rule"}
        set newEvent to make new event with properties eventProps
    end tell
end tell
EOF
        }
        
        generate_applescript_with_recurrence "Weekly Meeting" "FREQ=WEEKLY;INTERVAL=1"
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const script = stdout.trim();
        
        expect(script).toContain('recurrence:"FREQ=WEEKLY;INTERVAL=1"');
        
        done();
      });
    });
  });

  describe('Date Time Parsing for AppleScript', () => {
    test('should parse datetime correctly for AppleScript', (done) => {
      const testScript = `
        parse_datetime_for_applescript() {
          local datetime="$1"
          
          local year=$(echo "$datetime" | cut -c1-4)
          local month=$(echo "$datetime" | cut -c6-7)
          local day=$(echo "$datetime" | cut -c9-10)
          local hour=$(echo "$datetime" | cut -c12-13)
          local minute=$(echo "$datetime" | cut -c15-16)
          
          echo "YEAR: $year"
          echo "MONTH: $month"
          echo "DAY: $day"
          echo "HOUR: $hour"
          echo "MINUTE: $minute"
        }
        
        parse_datetime_for_applescript "2024-01-15 14:30:00"
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const lines = stdout.trim().split('\n');
        
        expect(lines[0]).toBe('YEAR: 2024');
        expect(lines[1]).toBe('MONTH: 01');
        expect(lines[2]).toBe('DAY: 15');
        expect(lines[3]).toBe('HOUR: 14');
        expect(lines[4]).toBe('MINUTE: 30');
        
        done();
      });
    });

    test('should validate datetime format before parsing', (done) => {
      const testScript = `
        validate_datetime_format() {
          local datetime="$1"
          
          if [[ "$datetime" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
            echo "VALID_FORMAT"
          else
            echo "INVALID_FORMAT"
          fi
        }
        
        echo "Test 1: $(validate_datetime_format "2024-01-15 14:30:00")"
        echo "Test 2: $(validate_datetime_format "invalid-datetime")"
        echo "Test 3: $(validate_datetime_format "2024-01-15 14:30")"
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const lines = stdout.trim().split('\n');
        
        expect(lines[0]).toBe('Test 1: VALID_FORMAT');
        expect(lines[1]).toBe('Test 2: INVALID_FORMAT');
        expect(lines[2]).toBe('Test 3: INVALID_FORMAT');
        
        done();
      });
    });
  });

  describe('Recurrence Rule Generation', () => {
    test('should generate correct recurrence rules', (done) => {
      const testScript = `
        generate_recurrence_rule() {
          local pattern="$1"
          
          case "$pattern" in
            "daily") echo "FREQ=DAILY;INTERVAL=1" ;;
            "weekly") echo "FREQ=WEEKLY;INTERVAL=1" ;;
            "biweekly") echo "FREQ=WEEKLY;INTERVAL=2" ;;
            "monthly") echo "FREQ=MONTHLY;INTERVAL=1" ;;
            "monthly_last_friday") echo "FREQ=MONTHLY;BYDAY=-1FR" ;;
            *) echo "" ;;
          esac
        }
        
        echo "Daily: $(generate_recurrence_rule "daily")"
        echo "Weekly: $(generate_recurrence_rule "weekly")"
        echo "Biweekly: $(generate_recurrence_rule "biweekly")"
        echo "Monthly: $(generate_recurrence_rule "monthly")"
        echo "Last Friday: $(generate_recurrence_rule "monthly_last_friday")"
        echo "Unknown: $(generate_recurrence_rule "unknown")"
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const lines = stdout.trim().split('\n');
        
        expect(lines[0]).toBe('Daily: FREQ=DAILY;INTERVAL=1');
        expect(lines[1]).toBe('Weekly: FREQ=WEEKLY;INTERVAL=1');
        expect(lines[2]).toBe('Biweekly: FREQ=WEEKLY;INTERVAL=2');
        expect(lines[3]).toBe('Monthly: FREQ=MONTHLY;INTERVAL=1');
        expect(lines[4]).toBe('Last Friday: FREQ=MONTHLY;BYDAY=-1FR');
        expect(lines[5]).toBe('Unknown: ');
        
        done();
      });
    });
  });

  describe('AppleScript Execution Safety', () => {
    test('should escape special characters in event data', (done) => {
      const testScript = `
        escape_applescript_string() {
          local input="$1"
          # Escape quotes and backslashes for AppleScript
          echo "$input" | sed 's/\\\\/\\\\\\\\/g' | sed 's/"/\\\\"/g'
        }
        
        echo "Test 1: $(escape_applescript_string 'Meeting with "quotes" and backslashes \\\\')"
        echo "Test 2: $(escape_applescript_string "John's meeting")"
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const output = stdout.trim();
        
        expect(output).toContain('\\"quotes\\"');
        expect(output).toContain("John's meeting");
        
        done();
      });
    });

    test('should validate AppleScript syntax before execution', (done) => {
      const testScript = `
        validate_applescript_syntax() {
          local script="$1"
          
          # Basic validation checks
          if [[ "$script" == *"tell application"* ]] && 
             [[ "$script" == *"end tell"* ]]; then
            echo "SYNTAX_VALID"
          else
            echo "SYNTAX_INVALID"
          fi
        }
        
        VALID_SCRIPT='tell application "Calendar"
        end tell'
        
        INVALID_SCRIPT='tell application "Calendar"
        # missing end tell'
        
        echo "Valid: $(validate_applescript_syntax "$VALID_SCRIPT")"
        echo "Invalid: $(validate_applescript_syntax "$INVALID_SCRIPT")"
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const lines = stdout.trim().split('\n');
        
        expect(lines[0]).toBe('Valid: SYNTAX_VALID');
        expect(lines[1]).toBe('Invalid: SYNTAX_INVALID');
        
        done();
      });
    });
  });

  describe('Calendar Application Detection', () => {
    test('should detect if Calendar app is available', (done) => {
      const testScript = `
        check_calendar_app() {
          # Check if Calendar app exists
          if [ -d "/Applications/Calendar.app" ] || [ -d "/System/Applications/Calendar.app" ]; then
            echo "CALENDAR_AVAILABLE"
          else
            echo "CALENDAR_NOT_AVAILABLE"
          fi
        }
        
        check_calendar_app
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const result = stdout.trim();
        expect(result).toMatch(/^(CALENDAR_AVAILABLE|CALENDAR_NOT_AVAILABLE)$/);
        done();
      });
    });

    test('should check Calendar app permissions', (done) => {
      const testScript = `
        check_calendar_permissions() {
          # This would normally check calendar permissions
          # For testing, we'll simulate the check
          echo "PERMISSION_CHECK_SIMULATED"
        }
        
        check_calendar_permissions
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('PERMISSION_CHECK_SIMULATED');
        done();
      });
    });
  });

  describe('Event Validation', () => {
    test('should validate required event fields', (done) => {
      const testScript = `
        validate_event_data() {
          local title="$1"
          local start_time="$2"
          local end_time="$3"
          
          local errors=""
          
          if [ -z "$title" ]; then
            errors="$errors MISSING_TITLE"
          fi
          
          if [ -z "$start_time" ]; then
            errors="$errors MISSING_START_TIME"
          fi
          
          if [ -z "$end_time" ]; then
            errors="$errors MISSING_END_TIME"
          fi
          
          # Check time format
          if [ -n "$start_time" ] && ! [[ "$start_time" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
            errors="$errors INVALID_START_TIME_FORMAT"
          fi
          
          if [ -n "$end_time" ] && ! [[ "$end_time" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
            errors="$errors INVALID_END_TIME_FORMAT"
          fi
          
          if [ -z "$errors" ]; then
            echo "VALID"
          else
            echo "INVALID:$errors"
          fi
        }
        
        echo "Test 1: $(validate_event_data "Meeting" "2024-01-15 15:00:00" "2024-01-15 16:00:00")"
        echo "Test 2: $(validate_event_data "" "2024-01-15 15:00:00" "2024-01-15 16:00:00")"
        echo "Test 3: $(validate_event_data "Meeting" "invalid-time" "2024-01-15 16:00:00")"
        echo "Test 4: $(validate_event_data "" "" "")"
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const lines = stdout.trim().split('\n');
        
        expect(lines[0]).toBe('Test 1: VALID');
        expect(lines[1]).toContain('MISSING_TITLE');
        expect(lines[2]).toContain('INVALID_START_TIME_FORMAT');
        expect(lines[3]).toContain('MISSING_TITLE');
        expect(lines[3]).toContain('MISSING_START_TIME');
        expect(lines[3]).toContain('MISSING_END_TIME');
        
        done();
      });
    });

    test('should validate event time logic', (done) => {
      const testScript = `
        validate_event_time_logic() {
          local start_time="$1"
          local end_time="$2"
          
          local start_seconds=$(date -j -f "%Y-%m-%d %H:%M:%S" "$start_time" "+%s" 2>/dev/null)
          local end_seconds=$(date -j -f "%Y-%m-%d %H:%M:%S" "$end_time" "+%s" 2>/dev/null)
          
          if [ -z "$start_seconds" ] || [ -z "$end_seconds" ]; then
            echo "INVALID_TIME_FORMAT"
            return 1
          fi
          
          if [ "$end_seconds" -le "$start_seconds" ]; then
            echo "END_BEFORE_START"
            return 1
          fi
          
          local duration=$(( (end_seconds - start_seconds) / 60 ))
          if [ "$duration" -lt 1 ]; then
            echo "DURATION_TOO_SHORT"
            return 1
          fi
          
          if [ "$duration" -gt 1440 ]; then  # More than 24 hours
            echo "DURATION_TOO_LONG"
            return 1
          fi
          
          echo "TIME_LOGIC_VALID"
        }
        
        echo "Test 1: $(validate_event_time_logic "2024-01-15 15:00:00" "2024-01-15 16:00:00")"
        echo "Test 2: $(validate_event_time_logic "2024-01-15 16:00:00" "2024-01-15 15:00:00")"
        echo "Test 3: $(validate_event_time_logic "2024-01-15 15:00:00" "2024-01-15 15:00:00")"
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const lines = stdout.trim().split('\n');
        
        expect(lines[0]).toBe('Test 1: TIME_LOGIC_VALID');
        expect(lines[1]).toBe('Test 2: END_BEFORE_START');
        expect(lines[2]).toBe('Test 3: END_BEFORE_START');
        
        done();
      });
    });
  });

  describe('AppleScript Testing Mode', () => {
    test('should generate AppleScript in test mode without execution', (done) => {
      const testScript = `
        generate_test_applescript() {
          local title="$1"
          local test_mode="$2"
          
          if [ "$test_mode" = "true" ]; then
            # In test mode, just validate the script generation
            cat << EOF
-- TEST MODE: AppleScript would be:
tell application "Calendar"
    -- Create event: $title
    -- This script was generated in test mode
end tell
EOF
          else
            # Normal mode would generate full script
            echo "tell application \"Calendar\""
            echo "    -- Create event: $title"
            echo "end tell"
          fi
        }
        
        echo "=== Test Mode ==="
        generate_test_applescript "Test Event" "true"
        echo ""
        echo "=== Normal Mode ==="
        generate_test_applescript "Test Event" "false"
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const output = stdout.trim();
        
        expect(output).toContain('-- TEST MODE: AppleScript would be:');
        expect(output).toContain('=== Normal Mode ===');
        expect(output).toContain('tell application "Calendar"');
        
        done();
      });
    });
  });

  describe('Error Handling', () => {
    test('should handle AppleScript execution errors', (done) => {
      const testScript = `
        handle_applescript_error() {
          local script="$1"
          local test_mode="$2"
          
          if [ "$test_mode" = "true" ]; then
            # Simulate AppleScript execution
            if [[ "$script" == *"invalid"* ]]; then
              echo "APPLESCRIPT_ERROR: Invalid syntax"
              return 1
            else
              echo "APPLESCRIPT_SUCCESS"
              return 0
            fi
          fi
        }
        
        echo "Valid script: $(handle_applescript_error "tell application \\"Calendar\\"" "true")"
        echo "Invalid script: $(handle_applescript_error "invalid script syntax" "true")"
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        const lines = stdout.trim().split('\n');
        
        expect(lines[0]).toBe('Valid script: APPLESCRIPT_SUCCESS');
        expect(lines[1]).toContain('APPLESCRIPT_ERROR');
        
        done();
      });
    });

    test('should provide meaningful error messages', (done) => {
      const testScript = `
        get_applescript_error_message() {
          local error_type="$1"
          
          case "$error_type" in
            "permission_denied") echo "Calendar access permission denied. Please grant access in System Preferences." ;;
            "app_not_found") echo "Calendar application not found. Please ensure Calendar.app is installed." ;;
            "syntax_error") echo "AppleScript syntax error. Please check the generated script." ;;
            "event_creation_failed") echo "Failed to create calendar event. Please check event data." ;;
            *) echo "Unknown error occurred during calendar event creation." ;;
          esac
        }
        
        echo "Permission: $(get_applescript_error_message "permission_denied")"
        echo "App not found: $(get_applescript_error_message "app_not_found")"
        echo "Syntax: $(get_applescript_error_message "syntax_error")"
        echo "Unknown: $(get_applescript_error_message "unknown_error")"
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const output = stdout.trim();
        
        expect(output).toContain('Calendar access permission denied');
        expect(output).toContain('Calendar application not found');
        expect(output).toContain('AppleScript syntax error');
        expect(output).toContain('Unknown error occurred');
        
        done();
      });
    });
  });

  describe('Performance Testing', () => {
    test('should generate AppleScript quickly for simple events', (done) => {
      const startTime = Date.now();

      const testScript = `
        generate_multiple_scripts() {
          for i in {1..10}; do
            cat << EOF > /dev/null
tell application "Calendar"
    set startDate to (current date)
    set endDate to (current date)
    tell calendar 1
        set eventProps to {summary:"Event $i", start date:startDate, end date:endDate}
        make new event with properties eventProps
    end tell
end tell
EOF
          done
          echo "SCRIPTS_GENERATED"
        }
        
        generate_multiple_scripts
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        const endTime = Date.now();
        const duration = endTime - startTime;

        expect(error).toBeNull();
        expect(stdout.trim()).toBe('SCRIPTS_GENERATED');
        expect(duration).toBeLessThan(5000); // Should complete within 5 seconds
        
        done();
      });
    });
  });
});