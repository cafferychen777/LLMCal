/**
 * Global test setup for LLMCal
 * Initializes test environment and starts required services
 */

const { MockServiceManager } = require('../mocks');
const fs = require('fs').promises;
const path = require('path');

module.exports = async () => {
  console.log('🚀 Starting LLMCal test environment setup...');
  
  try {
    // Create test directories
    const testDirs = [
      '/tmp/llmcal-test-logs',
      '/tmp/llmcal-test-bundle',
      '/tmp/llmcal-test-cache'
    ];

    for (const dir of testDirs) {
      await fs.mkdir(dir, { recursive: true });
    }

    // Start mock services
    const mockServices = new MockServiceManager();
    await mockServices.startAll();
    
    // Store mock service instance globally for tests
    global.mockServices = mockServices;

    // Setup test environment variables
    process.env.TEST_MODE = 'true';
    process.env.ANTHROPIC_API_BASE = mockServices.getAnthropicEndpoint();
    process.env.ZOOM_OAUTH_URL = mockServices.getZoomOAuthEndpoint();
    process.env.ZOOM_API_BASE = mockServices.getZoomApiEndpoint();

    // Create test bundle files
    await setupTestBundle();
    
    // Setup test logging
    setupTestLogging();

    console.log('✅ Test environment setup completed successfully');
    
  } catch (error) {
    console.error('❌ Failed to setup test environment:', error);
    throw error;
  }
};

async function setupTestBundle() {
  const bundlePath = '/tmp/llmcal-test-bundle';
  
  // Create minimal i18n.json for testing
  const i18nData = {
    en: {
      processing: "Processing...",
      success: "Event added to calendar",
      error: "Failed to add event",
      api_error: "API request failed",
      validation_error: "Event validation failed"
    },
    zh: {
      processing: "处理中...",
      success: "事件已添加到日历",
      error: "添加事件失败",
      api_error: "API请求失败",
      validation_error: "事件验证失败"
    },
    es: {
      processing: "Procesando...",
      success: "Evento agregado al calendario",
      error: "Error al agregar evento",
      api_error: "Error en solicitud de API",
      validation_error: "Error de validación de evento"
    }
  };

  await fs.writeFile(
    path.join(bundlePath, 'i18n.json'),
    JSON.stringify(i18nData, null, 2)
  );

  // Create minimal Config.json for testing
  const configData = {
    name: "LLMCal Test",
    description: "Test configuration for LLMCal",
    identifier: "com.test.llmcal",
    version: "1.0.0-test",
    options: [
      {
        identifier: "anthropic_api_key",
        label: "Anthropic API Key",
        type: "string",
        description: "Your Anthropic API key for Claude"
      },
      {
        identifier: "zoom_account_id",
        label: "Zoom Account ID",
        type: "string",
        description: "Your Zoom Account ID (optional)"
      }
    ]
  };

  await fs.writeFile(
    path.join(bundlePath, 'Config.json'),
    JSON.stringify(configData, null, 2)
  );

  console.log('📁 Test bundle files created');
}

function setupTestLogging() {
  // Override console methods for test environment
  const originalConsoleLog = console.log;
  const originalConsoleError = console.error;
  const originalConsoleWarn = console.warn;

  // Only show setup/teardown messages and errors during testing
  console.log = (...args) => {
    if (args[0] && (args[0].includes('🚀') || args[0].includes('✅') || args[0].includes('❌'))) {
      originalConsoleLog(...args);
    }
  };

  console.error = (...args) => {
    // Always show errors
    originalConsoleError(...args);
  };

  console.warn = (...args) => {
    // Show warnings only in verbose mode
    if (process.env.JEST_VERBOSE === 'true') {
      originalConsoleWarn(...args);
    }
  };

  // Store original methods for restoration
  global.originalConsole = {
    log: originalConsoleLog,
    error: originalConsoleError,
    warn: originalConsoleWarn
  };

  console.log('📝 Test logging configured');
}

// Export helper functions for use in tests
global.testHelpers = {
  generateTestEventData: (type = 'basic') => {
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
        title: 'Zoom Test Meeting',
        start_time: '2024-01-15 14:00',
        end_time: '2024-01-15 15:00',
        description: 'Meeting with Zoom integration',
        location: 'Zoom Meeting',
        url: 'https://zoom.us/j/123456789',
        alerts: [5, 15],
        recurrence: 'none',
        attendees: ['test@example.com']
      },
      recurring: {
        title: 'Weekly Test Standup',
        start_time: '2024-01-15 09:00',
        end_time: '2024-01-15 09:30',
        description: 'Weekly team standup',
        location: 'Office',
        alerts: [15, 30],
        recurrence: 'weekly',
        attendees: ['team@example.com']
      }
    };
    return events[type] || events.basic;
  },

  generateTestEnvironment: (testName) => {
    return {
      POPCLIP_TEXT: `Test event for ${testName}`,
      POPCLIP_OPTION_ANTHROPIC_API_KEY: 'test-api-key-valid',
      POPCLIP_OPTION_ZOOM_ACCOUNT_ID: 'test-account-id',
      POPCLIP_OPTION_ZOOM_CLIENT_ID: 'test-client-id',
      POPCLIP_OPTION_ZOOM_CLIENT_SECRET: 'test-client-secret',
      POPCLIP_OPTION_ZOOM_EMAIL: 'test@example.com',
      POPCLIP_OPTION_ZOOM_NAME: 'Test User',
      POPCLIP_BUNDLE_PATH: '/tmp/llmcal-test-bundle',
      HOME: '/tmp',
      TEST_MODE: 'true'
    };
  },

  sleep: (ms) => new Promise(resolve => setTimeout(resolve, ms)),

  waitForCondition: async (conditionFn, timeout = 5000, interval = 100) => {
    const startTime = Date.now();
    while (Date.now() - startTime < timeout) {
      if (await conditionFn()) {
        return true;
      }
      await global.testHelpers.sleep(interval);
    }
    throw new Error(`Condition not met within ${timeout}ms timeout`);
  }
};