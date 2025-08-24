/**
 * Unit tests for API client functionality
 * Testing Anthropic Claude API interactions and error handling
 */

const { exec } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const http = require('http');

describe('API Client', () => {
  let mockEnv;
  let mockServer;
  let mockServerPort = 3000;

  beforeAll((done) => {
    // Create a mock HTTP server for testing
    mockServer = http.createServer((req, res) => {
      const url = req.url;
      const method = req.method;

      // CORS headers
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
      res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-api-key, anthropic-version');

      if (method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
      }

      if (url === '/v1/messages' && method === 'POST') {
        let body = '';
        req.on('data', chunk => {
          body += chunk.toString();
        });

        req.on('end', () => {
          try {
            const requestData = JSON.parse(body);
            
            // Check API key
            const apiKey = req.headers['x-api-key'];
            if (!apiKey || apiKey === 'invalid-key') {
              res.writeHead(401, { 'Content-Type': 'application/json' });
              res.end(JSON.stringify({ error: { type: 'authentication_error', message: 'Invalid API key' } }));
              return;
            }

            // Check for rate limiting test
            if (apiKey === 'rate-limit-key') {
              res.writeHead(429, { 'Content-Type': 'application/json' });
              res.end(JSON.stringify({ error: { type: 'rate_limit_error', message: 'Rate limit exceeded' } }));
              return;
            }

            // Mock successful response
            const mockResponse = {
              content: [{
                text: JSON.stringify({
                  title: 'Test Meeting',
                  start_time: '2024-01-15 15:00',
                  end_time: '2024-01-15 16:00',
                  description: 'Generated test meeting',
                  location: 'Conference Room A',
                  url: 'https://example.com/meeting',
                  alerts: [15, 30],
                  recurrence: 'none',
                  attendees: ['test@example.com']
                })
              }],
              model: 'claude-sonnet-4-20250514',
              stop_reason: 'end_turn',
              usage: {
                input_tokens: 100,
                output_tokens: 200
              }
            };

            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify(mockResponse));
          } catch (error) {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: { type: 'invalid_request_error', message: 'Invalid JSON' } }));
          }
        });
      } else {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: { type: 'not_found_error', message: 'Not found' } }));
      }
    });

    mockServer.listen(mockServerPort, () => {
      done();
    });
  });

  afterAll((done) => {
    if (mockServer) {
      mockServer.close(done);
    } else {
      done();
    }
  });

  beforeEach(() => {
    mockEnv = {
      ...process.env,
      POPCLIP_TEXT: 'Team meeting tomorrow at 3pm',
      POPCLIP_OPTION_ANTHROPIC_API_KEY: 'test-api-key',
      HOME: '/tmp'
    };
  });

  describe('API Request Construction', () => {
    test('should construct valid JSON payload for Claude API', (done) => {
      const testScript = `
        POPCLIP_TEXT="Team meeting tomorrow at 3pm"
        TODAY="2024-01-14"
        TOMORROW="2024-01-15"
        
        JSON_PAYLOAD="{
            \\"model\\": \\"claude-sonnet-4-20250514\\",
            \\"max_tokens\\": 1024,
            \\"messages\\": [{
                \\"role\\": \\"user\\",
                \\"content\\": \\"Convert text to calendar event: '$POPCLIP_TEXT'\\\\nUse these dates:\\\\n- Today: $TODAY\\\\n- Tomorrow: $TOMORROW\\\\nReturn only JSON with: title, start_time, end_time, description, location, url, alerts, recurrence, attendees\\"
            }]
        }"
        
        # Validate JSON structure
        echo "$JSON_PAYLOAD" | python3 -m json.tool > /dev/null
        echo "JSON_VALID"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('JSON_VALID');
        done();
      });
    });

    test('should handle special characters in text input', (done) => {
      const testScript = `
        POPCLIP_TEXT="Meeting with John's team @ 3pm (urgent!)"
        TODAY="2024-01-14"
        TOMORROW="2024-01-15"
        
        # Escape special characters for JSON
        ESCAPED_TEXT=$(echo "$POPCLIP_TEXT" | sed 's/"/\\\\"/g' | sed "s/'/\\\\'/g")
        
        JSON_PAYLOAD="{
            \\"model\\": \\"claude-sonnet-4-20250514\\",
            \\"max_tokens\\": 1024,
            \\"messages\\": [{
                \\"role\\": \\"user\\",
                \\"content\\": \\"Convert text to calendar event: '$ESCAPED_TEXT'\\"
            }]
        }"
        
        echo "$JSON_PAYLOAD" | python3 -m json.tool > /dev/null
        echo "ESCAPED_JSON_VALID"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout.trim()).toBe('ESCAPED_JSON_VALID');
        done();
      });
    });
  });

  describe('API Response Handling', () => {
    test('should parse valid Claude API response', async () => {
      const mockResponse = {
        content: [{
          text: JSON.stringify({
            title: 'Test Meeting',
            start_time: '2024-01-15 15:00',
            end_time: '2024-01-15 16:00',
            description: 'Test description',
            location: 'Office',
            url: 'https://example.com',
            alerts: [15],
            recurrence: 'none',
            attendees: []
          })
        }]
      };

      const tempFile = '/tmp/mock_response.json';
      await fs.writeFile(tempFile, JSON.stringify(mockResponse));

      const testScript = `
        TEMP_PYTHON_FILE="/tmp/process_event.py"
        cat > "$TEMP_PYTHON_FILE" << 'EOF'
import sys
import json
import re

def clean_json_content(content):
    content = re.sub(r'^\\`\\`\\`json\\s*', '', content)
    content = re.sub(r'\\s*\\`\\`\\`$', '', content)
    content = content.strip()
    return content

def process_response(response_text):
    try:
        response = json.loads(response_text)
        if not response:
            raise ValueError("Empty response")
            
        if all(key in response for key in ['title', 'start_time']):
            return response
            
        content = response.get('content', [{}])[0].get('text', '')
        if not content:
            raise ValueError("No content in response")
            
        content = clean_json_content(content)
        event = json.loads(content)
        
        if not all(key in event for key in ['title', 'start_time']):
            raise ValueError("Missing required fields in event data")
            
        return event
            
    except Exception as e:
        print(f"Error processing response: {str(e)}", file=sys.stderr)
        return None

if __name__ == "__main__":
    response_text = sys.stdin.read()
    event = process_response(response_text)
    if event:
        print(json.dumps(event))
    else:
        print("{}")
EOF
        
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

    test('should handle malformed API response', async () => {
      const malformedResponse = '{ "content": [{ "text": "invalid json content" }] }';
      const tempFile = '/tmp/malformed_response.json';
      await fs.writeFile(tempFile, malformedResponse);

      const testScript = `
        TEMP_PYTHON_FILE="/tmp/process_event.py"
        cat > "$TEMP_PYTHON_FILE" << 'EOF'
import sys
import json
import re

def process_response(response_text):
    try:
        response = json.loads(response_text)
        content = response.get('content', [{}])[0].get('text', '')
        event = json.loads(content)
        return event
    except Exception:
        return None

if __name__ == "__main__":
    response_text = sys.stdin.read()
    event = process_response(response_text)
    if event:
        print(json.dumps(event))
    else:
        print("{}")
EOF
        
        python3 "$TEMP_PYTHON_FILE" < "${tempFile}"
      `;

      return new Promise((resolve) => {
        exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
          const result = stdout.trim();
          expect(result).toBe('{}');
          resolve();
        });
      });
    });

    test('should extract required fields from response', async () => {
      const mockResponse = {
        content: [{
          text: JSON.stringify({
            title: 'Important Meeting',
            start_time: '2024-01-15 14:00',
            end_time: '2024-01-15 15:30',
            description: 'Quarterly review',
            location: 'Boardroom',
            url: '',
            alerts: [5, 15, 30],
            recurrence: 'weekly',
            attendees: ['alice@company.com', 'bob@company.com']
          })
        }]
      };

      const tempFile = '/tmp/complete_response.json';
      await fs.writeFile(tempFile, JSON.stringify(mockResponse));

      const testScript = `
        RESPONSE=$(cat "${tempFile}")
        
        # Extract fields using jq
        TITLE=$(echo "$RESPONSE" | jq -r '.content[0].text' | jq -r '.title')
        START_TIME=$(echo "$RESPONSE" | jq -r '.content[0].text' | jq -r '.start_time')
        END_TIME=$(echo "$RESPONSE" | jq -r '.content[0].text' | jq -r '.end_time')
        ALERTS=$(echo "$RESPONSE" | jq -r '.content[0].text' | jq -r '.alerts[]')
        RECURRENCE=$(echo "$RESPONSE" | jq -r '.content[0].text' | jq -r '.recurrence')
        
        echo "TITLE: $TITLE"
        echo "START: $START_TIME" 
        echo "END: $END_TIME"
        echo "RECURRENCE: $RECURRENCE"
      `;

      return new Promise((resolve, reject) => {
        exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
          if (error) {
            reject(error);
            return;
          }

          const lines = stdout.trim().split('\n');
          expect(lines[0]).toBe('TITLE: Important Meeting');
          expect(lines[1]).toBe('START: 2024-01-15 14:00');
          expect(lines[2]).toBe('END: 2024-01-15 15:30');
          expect(lines[3]).toBe('RECURRENCE: weekly');
          resolve();
        });
      });
    });
  });

  describe('HTTP Error Handling', () => {
    test('should handle authentication errors', (done) => {
      const testScript = `
        # Test with invalid API key
        RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST "http://localhost:${mockServerPort}/v1/messages" \\
            -H "x-api-key: invalid-key" \\
            -H "anthropic-version: 2023-06-01" \\
            -H "content-type: application/json" \\
            -d '{"model": "claude-sonnet-4-20250514", "max_tokens": 100, "messages": [{"role": "user", "content": "test"}]}')
        
        HTTP_CODE=$(echo "$RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
        BODY=$(echo "$RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')
        
        echo "CODE: $HTTP_CODE"
        echo "BODY: $BODY"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        const output = stdout.trim();
        expect(output).toContain('CODE: 401');
        expect(output).toContain('authentication_error');
        done();
      });
    });

    test('should handle rate limiting errors', (done) => {
      const testScript = `
        # Test with rate limit trigger
        RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST "http://localhost:${mockServerPort}/v1/messages" \\
            -H "x-api-key: rate-limit-key" \\
            -H "anthropic-version: 2023-06-01" \\
            -H "content-type: application/json" \\
            -d '{"model": "claude-sonnet-4-20250514", "max_tokens": 100, "messages": [{"role": "user", "content": "test"}]}')
        
        HTTP_CODE=$(echo "$RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
        
        echo "CODE: $HTTP_CODE"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        const output = stdout.trim();
        expect(output).toBe('CODE: 429');
        done();
      });
    });

    test('should handle network timeouts', (done) => {
      const testScript = `
        # Test with very short timeout
        RESPONSE=$(timeout 1s curl -s --max-time 1 -X POST "http://localhost:9999/v1/messages" \\
            -H "x-api-key: test-key" \\
            -H "content-type: application/json" \\
            -d '{}' 2>&1 || echo "TIMEOUT_OR_CONNECTION_ERROR")
        
        echo "RESULT: $RESPONSE"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        const output = stdout.trim();
        expect(output).toContain('TIMEOUT_OR_CONNECTION_ERROR');
        done();
      });
    });
  });

  describe('API Request Validation', () => {
    test('should validate required headers', (done) => {
      const testScript = `
        # Test request without API key header
        RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST "http://localhost:${mockServerPort}/v1/messages" \\
            -H "content-type: application/json" \\
            -d '{"model": "claude-sonnet-4-20250514", "max_tokens": 100, "messages": [{"role": "user", "content": "test"}]}')
        
        HTTP_CODE=$(echo "$RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
        echo "CODE: $HTTP_CODE"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        const output = stdout.trim();
        expect(output).toBe('CODE: 401');
        done();
      });
    });

    test('should validate JSON payload structure', (done) => {
      const testScript = `
        # Test with invalid JSON payload
        RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST "http://localhost:${mockServerPort}/v1/messages" \\
            -H "x-api-key: test-api-key" \\
            -H "content-type: application/json" \\
            -d 'invalid json payload')
        
        HTTP_CODE=$(echo "$RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
        echo "CODE: $HTTP_CODE"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        const output = stdout.trim();
        expect(output).toBe('CODE: 400');
        done();
      });
    });
  });

  describe('Response Processing Performance', () => {
    test('should process typical response within reasonable time', (done) => {
      const startTime = Date.now();

      const testScript = `
        # Test successful API call
        RESPONSE=$(curl -s -X POST "http://localhost:${mockServerPort}/v1/messages" \\
            -H "x-api-key: test-api-key" \\
            -H "anthropic-version: 2023-06-01" \\
            -H "content-type: application/json" \\
            -d '{"model": "claude-sonnet-4-20250514", "max_tokens": 100, "messages": [{"role": "user", "content": "test meeting"}]}')
        
        # Process response
        TITLE=$(echo "$RESPONSE" | jq -r '.content[0].text' | jq -r '.title')
        echo "TITLE: $TITLE"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        const endTime = Date.now();
        const processingTime = endTime - startTime;

        expect(error).toBeNull();
        expect(stdout.trim()).toBe('TITLE: Test Meeting');
        expect(processingTime).toBeLessThan(5000); // Should complete within 5 seconds
        done();
      });
    });
  });

  describe('Retry Logic', () => {
    test('should implement basic retry mechanism', (done) => {
      const testScript = `
        make_api_request_with_retry() {
          local max_retries=3
          local retry_count=0
          local url="$1"
          local headers="$2"
          local data="$3"
          
          while [ $retry_count -lt $max_retries ]; do
            local response=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST "$url" $headers -d "$data")
            local http_code=$(echo "$response" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
            
            if [ "$http_code" = "200" ]; then
              echo "$response" | sed 's/HTTP_CODE:[0-9]*$//'
              return 0
            elif [ "$http_code" = "429" ]; then
              retry_count=$((retry_count + 1))
              sleep $((retry_count * 2))  # Exponential backoff
            else
              echo "ERROR: HTTP $http_code"
              return 1
            fi
          done
          
          echo "ERROR: Max retries exceeded"
          return 1
        }
        
        # Test with successful request
        make_api_request_with_retry "http://localhost:${mockServerPort}/v1/messages" \\
          '-H "x-api-key: test-api-key" -H "content-type: application/json"' \\
          '{"model": "claude-sonnet-4-20250514", "max_tokens": 100, "messages": [{"role": "user", "content": "test"}]}'
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        expect(stdout).toContain('"title": "Test Meeting"');
        done();
      });
    });
  });

  describe('Error Response Parsing', () => {
    test('should extract error details from API response', (done) => {
      const testScript = `
        parse_api_error() {
          local response="$1"
          local error_type=$(echo "$response" | jq -r '.error.type // "unknown_error"')
          local error_message=$(echo "$response" | jq -r '.error.message // "Unknown error occurred"')
          
          echo "TYPE: $error_type"
          echo "MESSAGE: $error_message"
        }
        
        # Test with error response
        ERROR_RESPONSE='{"error": {"type": "authentication_error", "message": "Invalid API key"}}'
        parse_api_error "$ERROR_RESPONSE"
      `;

      exec(testScript, { env: mockEnv }, (error, stdout, stderr) => {
        expect(error).toBeNull();
        const lines = stdout.trim().split('\n');
        expect(lines[0]).toBe('TYPE: authentication_error');
        expect(lines[1]).toBe('MESSAGE: Invalid API key');
        done();
      });
    });
  });
});