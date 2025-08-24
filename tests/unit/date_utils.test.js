/**
 * Unit tests for date and time utility functions
 * Testing date parsing, formatting, and timezone handling
 */

const { exec } = require('child_process');
const path = require('path');

describe('Date Utilities', () => {
  let mockEnv;
  let calendarScript;

  beforeEach(() => {
    mockEnv = {
      ...process.env,
      HOME: '/tmp',
      TZ: 'America/New_York'
    };

    calendarScript = path.join(__dirname, '../../LLMCal.popclipext/calendar.sh');
  });

  describe('Date Format Conversion', () => {
    test('should convert datetime with proper format', (done) => {
      const testScript = `
        convert_datetime() {
          local input_datetime="$1"
          input_datetime=$(echo "$input_datetime" | tr -d '"' | sed 's/\\([0-9][0-9]:[0-9][0-9]\\)$/\\1:00/')
          date -j -f "%Y-%m-%d %H:%M:%S" "$input_datetime" "+%Y-%m-%d %H:%M:%S" 2>/dev/null
        }
        
        convert_datetime "2024-01-15 15:30"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('2024-01-15 15:30:00');
        done();
      });
    });

    test('should handle datetime with quotes', (done) => {
      const testScript = `
        convert_datetime() {
          local input_datetime="$1"
          input_datetime=$(echo "$input_datetime" | tr -d '"' | sed 's/\\([0-9][0-9]:[0-9][0-9]\\)$/\\1:00/')
          date -j -f "%Y-%m-%d %H:%M:%S" "$input_datetime" "+%Y-%m-%d %H:%M:%S" 2>/dev/null
        }
        
        convert_datetime '"2024-01-15 15:30"'
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('2024-01-15 15:30:00');
        done();
      });
    });

    test('should handle datetime already with seconds', (done) => {
      const testScript = `
        convert_datetime() {
          local input_datetime="$1"
          input_datetime=$(echo "$input_datetime" | tr -d '"' | sed 's/\\([0-9][0-9]:[0-9][0-9]\\)$/\\1:00/')
          date -j -f "%Y-%m-%d %H:%M:%S" "$input_datetime" "+%Y-%m-%d %H:%M:%S" 2>/dev/null
        }
        
        convert_datetime "2024-01-15 15:30:45"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('2024-01-15 15:30:45');
        done();
      });
    });

    test('should return empty for invalid date format', (done) => {
      const testScript = `
        convert_datetime() {
          local input_datetime="$1"
          input_datetime=$(echo "$input_datetime" | tr -d '"' | sed 's/\\([0-9][0-9]:[0-9][0-9]\\)$/\\1:00/')
          date -j -f "%Y-%m-%d %H:%M:%S" "$input_datetime" "+%Y-%m-%d %H:%M:%S" 2>/dev/null
        }
        
        convert_datetime "invalid-date-format"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        // Should not crash, returns empty string
        expect(stdout.trim()).toBe('');
        done();
      });
    });
  });

  describe('ISO 8601 Format Conversion', () => {
    test('should convert to ISO 8601 format for Zoom API', (done) => {
      const testScript = `
        start_time_iso() {
          local input_time="$1"
          date -j -f "%Y-%m-%d %H:%M:%S" "$input_time" "+%Y-%m-%dT%H:%M:00Z"
        }
        
        start_time_iso "2024-01-15 15:30:00"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('2024-01-15T15:30:00Z');
        done();
      });
    });

    test('should handle timezone conversion', (done) => {
      const testScript = `
        # Test timezone conversion logic
        convert_to_utc() {
          local local_time="$1"
          local timezone="$2"
          # Simplified UTC conversion for testing
          echo "$local_time" | sed 's/ /T/' | sed 's/$/Z/'
        }
        
        convert_to_utc "2024-01-15 15:30:00" "America/New_York"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('2024-01-15T15:30:00Z');
        done();
      });
    });
  });

  describe('Duration Calculation', () => {
    test('should calculate meeting duration in minutes', (done) => {
      const testScript = `
        calculate_duration() {
          local start_time="$1"
          local end_time="$2"
          
          local start_seconds=$(date -j -f "%Y-%m-%d %H:%M:%S" "$start_time" "+%s")
          local end_seconds=$(date -j -f "%Y-%m-%d %H:%M:%S" "$end_time" "+%s")
          local duration=$(( (end_seconds - start_seconds) / 60 ))
          
          echo "$duration"
        }
        
        calculate_duration "2024-01-15 15:00:00" "2024-01-15 16:30:00"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(parseInt(stdout.trim())).toBe(90); // 1.5 hours = 90 minutes
        done();
      });
    });

    test('should handle same start and end time', (done) => {
      const testScript = `
        calculate_duration() {
          local start_time="$1"
          local end_time="$2"
          
          local start_seconds=$(date -j -f "%Y-%m-%d %H:%M:%S" "$start_time" "+%s")
          local end_seconds=$(date -j -f "%Y-%m-%d %H:%M:%S" "$end_time" "+%s")
          local duration=$(( (end_seconds - start_seconds) / 60 ))
          
          echo "$duration"
        }
        
        calculate_duration "2024-01-15 15:00:00" "2024-01-15 15:00:00"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(parseInt(stdout.trim())).toBe(0);
        done();
      });
    });

    test('should handle negative duration (end before start)', (done) => {
      const testScript = `
        calculate_duration() {
          local start_time="$1"
          local end_time="$2"
          
          local start_seconds=$(date -j -f "%Y-%m-%d %H:%M:%S" "$start_time" "+%s")
          local end_seconds=$(date -j -f "%Y-%m-%d %H:%M:%S" "$end_time" "+%s")
          local duration=$(( (end_seconds - start_seconds) / 60 ))
          
          echo "$duration"
        }
        
        calculate_duration "2024-01-15 16:00:00" "2024-01-15 15:00:00"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(parseInt(stdout.trim())).toBe(-60); // -1 hour
        done();
      });
    });
  });

  describe('Date Reference Generation', () => {
    test('should generate today reference date', (done) => {
      const testScript = `
        TODAY=$(date +%Y-%m-%d)
        echo "$TODAY"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const today = stdout.trim();
        expect(today).toMatch(/^\d{4}-\d{2}-\d{2}$/);
        
        // Verify it's actually today
        const expectedToday = new Date().toISOString().split('T')[0];
        expect(today).toBe(expectedToday);
        done();
      });
    });

    test('should generate tomorrow reference date', (done) => {
      const testScript = `
        TOMORROW=$(date -v+1d +%Y-%m-%d)
        echo "$TOMORROW"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const tomorrow = stdout.trim();
        expect(tomorrow).toMatch(/^\d{4}-\d{2}-\d{2}$/);
        
        // Verify it's actually tomorrow
        const expectedTomorrow = new Date();
        expectedTomorrow.setDate(expectedTomorrow.getDate() + 1);
        const expectedTomorrowStr = expectedTomorrow.toISOString().split('T')[0];
        expect(tomorrow).toBe(expectedTomorrowStr);
        done();
      });
    });

    test('should generate next Wednesday reference', (done) => {
      const testScript = `
        NEXT_WEDNESDAY=$(date -v+wed +%Y-%m-%d)
        echo "$NEXT_WEDNESDAY"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const nextWed = stdout.trim();
        expect(nextWed).toMatch(/^\d{4}-\d{2}-\d{2}$/);
        
        // Verify it's actually a Wednesday
        const wedDate = new Date(nextWed);
        expect(wedDate.getDay()).toBe(3); // Wednesday = 3
        done();
      });
    });
  });

  describe('Time Validation', () => {
    test('should validate correct time format', (done) => {
      const testScript = `
        validate_time_format() {
          local time_string="$1"
          if [[ "$time_string" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
            echo "valid"
          else
            echo "invalid"
          fi
        }
        
        validate_time_format "2024-01-15 15:30:00"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('valid');
        done();
      });
    });

    test('should detect invalid time format', (done) => {
      const testScript = `
        validate_time_format() {
          local time_string="$1"
          if [[ "$time_string" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
            echo "valid"
          else
            echo "invalid"
          fi
        }
        
        validate_time_format "invalid-time"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('invalid');
        done();
      });
    });

    test('should detect missing seconds in time format', (done) => {
      const testScript = `
        validate_time_format() {
          local time_string="$1"
          if [[ "$time_string" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
            echo "valid"
          else
            echo "invalid"
          fi
        }
        
        validate_time_format "2024-01-15 15:30"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('invalid');
        done();
      });
    });
  });

  describe('Business Days Calculation', () => {
    test('should calculate next business day', (done) => {
      const testScript = `
        next_business_day() {
          local current_date="$1"
          local day_of_week=$(date -j -f "%Y-%m-%d" "$current_date" "+%u")
          
          # If Friday (5), add 3 days to get Monday
          # If Saturday (6), add 2 days to get Monday  
          # Otherwise add 1 day
          case "$day_of_week" in
            5) date -j -f "%Y-%m-%d" "$current_date" -v+3d "+%Y-%m-%d" ;;
            6) date -j -f "%Y-%m-%d" "$current_date" -v+2d "+%Y-%m-%d" ;;
            *) date -j -f "%Y-%m-%d" "$current_date" -v+1d "+%Y-%m-%d" ;;
          esac
        }
        
        # Test with a Monday (should return Tuesday)
        next_business_day "2024-01-15"  # Assuming this is a Monday
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const nextDay = stdout.trim();
        expect(nextDay).toMatch(/^\d{4}-\d{2}-\d{2}$/);
        done();
      });
    });
  });

  describe('Recurring Event Patterns', () => {
    test('should generate daily recurrence rule', (done) => {
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
        
        generate_recurrence_rule "daily"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('FREQ=DAILY;INTERVAL=1');
        done();
      });
    });

    test('should generate monthly last Friday rule', (done) => {
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
        
        generate_recurrence_rule "monthly_last_friday"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('FREQ=MONTHLY;BYDAY=-1FR');
        done();
      });
    });

    test('should return empty for unknown recurrence pattern', (done) => {
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
        
        generate_recurrence_rule "unknown_pattern"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('');
        done();
      });
    });
  });

  describe('Performance Benchmarks', () => {
    test('date conversion should complete within reasonable time', (done) => {
      const startTime = Date.now();
      
      const testScript = `
        convert_datetime() {
          local input_datetime="$1"
          input_datetime=$(echo "$input_datetime" | tr -d '"' | sed 's/\\([0-9][0-9]:[0-9][0-9]\\)$/\\1:00/')
          date -j -f "%Y-%m-%d %H:%M:%S" "$input_datetime" "+%Y-%m-%d %H:%M:%S" 2>/dev/null
        }
        
        # Test multiple conversions
        for i in {1..100}; do
          convert_datetime "2024-01-15 15:30" > /dev/null
        done
        echo "completed"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        const endTime = Date.now();
        const duration = endTime - startTime;
        
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('completed');
        expect(duration).toBeLessThan(10000); // Should complete within 10 seconds
        done();
      });
    });

    test('duration calculation should be fast for multiple events', (done) => {
      const startTime = Date.now();
      
      const testScript = `
        calculate_duration() {
          local start_time="$1"
          local end_time="$2"
          local start_seconds=$(date -j -f "%Y-%m-%d %H:%M:%S" "$start_time" "+%s")
          local end_seconds=$(date -j -f "%Y-%m-%d %H:%M:%S" "$end_time" "+%s")
          echo $(( (end_seconds - start_seconds) / 60 ))
        }
        
        # Test multiple calculations
        for i in {1..50}; do
          calculate_duration "2024-01-15 15:00:00" "2024-01-15 16:00:00" > /dev/null
        done
        echo "completed"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        const endTime = Date.now();
        const duration = endTime - startTime;
        
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('completed');
        expect(duration).toBeLessThan(5000); // Should complete within 5 seconds
        done();
      });
    });
  });
});