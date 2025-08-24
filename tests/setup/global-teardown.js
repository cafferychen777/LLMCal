/**
 * Global test teardown for LLMCal
 * Cleans up test environment and stops services
 */

const fs = require('fs').promises;

module.exports = async () => {
  console.log('🧹 Starting LLMCal test environment teardown...');
  
  try {
    // Stop mock services
    if (global.mockServices) {
      await global.mockServices.stopAll();
      global.mockServices = null;
    }

    // Restore original console methods
    if (global.originalConsole) {
      console.log = global.originalConsole.log;
      console.error = global.originalConsole.error;
      console.warn = global.originalConsole.warn;
      global.originalConsole = null;
    }

    // Clean up test directories
    const testDirs = [
      '/tmp/llmcal-test-logs',
      '/tmp/llmcal-test-bundle',
      '/tmp/llmcal-test-cache'
    ];

    for (const dir of testDirs) {
      try {
        await fs.rm(dir, { recursive: true, force: true });
      } catch (error) {
        // Ignore cleanup errors
        console.warn(`Warning: Could not clean up ${dir}:`, error.message);
      }
    }

    // Clean up global test variables
    delete process.env.TEST_MODE;
    delete process.env.ANTHROPIC_API_BASE;
    delete process.env.ZOOM_OAUTH_URL;
    delete process.env.ZOOM_API_BASE;

    // Clean up global helpers
    global.testHelpers = null;

    console.log('✅ Test environment teardown completed successfully');
    
  } catch (error) {
    console.error('❌ Failed to teardown test environment:', error);
    // Don't throw error in teardown to avoid masking test failures
  }
};

// Emergency cleanup function for unexpected shutdowns
process.on('SIGINT', async () => {
  console.log('\n🛑 Received SIGINT, performing emergency cleanup...');
  await module.exports();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n🛑 Received SIGTERM, performing emergency cleanup...');
  await module.exports();
  process.exit(0);
});

process.on('uncaughtException', async (error) => {
  console.error('🚨 Uncaught exception during test teardown:', error);
  await module.exports();
  process.exit(1);
});

process.on('unhandledRejection', async (reason, promise) => {
  console.error('🚨 Unhandled rejection during test teardown:', reason);
  await module.exports();
  process.exit(1);
});