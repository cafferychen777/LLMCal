/**
 * Mock services orchestrator for LLMCal testing
 * Manages all mock API servers and provides test utilities
 */

const { AnthropicApiMock, testScenarios } = require('./anthropic-api');
const { ZoomApiMock, zoomTestScenarios } = require('./zoom-api');

class MockServiceManager {
  constructor() {
    this.anthropicMock = new AnthropicApiMock(3003);
    this.zoomMock = new ZoomApiMock(3004, 3005);
    this.services = [];
  }

  async startAll() {
    console.log('Starting all mock services...');
    
    await Promise.all([
      this.anthropicMock.start(),
      this.zoomMock.start()
    ]);

    this.services = [this.anthropicMock, this.zoomMock];
    console.log('All mock services started successfully');
  }

  async stopAll() {
    console.log('Stopping all mock services...');
    
    await Promise.all([
      this.anthropicMock.stop(),
      this.zoomMock.stop()
    ]);

    this.services = [];
    console.log('All mock services stopped successfully');
  }

  getAnthropicMock() {
    return this.anthropicMock;
  }

  getZoomMock() {
    return this.zoomMock;
  }

  // Helper methods for tests
  getAnthropicEndpoint() {
    return `http://localhost:3003/v1/messages`;
  }

  getZoomOAuthEndpoint() {
    return `http://localhost:3005/oauth/token`;
  }

  getZoomApiEndpoint() {
    return `http://localhost:3004/v2`;
  }

  // Test data generators
  generateTestApiKey(type = 'valid') {
    const keys = {
      valid: 'test-api-key-valid',
      invalid: 'invalid-key',
      rateLimit: 'rate-limit-key',
      expired: 'expired-key'
    };
    return keys[type] || keys.valid;
  }

  generateTestZoomCredentials(type = 'valid') {
    const credentials = {
      valid: {
        account_id: 'test-account-id',
        client_id: 'test-client-id',
        client_secret: 'test-client-secret'
      },
      invalid: {
        account_id: 'test-account-id',
        client_id: 'invalid-client',
        client_secret: 'invalid-secret'
      },
      rateLimit: {
        account_id: 'test-account-id',
        client_id: 'rate-limit-client',
        client_secret: 'rate-limit-secret'
      }
    };
    return credentials[type] || credentials.valid;
  }

  generateTestEvent(type = 'basic') {
    const events = {
      basic: {
        title: 'Test Meeting',
        start_time: '2024-01-15 15:00',
        end_time: '2024-01-15 16:00',
        description: 'Basic test meeting',
        location: 'Conference Room A',
        alerts: [15],
        recurrence: 'none',
        attendees: []
      },
      zoom: {
        title: 'Zoom Meeting',
        start_time: '2024-01-15 14:00',
        end_time: '2024-01-15 15:00',
        description: 'Meeting with Zoom integration',
        location: 'Zoom Meeting',
        url: 'https://zoom.us/j/123456789',
        alerts: [5, 15],
        recurrence: 'none',
        attendees: ['alice@example.com', 'bob@example.com']
      },
      recurring: {
        title: 'Weekly Standup',
        start_time: '2024-01-15 09:00',
        end_time: '2024-01-15 09:30',
        description: 'Weekly team standup',
        location: 'Office',
        alerts: [15, 30],
        recurrence: 'weekly',
        attendees: ['team@example.com']
      },
      complex: {
        title: 'Quarterly Review Meeting',
        start_time: '2024-01-15 13:00',
        end_time: '2024-01-15 16:00',
        description: 'Comprehensive quarterly business review with all stakeholders',
        location: 'Executive Boardroom',
        url: 'https://example.com/meeting-materials',
        alerts: [1440, 60, 15], // 1 day, 1 hour, 15 minutes
        recurrence: 'none',
        attendees: [
          'ceo@company.com',
          'cfo@company.com',
          'cto@company.com',
          'vp-sales@company.com',
          'vp-marketing@company.com'
        ]
      }
    };
    return events[type] || events.basic;
  }

  // Validation helpers
  validateEventStructure(event) {
    const requiredFields = ['title', 'start_time', 'end_time'];
    const optionalFields = ['description', 'location', 'url', 'alerts', 'recurrence', 'attendees'];
    const allFields = [...requiredFields, ...optionalFields];

    const validation = {
      valid: true,
      errors: [],
      warnings: []
    };

    // Check required fields
    for (const field of requiredFields) {
      if (!event[field]) {
        validation.valid = false;
        validation.errors.push(`Missing required field: ${field}`);
      }
    }

    // Check for unknown fields
    for (const field in event) {
      if (!allFields.includes(field)) {
        validation.warnings.push(`Unknown field: ${field}`);
      }
    }

    // Validate field types
    if (event.start_time && !/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/.test(event.start_time)) {
      validation.valid = false;
      validation.errors.push('Invalid start_time format. Expected: YYYY-MM-DD HH:MM');
    }

    if (event.end_time && !/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/.test(event.end_time)) {
      validation.valid = false;
      validation.errors.push('Invalid end_time format. Expected: YYYY-MM-DD HH:MM');
    }

    if (event.alerts && !Array.isArray(event.alerts)) {
      validation.valid = false;
      validation.errors.push('alerts must be an array');
    }

    if (event.attendees && !Array.isArray(event.attendees)) {
      validation.valid = false;
      validation.errors.push('attendees must be an array');
    }

    return validation;
  }

  // Test environment setup
  setupTestEnvironment(testName) {
    return {
      POPCLIP_TEXT: `Test event for ${testName}`,
      POPCLIP_OPTION_ANTHROPIC_API_KEY: this.generateTestApiKey(),
      POPCLIP_OPTION_ZOOM_ACCOUNT_ID: 'test-account-id',
      POPCLIP_OPTION_ZOOM_CLIENT_ID: 'test-client-id',
      POPCLIP_OPTION_ZOOM_CLIENT_SECRET: 'test-client-secret',
      POPCLIP_OPTION_ZOOM_EMAIL: 'test@example.com',
      POPCLIP_OPTION_ZOOM_NAME: 'Test User',
      POPCLIP_BUNDLE_PATH: '/tmp/test-bundle',
      HOME: '/tmp',
      ANTHROPIC_API_BASE: this.getAnthropicEndpoint(),
      ZOOM_OAUTH_URL: this.getZoomOAuthEndpoint(),
      ZOOM_API_BASE: this.getZoomApiEndpoint()
    };
  }

  // Performance testing helpers
  async measureResponseTime(operation) {
    const startTime = process.hrtime.bigint();
    await operation();
    const endTime = process.hrtime.bigint();
    return Number(endTime - startTime) / 1000000; // Convert to milliseconds
  }

  // Load testing helpers
  async runLoadTest(operation, concurrency = 5, iterations = 10) {
    const results = [];
    const promises = [];

    for (let i = 0; i < concurrency; i++) {
      const promise = (async () => {
        const batchResults = [];
        for (let j = 0; j < iterations; j++) {
          const startTime = Date.now();
          try {
            await operation();
            const endTime = Date.now();
            batchResults.push({
              success: true,
              duration: endTime - startTime,
              iteration: j,
              worker: i
            });
          } catch (error) {
            const endTime = Date.now();
            batchResults.push({
              success: false,
              duration: endTime - startTime,
              error: error.message,
              iteration: j,
              worker: i
            });
          }
        }
        return batchResults;
      })();
      
      promises.push(promise);
    }

    const allResults = await Promise.all(promises);
    return allResults.flat();
  }
}

module.exports = {
  MockServiceManager,
  AnthropicApiMock,
  ZoomApiMock,
  testScenarios,
  zoomTestScenarios
};