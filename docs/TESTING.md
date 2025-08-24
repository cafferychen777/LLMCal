# 🧪 LLMCal Testing Guide

This comprehensive guide covers all aspects of testing the LLMCal PopClip extension, from setup to execution to troubleshooting.

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Test Environment Setup](#test-environment-setup)
- [Test Types](#test-types)
- [Running Tests](#running-tests)
- [Coverage Reports](#coverage-reports)
- [Continuous Integration](#continuous-integration)
- [Writing Tests](#writing-tests)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## 🚀 Quick Start

### Prerequisites

- **macOS**: Required for full integration testing
- **Node.js**: Version 16+ recommended
- **npm**: Version 8+ recommended
- **jq**: For JSON processing in shell tests
- **curl**: For API testing

### Automated Setup

The easiest way to set up the testing environment:

```bash
# Run the automated configuration
npm run test:setup

# Or with verbose output
npm run test:setup:verbose

# Check configuration only
npm run test:setup:check
```

### Manual Setup

If you prefer manual setup:

```bash
# Install dependencies
npm ci

# Create test directories
mkdir -p tests/{unit,integration,e2e,mocks,utils,setup,fixtures}

# Run tests to verify setup
npm test
```

## 🔧 Test Environment Setup

### Directory Structure

```
tests/
├── unit/                    # Unit tests
│   ├── calendar.test.js
│   ├── date_utils.test.js
│   ├── api_client.test.js
│   └── zoom_integration.test.js
├── integration/             # Integration tests
│   ├── popclip_integration.test.js
│   └── calendar_app_integration.test.js
├── e2e/                     # End-to-end tests
│   └── full_flow.test.js
├── mocks/                   # Mock services
│   ├── anthropic-api.js
│   ├── zoom-api.js
│   └── index.js
├── utils/                   # Test utilities
│   ├── test-reporter.js
│   └── notification-service.js
├── setup/                   # Environment setup
│   ├── global-setup.js
│   ├── global-teardown.js
│   └── auto-config.js
└── fixtures/                # Test data
    ├── test-events.json
    └── api-responses.json
```

### Environment Variables

Create a `.env.test` file or set these variables:

```bash
# Required for API testing
POPCLIP_OPTION_ANTHROPIC_API_KEY=test-key

# Optional for Zoom testing
POPCLIP_OPTION_ZOOM_ACCOUNT_ID=test-account
POPCLIP_OPTION_ZOOM_CLIENT_ID=test-client
POPCLIP_OPTION_ZOOM_CLIENT_SECRET=test-secret

# Test configuration
NODE_ENV=test
TEST_MODE=true
FORCE_COLOR=1
```

## 🎯 Test Types

### Unit Tests

Test individual functions and components in isolation:

- **calendar.test.js**: Core calendar processing logic
- **date_utils.test.js**: Date/time utility functions
- **api_client.test.js**: API interaction handling
- **zoom_integration.test.js**: Zoom API integration

### Integration Tests

Test component interactions and workflows:

- **popclip_integration.test.js**: PopClip extension workflow
- **calendar_app_integration.test.js**: macOS Calendar app integration

### End-to-End Tests

Test complete user workflows:

- **full_flow.test.js**: Complete text-to-calendar workflows
- Multi-step scenarios with real API interactions (mocked)

## 🏃 Running Tests

### Basic Commands

```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run in watch mode (development)
npm run test:watch

# Run silently (CI mode)
npm run test:ci
```

### Specific Test Types

```bash
# Unit tests only
npm run test:unit

# Integration tests only
npm run test:integration

# End-to-end tests only
npm run test:e2e

# Verbose output
npm run test:verbose
```

### Individual Test Files

```bash
# Run specific test file
npm test calendar.test.js

# Run specific test suite
npm test -- --testNamePattern="Date Processing"

# Run tests matching pattern
npm test -- --testPathPattern="integration"
```

### Debug Mode

```bash
# Run with Node.js debugging
node --inspect-brk node_modules/.bin/jest --runInBand

# VS Code debugging (F5 with provided launch config)
```

## 📊 Coverage Reports

### Generating Coverage

```bash
# Generate coverage report
npm run test:coverage

# View HTML report
open coverage/lcov-report/index.html
```

### Coverage Requirements

The project maintains these coverage thresholds:

- **Statements**: 70%
- **Branches**: 70%
- **Functions**: 70%
- **Lines**: 70%

### Coverage Files

```
coverage/
├── clover.xml              # Clover format
├── lcov.info              # LCOV format
├── coverage-final.json    # JSON format
├── test-report.html       # Custom HTML report
└── lcov-report/           # HTML coverage report
    └── index.html
```

## 🔄 Continuous Integration

### GitHub Actions

The project includes comprehensive CI workflows:

#### Main Test Workflow (`.github/workflows/test.yml`)

- **Triggers**: Push to main/develop, PRs, daily schedule
- **Matrix**: Multiple macOS versions and Node.js versions
- **Steps**: Install → Lint → Unit Tests → Integration Tests → Coverage
- **Artifacts**: Coverage reports, test results

#### E2E Workflow (`.github/workflows/e2e.yml`)

- **Triggers**: Push to main, PRs, twice daily
- **Tests**: Complete user workflows, integration scenarios
- **Validation**: PopClip extension structure validation

### Local CI Simulation

```bash
# Run tests in CI mode
npm run test:ci

# Simulate GitHub Actions environment
CI=true npm test
```

## ✍️ Writing Tests

### Test Structure

Follow this pattern for test files:

```javascript
describe('Feature Name', () => {
  let mockEnv;
  
  beforeEach(() => {
    // Setup test environment
    mockEnv = global.testHelpers.generateTestEnvironment('test-name');
  });

  afterEach(() => {
    // Cleanup if needed
  });

  describe('Specific Functionality', () => {
    test('should do something specific', async () => {
      // Arrange
      const input = 'test input';
      const expected = 'expected output';
      
      // Act
      const result = await functionUnderTest(input);
      
      // Assert
      expect(result).toBe(expected);
    });
  });
});
```

### Mock Services

Use the built-in mock services for API testing:

```javascript
const { MockServiceManager } = require('../mocks');

beforeAll(async () => {
  mockServices = new MockServiceManager();
  await mockServices.startAll();
});

afterAll(async () => {
  await mockServices.stopAll();
});
```

### Test Utilities

Access global test helpers:

```javascript
// Generate test data
const eventData = global.testHelpers.generateTestEventData('zoom');

// Generate test environment
const testEnv = global.testHelpers.generateTestEnvironment('my-test');

// Wait for conditions
await global.testHelpers.waitForCondition(() => condition, 5000);
```

### Performance Testing

Include performance assertions:

```javascript
test('should complete within performance threshold', async () => {
  const startTime = Date.now();
  
  await performOperation();
  
  const duration = Date.now() - startTime;
  expect(duration).toBeLessThan(5000); // 5 seconds max
});
```

## 🔧 Troubleshooting

### Common Issues

#### Tests Timeout

```bash
# Increase timeout globally
npm test -- --testTimeout=30000

# Or in specific test
test('long running test', async () => {
  // test code
}, 30000); // 30 second timeout
```

#### Mock Services Won't Start

```bash
# Check if ports are in use
lsof -i :3003 -i :3004 -i :3005

# Kill conflicting processes
kill -9 <PID>

# Restart mock services
npm run test:setup:force
```

#### Shell Script Tests Failing

```bash
# Check shell script permissions
chmod +x LLMCal.popclipext/calendar.sh

# Verify shell tools
which jq curl date osascript

# Install missing tools (macOS)
brew install jq
```

#### Coverage Reports Not Generated

```bash
# Clean coverage directory
rm -rf coverage/

# Regenerate with fresh install
npm run test:setup:force
npm run test:coverage
```

### Debug Information

Enable verbose logging:

```bash
# Verbose test output
DEBUG=* npm test

# Jest verbose mode
npm run test:verbose

# Setup with verbose logging
npm run test:setup:verbose
```

### Platform-Specific Issues

#### macOS Specific

```bash
# Grant calendar access (if needed)
# System Preferences → Security & Privacy → Privacy → Calendars

# Check AppleScript availability
osascript -e 'tell application "Calendar" to get name'
```

#### Node.js Version Issues

```bash
# Check Node.js version
node --version

# Use Node Version Manager
nvm use 18
nvm install --lts
```

## 📝 Best Practices

### Test Naming

```javascript
// Good
test('should create calendar event with valid data')
test('should return authentication error for invalid API key')
test('should handle timezone conversion correctly')

// Avoid
test('test event creation')
test('api test')
test('check dates')
```

### Test Organization

- **Group related tests** with `describe` blocks
- **Use descriptive test names** that explain the scenario
- **Keep tests independent** - each test should be able to run alone
- **Test edge cases** and error conditions
- **Include performance tests** for critical paths

### Mock Usage

- **Mock external services** (APIs, file system, notifications)
- **Use real implementations** for core business logic
- **Keep mocks simple** and focused
- **Verify mock interactions** when important

### Assertions

```javascript
// Specific assertions
expect(result.title).toBe('Expected Title');
expect(result.attendees).toHaveLength(3);
expect(response.status).toBe(200);

// Pattern matching
expect(result.start_time).toMatch(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/);

// Object structure
expect(result).toMatchObject({
  title: expect.any(String),
  start_time: expect.stringMatching(/^\d{4}-\d{2}-\d{2}/),
  attendees: expect.arrayContaining(['test@example.com'])
});
```

### Error Testing

```javascript
test('should handle API errors gracefully', async () => {
  // Arrange
  const invalidInput = '';
  
  // Act & Assert
  await expect(processCalendarEvent(invalidInput))
    .rejects
    .toThrow('Invalid input provided');
});
```

### Async Testing

```javascript
// Async/await (preferred)
test('should process async operation', async () => {
  const result = await asyncFunction();
  expect(result).toBeDefined();
});

// Promise resolution
test('should resolve promise', () => {
  return expect(promiseFunction()).resolves.toBe('success');
});

// Promise rejection
test('should reject promise', () => {
  return expect(failingPromise()).rejects.toThrow();
});
```

## 📈 Performance Monitoring

### Benchmarking

```javascript
const { performance } = require('perf_hooks');

test('performance benchmark', async () => {
  const start = performance.now();
  
  await operationUnderTest();
  
  const end = performance.now();
  const duration = end - start;
  
  expect(duration).toBeLessThan(1000); // 1 second
  console.log(`Operation took ${duration.toFixed(2)}ms`);
});
```

### Memory Usage

```javascript
test('memory usage test', async () => {
  const initialMemory = process.memoryUsage().heapUsed;
  
  await memoryIntensiveOperation();
  
  global.gc(); // Force garbage collection if --expose-gc
  const finalMemory = process.memoryUsage().heapUsed;
  const memoryDelta = finalMemory - initialMemory;
  
  expect(memoryDelta).toBeLessThan(50 * 1024 * 1024); // 50MB max
});
```

## 🚨 Test Maintenance

### Regular Tasks

- **Review test coverage** monthly and add tests for uncovered code
- **Update test data** when business logic changes
- **Refactor duplicate test code** into utilities
- **Monitor test performance** and optimize slow tests
- **Update dependencies** regularly

### Quality Metrics

Track these metrics over time:

- **Test coverage percentage** (aim for >70%)
- **Test execution time** (keep under 30 seconds for full suite)
- **Flaky test rate** (should be <1%)
- **Test failure rate** in CI (should be <5%)

---

## 🆘 Getting Help

If you encounter issues not covered in this guide:

1. **Check the FAQ** in this document
2. **Review recent commits** for related changes
3. **Run diagnostics**: `npm run test:setup:check`
4. **Create an issue** with test output and environment details

Happy testing! 🎉