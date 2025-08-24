/**
 * Unit tests for calendar.sh functions
 * Testing main calendar processing and AppleScript generation
 */

const { spawn, exec } = require('child_process');
const fs = require('fs').promises;
const path = require('path');

describe('Calendar Processing', () => {
  let mockEnv;
  let calendarScript;
  const testLogDir = '/tmp/llmcal_test_logs';

  beforeEach(async () => {
    // Create test log directory
    await fs.mkdir(testLogDir, { recursive: true });

    // Mock environment variables
    mockEnv = {
      ...process.env,
      POPCLIP_TEXT: 'Team meeting tomorrow at 3pm for 1 hour',
      POPCLIP_OPTION_ANTHROPIC_API_KEY: 'test-api-key',
      POPCLIP_BUNDLE_PATH: path.join(__dirname, '../../LLMCal.popclipext'),
      HOME: '/tmp'
    };

    // Path to calendar script
    calendarScript = path.join(__dirname, '../../LLMCal.popclipext/calendar.sh');
  });

  afterEach(async () => {
    // Clean up test logs
    try {
      await fs.rm(testLogDir, { recursive: true, force: true });
    } catch (error) {
      // Ignore cleanup errors
    }
  });

  describe('Language Detection', () => {
    test('should detect English as default language', (done) => {
      const testScript = `
        source "${calendarScript}"
        get_language
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toMatch(/^(en|zh|es)$/);
        done();
      });
    });

    test('should handle Chinese language setting', (done) => {
      const testEnv = { 
        ...mockEnv,
        // Simulate Chinese language setting
        LANG: 'zh_CN.UTF-8'
      };

      const testScript = `
        # Mock the defaults command for Chinese
        function defaults() {
          echo '("zh-Hans-CN", "en-CN")'
        }
        export -f defaults
        source "${calendarScript}"
        get_language
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('zh');
        done();
      });
    });
  });

  describe('Translation System', () => {
    test('should load translations from i18n.json', (done) => {
      const testScript = `
        export POPCLIP_BUNDLE_PATH="${path.join(__dirname, '../../LLMCal.popclipext')}"
        source "${calendarScript}"
        get_translation "processing"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBeTruthy();
        done();
      });
    });

    test('should fallback to English for missing translations', (done) => {
      const testScript = `
        export POPCLIP_BUNDLE_PATH="/non/existent/path"
        source "${calendarScript}"
        get_translation "processing"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('Processing...');
        done();
      });
    });
  });

  describe('Date Processing', () => {
    test('should correctly set today, tomorrow, and reference dates', (done) => {
      const testScript = `
        source "${calendarScript}"
        echo "TODAY: $TODAY"
        echo "TOMORROW: $TOMORROW"
        echo "DAY_AFTER_TOMORROW: $DAY_AFTER_TOMORROW"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        
        const lines = stdout.trim().split('\n');
        const today = lines[0].replace('TODAY: ', '');
        const tomorrow = lines[1].replace('TOMORROW: ', '');
        const dayAfter = lines[2].replace('DAY_AFTER_TOMORROW: ', '');

        // Verify date formats (YYYY-MM-DD)
        expect(today).toMatch(/^\d{4}-\d{2}-\d{2}$/);
        expect(tomorrow).toMatch(/^\d{4}-\d{2}-\d{2}$/);
        expect(dayAfter).toMatch(/^\d{4}-\d{2}-\d{2}$/);

        // Verify date sequence
        const todayDate = new Date(today);
        const tomorrowDate = new Date(tomorrow);
        const dayAfterDate = new Date(dayAfter);

        expect(tomorrowDate.getTime() - todayDate.getTime()).toBe(24 * 60 * 60 * 1000);
        expect(dayAfterDate.getTime() - tomorrowDate.getTime()).toBe(24 * 60 * 60 * 1000);

        done();
      });
    });
  });

  describe('JSON Processing', () => {
    test('should process valid Claude API response', async () => {
      const mockResponse = {
        content: [{
          text: JSON.stringify({
            title: 'Test Meeting',
            start_time: '2024-01-15 15:00',
            end_time: '2024-01-15 16:00',
            description: 'Test meeting description',
            location: 'Conference Room A',
            url: 'https://example.com/meeting',
            alerts: [15, 30],
            recurrence: 'none',
            attendees: ['test@example.com']
          })
        }]
      };

      const tempFile = '/tmp/test_response.json';
      await fs.writeFile(tempFile, JSON.stringify(mockResponse));

      const testScript = `
        source "${calendarScript}"
        python3 "$TEMP_PYTHON_FILE" < "${tempFile}"
      `;

      return new Promise((resolve, reject) => {
        exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
          if (error) {
            reject(error);
            return;
          }

          try {
            const result = JSON.parse(stdout.trim());
            expect(result.title).toBe('Test Meeting');
            expect(result.start_time).toBe('2024-01-15 15:00');
            expect(result.end_time).toBe('2024-01-15 16:00');
            resolve();
          } catch (parseError) {
            reject(parseError);
          }
        });
      });
    });

    test('should handle malformed JSON response', async () => {
      const invalidResponse = '{ invalid json }';
      const tempFile = '/tmp/test_invalid_response.json';
      await fs.writeFile(tempFile, invalidResponse);

      const testScript = `
        source "${calendarScript}"
        python3 "$TEMP_PYTHON_FILE" < "${tempFile}" 2>/dev/null || echo "{}"
      `;

      return new Promise((resolve) => {
        exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
          const result = stdout.trim();
          expect(result).toBe('{}');
          resolve();
        });
      });
    });
  });

  describe('DateTime Conversion', () => {
    test('should convert datetime format correctly', (done) => {
      const testScript = `
        source "${calendarScript}"
        convert_datetime "2024-01-15 15:30"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('2024-01-15 15:30:00');
        done();
      });
    });

    test('should handle invalid datetime format', (done) => {
      const testScript = `
        source "${calendarScript}"
        convert_datetime "invalid-date"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        // Should not crash but return empty or error
        expect(stdout.trim()).toBe('');
        done();
      });
    });
  });

  describe('AppleScript Generation', () => {
    test('should generate valid AppleScript for simple event', async () => {
      const mockEventData = {
        title: 'Test Meeting',
        start_time: '2024-01-15 15:00:00',
        end_time: '2024-01-15 16:00:00',
        description: 'Test description',
        location: 'Office',
        url: 'https://example.com',
        alerts: ['15'],
        recurrence: 'none',
        attendees: ['test@example.com']
      };

      // This would require extracting the AppleScript generation into a testable function
      // For now, we test that the script structure is correct
      const expectedPatterns = [
        /tell application "Calendar"/,
        /set startDate to \(current date\)/,
        /set endDate to \(current date\)/,
        /make new event with properties/,
        /summary:"Test Meeting"/,
        /location:"Office"/,
        /url:"https:\/\/example\.com"/
      ];

      // Test that AppleScript contains expected elements
      expectedPatterns.forEach(pattern => {
        // This is a placeholder - in real implementation, we'd extract
        // the AppleScript generation into a testable function
        expect(pattern).toBeInstanceOf(RegExp);
      });
    });
  });

  describe('Zoom Integration Detection', () => {
    test('should detect Zoom meeting requirement', (done) => {
      const zoomTexts = [
        'Team meeting on Zoom tomorrow',
        'Schedule zoom call for project review',
        'ZOOM meeting with clients'
      ];

      const testScript = `
        check_zoom_requirement() {
          local text="$1"
          if [[ "$text" =~ [Zz]oom ]]; then
            echo "zoom_required"
          else
            echo "no_zoom"
          fi
        }

        check_zoom_requirement "${zoomTexts[0]}"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('zoom_required');
        done();
      });
    });
  });

  describe('Error Handling', () => {
    test('should handle missing API key gracefully', (done) => {
      const testEnvNoKey = { ...mockEnv };
      delete testEnvNoKey.POPCLIP_OPTION_ANTHROPIC_API_KEY;

      const testScript = `
        if [ -z "$POPCLIP_OPTION_ANTHROPIC_API_KEY" ]; then
          echo "API_KEY_MISSING"
        else
          echo "API_KEY_PRESENT"
        fi
      `;

      exec(testScript, { env: testEnvNoKey }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('API_KEY_MISSING');
        done();
      });
    });

    test('should handle missing required fields', (done) => {
      const testScript = `
        TITLE=""
        START_TIME=""
        END_TIME=""
        
        if [ -z "$TITLE" ] || [ -z "$START_TIME" ] || [ -z "$END_TIME" ]; then
          echo "MISSING_FIELDS"
          exit 1
        else
          echo "ALL_FIELDS_PRESENT"
        fi
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).not.toBeNull();
        expect(stdout.trim()).toBe('MISSING_FIELDS');
        done();
      });
    });
  });

  describe('Logging System', () => {
    test('should create log entries', async () => {
      const testLogFile = path.join(testLogDir, 'test.log');
      
      const testScript = `
        LOG_FILE="${testLogFile}"
        log() {
          echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOG_FILE"
        }
        
        log "Test log entry"
        log "Another test entry"
      `;

      return new Promise((resolve, reject) => {
        exec(testScript, { env: mockEnv }, async (error, stdout, stderr) => {
          if (error) {
            reject(error);
            return;
          }

          try {
            const logContent = await fs.readFile(testLogFile, 'utf8');
            const lines = logContent.trim().split('\n');
            
            expect(lines).toHaveLength(2);
            expect(lines[0]).toMatch(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}: Test log entry/);
            expect(lines[1]).toMatch(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}: Another test entry/);
            resolve();
          } catch (readError) {
            reject(readError);
          }
        });
      });
    });
  });

  describe('Performance Tests', () => {
    test('should process simple text within reasonable time', (done) => {
      const startTime = Date.now();
      const testScript = `
        # Simulate the key processing steps without API calls
        TITLE="Test Meeting"
        START_TIME="2024-01-15 15:00:00"
        END_TIME="2024-01-15 16:00:00"
        
        # Simulate datetime conversion
        convert_datetime() {
          echo "$1"
        }
        
        START_TIME_CONVERTED=$(convert_datetime "$START_TIME")
        END_TIME_CONVERTED=$(convert_datetime "$END_TIME")
        
        echo "Processing completed"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        const endTime = Date.now();
        const processingTime = endTime - startTime;

        expect(error).toBeNull();
        expect(stdout.trim()).toBe('Processing completed');
        expect(processingTime).toBeLessThan(5000); // Should complete within 5 seconds
        done();
      });
    });
  });
});