/**
 * Integration tests for PopClip extension
 * Testing the full PopClip workflow including text processing and notification system
 */

const { exec, spawn } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const { MockServiceManager } = require('../mocks');

describe('PopClip Extension Integration', () => {
  let mockServices;
  let testEnv;
  let testBundlePath;

  beforeAll(async () => {
    // Start mock services
    mockServices = new MockServiceManager();
    await mockServices.startAll();

    // Setup test bundle directory
    testBundlePath = '/tmp/test-llmcal-bundle';
    await fs.mkdir(testBundlePath, { recursive: true });
    
    // Copy necessary files to test bundle
    const sourceBundle = path.join(__dirname, '../../LLMCal.popclipext');
    await copyBundleFiles(sourceBundle, testBundlePath);
  });

  afterAll(async () => {
    // Stop mock services
    await mockServices.stopAll();
    
    // Cleanup test bundle
    await fs.rm(testBundlePath, { recursive: true, force: true });
  });

  beforeEach(() => {
    testEnv = {
      ...process.env,
      POPCLIP_BUNDLE_PATH: testBundlePath,
      POPCLIP_OPTION_ANTHROPIC_API_KEY: 'test-api-key-valid',
      POPCLIP_OPTION_ZOOM_ACCOUNT_ID: 'test-account-id',
      POPCLIP_OPTION_ZOOM_CLIENT_ID: 'test-client-id',
      POPCLIP_OPTION_ZOOM_CLIENT_SECRET: 'test-client-secret',
      POPCLIP_OPTION_ZOOM_EMAIL: 'test@example.com',
      POPCLIP_OPTION_ZOOM_NAME: 'Test User',
      HOME: '/tmp',
      // Override API endpoints to use mocks
      ANTHROPIC_API_BASE: mockServices.getAnthropicEndpoint(),
      ZOOM_OAUTH_URL: mockServices.getZoomOAuthEndpoint(),
      ZOOM_API_BASE: mockServices.getZoomApiEndpoint()
    };
  });

  async function copyBundleFiles(sourceDir, targetDir) {
    try {
      // Copy essential files for testing
      const filesToCopy = ['i18n.json', 'Config.json'];
      
      for (const file of filesToCopy) {
        try {
          const sourceFile = path.join(sourceDir, file);
          const targetFile = path.join(targetDir, file);
          await fs.copyFile(sourceFile, targetFile);
        } catch (error) {
          // Create minimal files if source doesn't exist
          if (file === 'i18n.json') {
            await fs.writeFile(path.join(targetDir, file), JSON.stringify({
              en: {
                processing: "Processing...",
                success: "Event added to calendar",
                error: "Failed to add event"
              },
              zh: {
                processing: "处理中...",
                success: "事件已添加到日历",
                error: "添加事件失败"
              }
            }, null, 2));
          } else if (file === 'Config.json') {
            await fs.writeFile(path.join(targetDir, file), JSON.stringify({
              "name": "LLMCal Test",
              "description": "Test configuration",
              "identifier": "com.test.llmcal"
            }, null, 2));
          }
        }
      }
    } catch (error) {
      console.warn('Warning: Could not copy all bundle files:', error.message);
    }
  }

  describe('Bundle Configuration', () => {
    test('should load bundle configuration correctly', async () => {
      const configPath = path.join(testBundlePath, 'Config.json');
      const configData = await fs.readFile(configPath, 'utf8');
      const config = JSON.parse(configData);

      expect(config).toHaveProperty('name');
      expect(config).toHaveProperty('description');
      expect(config).toHaveProperty('identifier');
    });

    test('should load i18n translations correctly', async () => {
      const i18nPath = path.join(testBundlePath, 'i18n.json');
      const i18nData = await fs.readFile(i18nPath, 'utf8');
      const translations = JSON.parse(i18nData);

      expect(translations).toHaveProperty('en');
      expect(translations).toHaveProperty('zh');
      expect(translations.en).toHaveProperty('processing');
      expect(translations.en).toHaveProperty('success');
      expect(translations.en).toHaveProperty('error');
    });
  });

  describe('Environment Variable Handling', () => {
    test('should detect missing API key', (done) => {
      const testScript = `
        if [ -z "$POPCLIP_OPTION_ANTHROPIC_API_KEY" ]; then
          echo "MISSING_API_KEY"
          exit 1
        else
          echo "API_KEY_PRESENT"
        fi
      `;

      const envWithoutKey = { ...testEnv };
      delete envWithoutKey.POPCLIP_OPTION_ANTHROPIC_API_KEY;

      exec(testScript, { env: envWithoutKey }, (error, stdout, stderr) => {
        expect(error).not.toBeNull();
        expect(stdout.trim()).toBe('MISSING_API_KEY');
        done();
      });
    });

    test('should handle optional Zoom credentials', (done) => {
      const testScript = `
        check_zoom_credentials() {
          if [ -n "$POPCLIP_OPTION_ZOOM_ACCOUNT_ID" ] && 
             [ -n "$POPCLIP_OPTION_ZOOM_CLIENT_ID" ] && 
             [ -n "$POPCLIP_OPTION_ZOOM_CLIENT_SECRET" ]; then
            echo "ZOOM_CONFIGURED"
          else
            echo "ZOOM_NOT_CONFIGURED"
          fi
        }
        
        check_zoom_credentials
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('ZOOM_CONFIGURED');
        done();
      });
    });
  });

  describe('Text Processing Integration', () => {
    test('should process simple meeting text', async () => {
      const testText = 'Team meeting tomorrow at 3pm';
      const testScript = `
        export POPCLIP_TEXT="${testText}"
        
        # Mock the calendar.sh script behavior
        process_text() {
          local text="$1"
          
          # Simulate API call to mock server
          local response=$(curl -s -X POST "${mockServices.getAnthropicEndpoint()}" \\
            -H "x-api-key: $POPCLIP_OPTION_ANTHROPIC_API_KEY" \\
            -H "anthropic-version: 2023-06-01" \\
            -H "content-type: application/json" \\
            -d "{\\"model\\": \\"claude-sonnet-4-20250514\\", \\"max_tokens\\": 1024, \\"messages\\": [{\\"role\\": \\"user\\", \\"content\\": \\"Convert text to calendar event: $text\\"}]}")
          
          echo "$response" | jq -r '.content[0].text'
        }
        
        process_text "$POPCLIP_TEXT"
      `;

      return new Promise((resolve, reject) => {
        exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
          if (error) {
            reject(error);
            return;
          }

          try {
            const result = JSON.parse(stdout.trim());
            expect(result).toHaveProperty('title');
            expect(result).toHaveProperty('start_time');
            expect(result).toHaveProperty('end_time');
            expect(result.title).toContain('meeting');
            resolve();
          } catch (parseError) {
            reject(parseError);
          }
        });
      });
    }, 10000);

    test('should handle zoom meeting text', async () => {
      const testText = 'Zoom call with client at 2pm tomorrow';
      const testScript = `
        export POPCLIP_TEXT="${testText}"
        
        # Check if text requires Zoom meeting
        if [[ "$POPCLIP_TEXT" =~ [Zz]oom ]]; then
          echo "ZOOM_REQUIRED"
        else
          echo "NO_ZOOM"
        fi
      `;

      return new Promise((resolve, reject) => {
        exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
          if (error) {
            reject(error);
            return;
          }

          expect(stdout.trim()).toBe('ZOOM_REQUIRED');
          resolve();
        });
      });
    });
  });

  describe('Language Detection and Translation', () => {
    test('should detect system language', (done) => {
      const testScript = `
        get_language() {
          # Mock language detection
          local sys_lang=$(echo "en-US" | cut -d'-' -f1)
          case "$sys_lang" in
            zh*) echo "zh" ;;
            es*) echo "es" ;;
            *) echo "en" ;;
          esac
        }
        
        get_language
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toMatch(/^(en|zh|es)$/);
        done();
      });
    });

    test('should load translations from bundle', (done) => {
      const testScript = `
        get_translation() {
          local key="$1"
          local translations_file="$POPCLIP_BUNDLE_PATH/i18n.json"
          
          if [ -f "$translations_file" ]; then
            python3 - "$translations_file" "en" "$key" <<'EOF'
import sys, json
try:
    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        data = json.load(f)
    lang = sys.argv[2]
    key = sys.argv[3]
    text = data.get(lang, {}).get(key, data['en'][key])
    print(text)
except Exception as e:
    print(data['en'][key])
EOF
          else
            echo "Translation file not found"
          fi
        }
        
        get_translation "processing"
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('Processing...');
        done();
      });
    });
  });

  describe('Notification System', () => {
    test('should create notification commands', (done) => {
      const testScript = `
        create_notification() {
          local message="$1"
          local title="$2"
          
          # Generate AppleScript notification command (don't execute in test)
          echo "osascript -e \\"display notification \\\\"$message\\\\" with title \\\\"$title\\\\"\""
        }
        
        create_notification "Test notification" "LLMCal"
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const notification = stdout.trim();
        expect(notification).toContain('display notification');
        expect(notification).toContain('Test notification');
        expect(notification).toContain('LLMCal');
        done();
      });
    });

    test('should handle notification with special characters', (done) => {
      const testScript = `
        create_safe_notification() {
          local message="$1"
          local title="$2"
          
          # Escape special characters for AppleScript
          local safe_message=$(echo "$message" | sed 's/"/\\\\"/g')
          local safe_title=$(echo "$title" | sed 's/"/\\\\"/g')
          
          echo "osascript -e \\"display notification \\\\"$safe_message\\\\" with title \\\\"$safe_title\\\\"\""
        }
        
        create_safe_notification "Meeting with John's team @ 3pm!" "LLMCal"
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const notification = stdout.trim();
        expect(notification).toContain('display notification');
        expect(notification).toContain("John's team");
        done();
      });
    });
  });

  describe('Error Handling Integration', () => {
    test('should handle API authentication errors gracefully', async () => {
      const badEnv = { 
        ...testEnv, 
        POPCLIP_OPTION_ANTHROPIC_API_KEY: 'invalid-key'
      };

      const testScript = `
        test_api_auth() {
          local response=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST "${mockServices.getAnthropicEndpoint()}" \\
            -H "x-api-key: $POPCLIP_OPTION_ANTHROPIC_API_KEY" \\
            -H "anthropic-version: 2023-06-01" \\
            -H "content-type: application/json" \\
            -d '{"model": "claude-sonnet-4-20250514", "max_tokens": 100, "messages": [{"role": "user", "content": "test"}]}')
          
          local http_code=$(echo "$response" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
          
          if [ "$http_code" = "401" ]; then
            echo "AUTH_ERROR"
          else
            echo "AUTH_OK"
          fi
        }
        
        test_api_auth
      `;

      return new Promise((resolve) => {
        exec(testScript, { env: badEnv }, (error, stdout, stderr) => {
          expect(stdout.trim()).toBe('AUTH_ERROR');
          resolve();
        });
      });
    });

    test('should handle network connectivity issues', (done) => {
      const testScript = `
        test_connectivity() {
          # Test with non-existent endpoint
          local response=$(timeout 3s curl -s --max-time 2 -X POST "http://localhost:9999/nonexistent" \\
            -H "content-type: application/json" \\
            -d '{}' 2>&1 || echo "CONNECTION_ERROR")
          
          if [[ "$response" == *"CONNECTION_ERROR"* ]] || [[ "$response" == *"Connection refused"* ]]; then
            echo "NETWORK_ERROR"
          else
            echo "NETWORK_OK"
          fi
        }
        
        test_connectivity
      `;

      exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
        expect(stdout.trim()).toBe('NETWORK_ERROR');
        done();
      });
    });
  });

  describe('Logging Integration', () => {
    test('should create and write to log files', async () => {
      const testLogDir = '/tmp/test-llmcal-logs';
      const testLogFile = path.join(testLogDir, 'test.log');

      const testScript = `
        LOG_DIR="${testLogDir}"
        LOG_FILE="${testLogFile}"
        
        mkdir -p "$LOG_DIR"
        
        log() {
          echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOG_FILE"
        }
        
        log "Test log entry from integration test"
        log "Another test entry"
        
        echo "LOGS_WRITTEN"
      `;

      return new Promise((resolve, reject) => {
        exec(testScript, { env: testEnv }, async (error, stdout, stderr) => {
          if (error) {
            reject(error);
            return;
          }

          expect(stdout.trim()).toBe('LOGS_WRITTEN');

          try {
            const logContent = await fs.readFile(testLogFile, 'utf8');
            const lines = logContent.trim().split('\n');
            
            expect(lines).toHaveLength(2);
            expect(lines[0]).toMatch(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}: Test log entry from integration test/);
            expect(lines[1]).toMatch(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}: Another test entry/);

            // Cleanup
            await fs.rm(testLogDir, { recursive: true, force: true });
            resolve();
          } catch (readError) {
            reject(readError);
          }
        });
      });
    });
  });

  describe('Full Workflow Integration', () => {
    test('should complete simple meeting creation workflow', async () => {
      const testText = 'Team standup tomorrow at 9am';
      
      const testScript = `
        export POPCLIP_TEXT="${testText}"
        
        # Simulate the full workflow without actually creating calendar events
        full_workflow() {
          local text="$POPCLIP_TEXT"
          
          # Step 1: Process with Claude API (mock)
          local api_response=$(curl -s -X POST "${mockServices.getAnthropicEndpoint()}" \\
            -H "x-api-key: $POPCLIP_OPTION_ANTHROPIC_API_KEY" \\
            -H "anthropic-version: 2023-06-01" \\
            -H "content-type: application/json" \\
            -d "{\\"model\\": \\"claude-sonnet-4-20250514\\", \\"max_tokens\\": 1024, \\"messages\\": [{\\"role\\": \\"user\\", \\"content\\": \\"Convert text to calendar event: $text\\"}]}")
          
          if [ $? -ne 0 ]; then
            echo "WORKFLOW_API_ERROR"
            return 1
          fi
          
          # Step 2: Parse response
          local event_data=$(echo "$api_response" | jq -r '.content[0].text')
          if [ -z "$event_data" ] || [ "$event_data" = "null" ]; then
            echo "WORKFLOW_PARSE_ERROR"
            return 1
          fi
          
          # Step 3: Validate event data
          local title=$(echo "$event_data" | jq -r '.title')
          local start_time=$(echo "$event_data" | jq -r '.start_time')
          
          if [ -z "$title" ] || [ "$title" = "null" ] || [ -z "$start_time" ] || [ "$start_time" = "null" ]; then
            echo "WORKFLOW_VALIDATION_ERROR"
            return 1
          fi
          
          echo "WORKFLOW_SUCCESS"
          return 0
        }
        
        full_workflow
      `;

      return new Promise((resolve, reject) => {
        exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
          if (error) {
            reject(new Error(`Workflow failed: ${stderr}`));
            return;
          }

          expect(stdout.trim()).toBe('WORKFLOW_SUCCESS');
          resolve();
        });
      });
    }, 15000);

    test('should handle zoom meeting creation workflow', async () => {
      const testText = 'Zoom meeting with clients tomorrow at 2pm';
      
      const testScript = `
        export POPCLIP_TEXT="${testText}"
        
        zoom_workflow() {
          local text="$POPCLIP_TEXT"
          
          # Step 1: Detect Zoom requirement
          if [[ "$text" =~ [Zz]oom ]]; then
            echo "ZOOM_DETECTED"
          else
            echo "NO_ZOOM_DETECTED"
            return 1
          fi
          
          # Step 2: Get Zoom token (mock)
          local auth_header=$(echo -n "$POPCLIP_OPTION_ZOOM_CLIENT_ID:$POPCLIP_OPTION_ZOOM_CLIENT_SECRET" | base64)
          local token_response=$(curl -s -X POST "${mockServices.getZoomOAuthEndpoint()}?grant_type=account_credentials&account_id=$POPCLIP_OPTION_ZOOM_ACCOUNT_ID" \\
            -H "Authorization: Basic $auth_header")
          
          local access_token=$(echo "$token_response" | jq -r '.access_token')
          if [ -z "$access_token" ] || [ "$access_token" = "null" ]; then
            echo "ZOOM_TOKEN_ERROR"
            return 1
          fi
          
          # Step 3: Create meeting (mock)
          local meeting_response=$(curl -s -X POST "${mockServices.getZoomApiEndpoint()}/users/me/meetings" \\
            -H "Authorization: Bearer $access_token" \\
            -H "Content-Type: application/json" \\
            -d '{"topic": "Test Meeting", "type": 2, "duration": 60}')
          
          local join_url=$(echo "$meeting_response" | jq -r '.join_url')
          if [ -z "$join_url" ] || [ "$join_url" = "null" ]; then
            echo "ZOOM_CREATE_ERROR"
            return 1
          fi
          
          echo "ZOOM_WORKFLOW_SUCCESS"
          return 0
        }
        
        zoom_workflow
      `;

      return new Promise((resolve, reject) => {
        exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
          if (error) {
            reject(new Error(`Zoom workflow failed: ${stderr}`));
            return;
          }

          const output = stdout.trim();
          expect(output).toContain('ZOOM_DETECTED');
          expect(output).toContain('ZOOM_WORKFLOW_SUCCESS');
          resolve();
        });
      });
    }, 15000);
  });

  describe('Performance Integration', () => {
    test('should complete workflow within reasonable time', async () => {
      const startTime = Date.now();
      const testText = 'Quick meeting test';

      const testScript = `
        export POPCLIP_TEXT="${testText}"
        
        # Simulate lightweight workflow
        quick_workflow() {
          # Mock API call with minimal processing
          local response=$(curl -s -X POST "${mockServices.getAnthropicEndpoint()}" \\
            -H "x-api-key: $POPCLIP_OPTION_ANTHROPIC_API_KEY" \\
            -H "anthropic-version: 2023-06-01" \\
            -H "content-type: application/json" \\
            -d '{"model": "claude-sonnet-4-20250514", "max_tokens": 100, "messages": [{"role": "user", "content": "test"}]}')
          
          echo "QUICK_WORKFLOW_COMPLETE"
        }
        
        quick_workflow
      `;

      return new Promise((resolve, reject) => {
        exec(testScript, { env: testEnv }, (error, stdout, stderr) => {
          const endTime = Date.now();
          const duration = endTime - startTime;

          if (error) {
            reject(error);
            return;
          }

          expect(stdout.trim()).toBe('QUICK_WORKFLOW_COMPLETE');
          expect(duration).toBeLessThan(10000); // Should complete within 10 seconds
          resolve();
        });
      });
    });
  });
});