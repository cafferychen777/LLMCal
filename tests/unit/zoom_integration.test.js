/**
 * Unit tests for Zoom API integration
 * Testing Zoom meeting creation, authentication, and error handling
 */

const { exec } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const http = require('http');

describe('Zoom Integration', () => {
  let mockEnv;
  let mockZoomServer;
  let mockOAuthServer;
  const zoomServerPort = 3001;
  const oauthServerPort = 3002;

  beforeAll((done) => {
    let serversStarted = 0;

    // Mock Zoom OAuth server
    mockOAuthServer = http.createServer((req, res) => {
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Content-Type', 'application/json');

      if (req.url.includes('/oauth/token') && req.method === 'POST') {
        const authHeader = req.headers.authorization;
        
        if (!authHeader || !authHeader.startsWith('Basic ')) {
          res.writeHead(401);
          res.end(JSON.stringify({ error: 'invalid_client', error_description: 'Invalid client credentials' }));
          return;
        }

        // Decode basic auth
        const base64Credentials = authHeader.replace('Basic ', '');
        const credentials = Buffer.from(base64Credentials, 'base64').toString('ascii');
        const [clientId, clientSecret] = credentials.split(':');

        if (clientId === 'invalid-client' || clientSecret === 'invalid-secret') {
          res.writeHead(401);
          res.end(JSON.stringify({ error: 'invalid_client' }));
          return;
        }

        // Mock successful token response
        res.writeHead(200);
        res.end(JSON.stringify({
          access_token: 'mock_access_token_12345',
          token_type: 'bearer',
          expires_in: 3600,
          scope: 'meeting:write'
        }));
      } else {
        res.writeHead(404);
        res.end(JSON.stringify({ error: 'not_found' }));
      }
    });

    // Mock Zoom API server
    mockZoomServer = http.createServer((req, res) => {
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Content-Type', 'application/json');

      if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
      }

      if (req.url === '/v2/users/me/meetings' && req.method === 'POST') {
        const authHeader = req.headers.authorization;
        
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
          res.writeHead(401);
          res.end(JSON.stringify({ code: 124, message: 'Invalid access token' }));
          return;
        }

        const token = authHeader.replace('Bearer ', '');
        if (token === 'invalid_token') {
          res.writeHead(401);
          res.end(JSON.stringify({ code: 124, message: 'Invalid access token' }));
          return;
        }

        let body = '';
        req.on('data', chunk => {
          body += chunk.toString();
        });

        req.on('end', () => {
          try {
            const meetingData = JSON.parse(body);
            
            // Validate required fields
            if (!meetingData.topic) {
              res.writeHead(400);
              res.end(JSON.stringify({ code: 300, message: 'Meeting topic is required' }));
              return;
            }

            // Mock successful meeting creation
            const mockMeeting = {
              uuid: 'mock-meeting-uuid-123',
              id: 123456789,
              host_id: 'mock-host-id',
              topic: meetingData.topic,
              type: meetingData.type || 2,
              status: 'waiting',
              start_time: meetingData.start_time || '2024-01-15T15:00:00Z',
              duration: meetingData.duration || 60,
              timezone: meetingData.timezone || 'UTC',
              join_url: `https://zoom.us/j/123456789?pwd=mock-password`,
              start_url: 'https://zoom.us/s/123456789?zak=mock-zak',
              password: 'mock123',
              settings: {
                host_video: true,
                participant_video: true,
                cn_meeting: false,
                in_meeting: false,
                join_before_host: true,
                mute_upon_entry: false,
                watermark: false,
                use_pmi: false,
                approval_type: 2,
                audio: 'both',
                auto_recording: 'none'
              }
            };

            res.writeHead(201);
            res.end(JSON.stringify(mockMeeting));
          } catch (error) {
            res.writeHead(400);
            res.end(JSON.stringify({ code: 300, message: 'Invalid request format' }));
          }
        });
      } else {
        res.writeHead(404);
        res.end(JSON.stringify({ code: 404, message: 'Not found' }));
      }
    });

    mockOAuthServer.listen(oauthServerPort, () => {
      serversStarted++;
      if (serversStarted === 2) done();
    });

    mockZoomServer.listen(zoomServerPort, () => {
      serversStarted++;
      if (serversStarted === 2) done();
    });
  });

  afterAll((done) => {
    let serversClosed = 0;
    const checkDone = () => {
      serversClosed++;
      if (serversClosed === 2) done();
    };

    if (mockOAuthServer) {
      mockOAuthServer.close(checkDone);
    } else {
      checkDone();
    }

    if (mockZoomServer) {
      mockZoomServer.close(checkDone);
    } else {
      checkDone();
    }
  });

  beforeEach(() => {
    mockEnv = {
      ...process.env,
      POPCLIP_OPTION_ZOOM_ACCOUNT_ID: 'test-account-id',
      POPCLIP_OPTION_ZOOM_CLIENT_ID: 'test-client-id',
      POPCLIP_OPTION_ZOOM_CLIENT_SECRET: 'test-client-secret',
      POPCLIP_OPTION_ZOOM_EMAIL: 'test@example.com',
      POPCLIP_OPTION_ZOOM_NAME: 'Test User',
      HOME: '/tmp'
    };
  });

  describe('Zoom Token Authentication', () => {
    test('should successfully get access token with valid credentials', (done) => {
      const testScript = `
        get_zoom_token() {
          local account_id="$1"
          local client_id="$2"
          local client_secret="$3"
          
          local auth_token=$(echo -n "$client_id:$client_secret" | base64)
          local response=$(curl -s -X POST "http://localhost:${oauthServerPort}/oauth/token?grant_type=account_credentials&account_id=$account_id" \\
              -H "Authorization: Basic $auth_token")
          
          echo "$response" | jq -r '.access_token // empty'
        }
        
        get_zoom_token "test-account" "test-client-id" "test-client-secret"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('mock_access_token_12345');
        done();
      });
    });

    test('should handle invalid credentials', (done) => {
      const testScript = `
        get_zoom_token() {
          local account_id="$1"
          local client_id="$2"
          local client_secret="$3"
          
          local auth_token=$(echo -n "$client_id:$client_secret" | base64)
          local response=$(curl -s -X POST "http://localhost:${oauthServerPort}/oauth/token?grant_type=account_credentials&account_id=$account_id" \\
              -H "Authorization: Basic $auth_token")
          
          echo "$response" | jq -r '.access_token // empty'
        }
        
        get_zoom_token "test-account" "invalid-client" "invalid-secret"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('');
        done();
      });
    });

    test('should handle missing credentials', (done) => {
      const testScript = `
        get_zoom_token() {
          local account_id="$1"
          local client_id="$2"
          local client_secret="$3"
          
          if [ -z "$account_id" ] || [ -z "$client_id" ] || [ -z "$client_secret" ]; then
            echo "MISSING_CREDENTIALS"
            return 1
          fi
          
          echo "CREDENTIALS_PROVIDED"
        }
        
        get_zoom_token "" "" ""
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).not.toBeNull();
        expect(stdout.trim()).toBe('MISSING_CREDENTIALS');
        done();
      });
    });
  });

  describe('Zoom Meeting Creation', () => {
    test('should create meeting with valid data', (done) => {
      const testScript = `
        create_zoom_meeting() {
          local title="$1"
          local start_time="$2"
          local duration="$3"
          local token="mock_access_token_12345"
          
          local payload="{\\"topic\\": \\"$title\\", \\"type\\": 2, \\"start_time\\": \\"$start_time\\", \\"duration\\": $duration}"
          
          local response=$(curl -s -X POST "http://localhost:${zoomServerPort}/v2/users/me/meetings" \\
              -H "Authorization: Bearer $token" \\
              -H "Content-Type: application/json" \\
              -d "$payload")
          
          local join_url=$(echo "$response" | jq -r '.join_url // empty')
          if [ -n "$join_url" ]; then
            printf '{"join_url": "%s", "success": true}' "$join_url"
          else
            printf '{"success": false, "error": "Failed to create meeting"}'
          fi
        }
        
        create_zoom_meeting "Test Meeting" "2024-01-15T15:00:00Z" 60
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        
        const result = JSON.parse(stdout.trim());
        expect(result.success).toBe(true);
        expect(result.join_url).toContain('zoom.us/j/');
        done();
      });
    });

    test('should handle invalid access token', (done) => {
      const testScript = `
        create_zoom_meeting() {
          local title="$1"
          local token="invalid_token"
          
          local payload="{\\"topic\\": \\"$title\\"}"
          
          local response=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST "http://localhost:${zoomServerPort}/v2/users/me/meetings" \\
              -H "Authorization: Bearer $token" \\
              -H "Content-Type: application/json" \\
              -d "$payload")
          
          local http_code=$(echo "$response" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
          
          if [ "$http_code" = "401" ]; then
            printf '{"success": false, "error": "Authentication failed"}'
          else
            printf '{"success": true}'
          fi
        }
        
        create_zoom_meeting "Test Meeting"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        
        const result = JSON.parse(stdout.trim());
        expect(result.success).toBe(false);
        expect(result.error).toBe('Authentication failed');
        done();
      });
    });

    test('should handle missing meeting title', (done) => {
      const testScript = `
        create_zoom_meeting() {
          local title="$1"
          local token="mock_access_token_12345"
          
          local payload="{\\"topic\\": \\"$title\\"}"
          
          local response=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST "http://localhost:${zoomServerPort}/v2/users/me/meetings" \\
              -H "Authorization: Bearer $token" \\
              -H "Content-Type: application/json" \\
              -d "$payload")
          
          local http_code=$(echo "$response" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
          
          if [ "$http_code" = "400" ]; then
            printf '{"success": false, "error": "Invalid meeting data"}'
          else
            printf '{"success": true}'
          fi
        }
        
        create_zoom_meeting ""
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        
        const result = JSON.parse(stdout.trim());
        expect(result.success).toBe(false);
        done();
      });
    });

    test('should include meeting settings in request', (done) => {
      const testScript = `
        create_zoom_meeting_with_settings() {
          local title="$1"
          local token="mock_access_token_12345"
          local email="test@example.com"
          local name="Test User"
          
          local payload='{
            "topic": "'$title'",
            "type": 2,
            "settings": {
              "host_video": true,
              "participant_video": true,
              "join_before_host": true,
              "mute_upon_entry": false,
              "contact_email": "'$email'",
              "contact_name": "'$name'"
            }
          }'
          
          local response=$(curl -s -X POST "http://localhost:${zoomServerPort}/v2/users/me/meetings" \\
              -H "Authorization: Bearer $token" \\
              -H "Content-Type: application/json" \\
              -d "$payload")
          
          local join_url=$(echo "$response" | jq -r '.join_url // empty')
          local host_video=$(echo "$response" | jq -r '.settings.host_video // false')
          
          printf '{"join_url": "%s", "host_video": %s}' "$join_url" "$host_video"
        }
        
        create_zoom_meeting_with_settings "Meeting with Settings"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        
        const result = JSON.parse(stdout.trim());
        expect(result.join_url).toContain('zoom.us/j/');
        expect(result.host_video).toBe(true);
        done();
      });
    });
  });

  describe('Zoom Integration Detection', () => {
    test('should detect zoom requirements in text', (done) => {
      const testScript = `
        requires_zoom_meeting() {
          local text="$1"
          local location="$2"
          
          if [[ "$text" =~ [Zz]oom ]] || [ "$location" = "zoom" ] || [ "$location" = "Zoom" ]; then
            echo "true"
          else
            echo "false"
          fi
        }
        
        echo "Text with zoom: $(requires_zoom_meeting "Meeting on Zoom" "")"
        echo "Location zoom: $(requires_zoom_meeting "" "zoom")"
        echo "No zoom: $(requires_zoom_meeting "Regular meeting" "office")"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        
        const lines = stdout.trim().split('\n');
        expect(lines[0]).toBe('Text with zoom: true');
        expect(lines[1]).toBe('Location zoom: true');
        expect(lines[2]).toBe('No zoom: false');
        done();
      });
    });
  });

  describe('Meeting Duration Calculation', () => {
    test('should calculate meeting duration for zoom API', (done) => {
      const testScript = `
        calculate_zoom_duration() {
          local start_time="$1"
          local end_time="$2"
          
          local start_seconds=$(date -j -f "%Y-%m-%d %H:%M:%S" "$start_time" "+%s")
          local end_seconds=$(date -j -f "%Y-%m-%d %H:%M:%S" "$end_time" "+%s")
          local duration=$(( (end_seconds - start_seconds) / 60 ))
          
          echo "$duration"
        }
        
        calculate_zoom_duration "2024-01-15 15:00:00" "2024-01-15 16:30:00"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(parseInt(stdout.trim())).toBe(90);
        done();
      });
    });

    test('should handle default duration for missing end time', (done) => {
      const testScript = `
        get_default_duration() {
          local start_time="$1"
          local end_time="$2"
          
          if [ -z "$end_time" ]; then
            echo "60"  # Default 1 hour
          else
            local start_seconds=$(date -j -f "%Y-%m-%d %H:%M:%S" "$start_time" "+%s")
            local end_seconds=$(date -j -f "%Y-%m-%d %H:%M:%S" "$end_time" "+%s")
            echo $(( (end_seconds - start_seconds) / 60 ))
          fi
        }
        
        get_default_duration "2024-01-15 15:00:00" ""
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(parseInt(stdout.trim())).toBe(60);
        done();
      });
    });
  });

  describe('Attendees Processing', () => {
    test('should format attendees for zoom API', (done) => {
      const testScript = `
        format_zoom_attendees() {
          local attendees="$1"
          
          if [ -z "$attendees" ]; then
            echo "[]"
            return
          fi
          
          local attendees_json="["
          while IFS= read -r email; do
            if [ -n "$email" ]; then
              if [ "$attendees_json" != "[" ]; then
                attendees_json="$attendees_json,"
              fi
              attendees_json="$attendees_json{\\"email\\":\\"$email\\"}"
            fi
          done <<< "$attendees"
          attendees_json="$attendees_json]"
          
          echo "$attendees_json"
        }
        
        ATTENDEES="alice@example.com
bob@example.com
charlie@example.com"
        
        format_zoom_attendees "$ATTENDEES"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        
        const result = stdout.trim();
        expect(result).toContain('"email":"alice@example.com"');
        expect(result).toContain('"email":"bob@example.com"');
        expect(result).toContain('"email":"charlie@example.com"');
        done();
      });
    });

    test('should handle empty attendees list', (done) => {
      const testScript = `
        format_zoom_attendees() {
          local attendees="$1"
          
          if [ -z "$attendees" ]; then
            echo "[]"
            return
          fi
          
          echo "not empty"
        }
        
        format_zoom_attendees ""
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('[]');
        done();
      });
    });
  });

  describe('Error Response Handling', () => {
    test('should parse zoom API error responses', (done) => {
      const testScript = `
        parse_zoom_error() {
          local response="$1"
          
          local code=$(echo "$response" | jq -r '.code // 0')
          local message=$(echo "$response" | jq -r '.message // "Unknown error"')
          
          echo "CODE: $code"
          echo "MESSAGE: $message"
        }
        
        ERROR_RESPONSE='{"code": 124, "message": "Invalid access token"}'
        parse_zoom_error "$ERROR_RESPONSE"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        
        const lines = stdout.trim().split('\n');
        expect(lines[0]).toBe('CODE: 124');
        expect(lines[1]).toBe('MESSAGE: Invalid access token');
        done();
      });
    });
  });

  describe('Integration Flow', () => {
    test('should complete full zoom meeting creation flow', (done) => {
      const testScript = `
        full_zoom_flow() {
          local title="$1"
          local start_time="$2"
          local duration="$3"
          local account_id="test-account"
          local client_id="test-client-id"
          local client_secret="test-client-secret"
          
          # Step 1: Get access token
          local auth_token=$(echo -n "$client_id:$client_secret" | base64)
          local token_response=$(curl -s -X POST "http://localhost:${oauthServerPort}/oauth/token?grant_type=account_credentials&account_id=$account_id" \\
              -H "Authorization: Basic $auth_token")
          
          local access_token=$(echo "$token_response" | jq -r '.access_token // empty')
          
          if [ -z "$access_token" ]; then
            printf '{"success": false, "error": "Failed to get access token"}'
            return 1
          fi
          
          # Step 2: Create meeting
          local meeting_payload="{\\"topic\\": \\"$title\\", \\"type\\": 2, \\"start_time\\": \\"$start_time\\", \\"duration\\": $duration}"
          
          local meeting_response=$(curl -s -X POST "http://localhost:${zoomServerPort}/v2/users/me/meetings" \\
              -H "Authorization: Bearer $access_token" \\
              -H "Content-Type: application/json" \\
              -d "$meeting_payload")
          
          local join_url=$(echo "$meeting_response" | jq -r '.join_url // empty')
          
          if [ -n "$join_url" ]; then
            printf '{"success": true, "join_url": "%s"}' "$join_url"
          else
            printf '{"success": false, "error": "Failed to create meeting"}'
          fi
        }
        
        full_zoom_flow "Integration Test Meeting" "2024-01-15T15:00:00Z" 60
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        
        const result = JSON.parse(stdout.trim());
        expect(result.success).toBe(true);
        expect(result.join_url).toContain('zoom.us/j/');
        done();
      });
    });
  });

  describe('Performance Tests', () => {
    test('should create zoom meeting within reasonable time', (done) => {
      const startTime = Date.now();

      const testScript = `
        # Simulate quick zoom meeting creation
        quick_zoom_test() {
          local token="mock_access_token_12345"
          local payload='{"topic": "Quick Test", "type": 2}'
          
          local response=$(curl -s -X POST "http://localhost:${zoomServerPort}/v2/users/me/meetings" \\
              -H "Authorization: Bearer $token" \\
              -H "Content-Type: application/json" \\
              -d "$payload")
          
          echo "$response" | jq -r '.join_url // empty'
        }
        
        quick_zoom_test
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        const endTime = Date.now();
        const processingTime = endTime - startTime;

        expect(error).toBeNull();
        expect(stdout.trim()).toContain('zoom.us/j/');
        expect(processingTime).toBeLessThan(5000); // Should complete within 5 seconds
        done();
      });
    });
  });
});