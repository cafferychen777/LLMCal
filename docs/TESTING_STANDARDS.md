# 📏 LLMCal Testing Standards

This document establishes the testing standards, conventions, and best practices for the LLMCal project to ensure consistent, maintainable, and effective testing across the entire codebase.

## 📋 Table of Contents

- [Testing Philosophy](#testing-philosophy)
- [Test Organization](#test-organization)
- [Naming Conventions](#naming-conventions)
- [Code Standards](#code-standards)
- [Coverage Requirements](#coverage-requirements)
- [Performance Standards](#performance-standards)
- [Documentation Standards](#documentation-standards)
- [Review Process](#review-process)
- [Quality Gates](#quality-gates)

---

## 🎯 Testing Philosophy

### Core Principles

1. **Test-Driven Mindset**: Write tests that focus on behavior and outcomes, not implementation details
2. **Fail Fast**: Tests should fail quickly and provide clear error messages
3. **Isolation**: Each test should be independent and not rely on other tests
4. **Repeatability**: Tests must produce consistent results across different environments
5. **Maintainability**: Tests should be easy to read, understand, and modify

### Testing Pyramid

```
        /\
       /  \
      / E2E \ (10%)
     /______\
    /        \
   / INTEGR.  \ (20%)
  /____________\
 /              \
/      UNIT      \ (70%)
\________________/
```

- **Unit Tests (70%)**: Fast, isolated tests of individual functions
- **Integration Tests (20%)**: Component interaction and workflow testing
- **E2E Tests (10%)**: Complete user scenario validation

### Test Categories

| Category | Purpose | Tools | Environment |
|----------|---------|--------|-------------|
| Unit | Individual function testing | Jest | Node.js |
| Integration | Component interaction | Jest + Mocks | Node.js + Mock Services |
| E2E | Complete workflows | Jest + Real APIs (mocked) | Full Environment |
| Performance | Speed and resource usage | Jest + Performance APIs | Production-like |
| Security | Vulnerability testing | Custom tools | Isolated |

---

## 📁 Test Organization

### Directory Structure Standard

```
tests/
├── unit/                           # Unit tests (70% of test suite)
│   ├── calendar.test.js           # Core calendar functionality
│   ├── date_utils.test.js         # Date/time utilities
│   ├── api_client.test.js         # API interaction layer
│   └── zoom_integration.test.js   # Zoom-specific functionality
├── integration/                    # Integration tests (20% of test suite)
│   ├── popclip_integration.test.js # PopClip workflow integration
│   └── calendar_app_integration.test.js # macOS Calendar integration
├── e2e/                           # End-to-end tests (10% of test suite)
│   └── full_flow.test.js          # Complete user workflows
├── mocks/                         # Mock services and data
│   ├── anthropic-api.js           # Anthropic API mock
│   ├── zoom-api.js                # Zoom API mock
│   └── index.js                   # Mock orchestrator
├── utils/                         # Test utilities
│   ├── test-reporter.js           # Custom test reporting
│   └── notification-service.js    # Test notifications
├── setup/                         # Test environment setup
│   ├── global-setup.js            # Global test initialization
│   ├── global-teardown.js         # Global test cleanup
│   └── auto-config.js             # Automated test configuration
└── fixtures/                      # Test data and fixtures
    ├── test-events.json           # Sample event data
    └── api-responses.json         # Sample API responses
```

### File Organization Rules

1. **One test file per source file** for unit tests
2. **Group related functionality** in integration tests
3. **Separate E2E tests by user journey**
4. **Mock services in dedicated directory**
5. **Shared utilities in utils directory**

---

## 📝 Naming Conventions

### Test File Names

| Pattern | Example | Purpose |
|---------|---------|---------|
| `[module].test.js` | `calendar.test.js` | Unit tests for specific module |
| `[feature]_integration.test.js` | `popclip_integration.test.js` | Integration tests for feature |
| `[workflow].test.js` | `full_flow.test.js` | End-to-end workflow tests |

### Test Suite Names

```javascript
// ✅ Good: Clear hierarchy and scope
describe('Calendar Processing', () => {
  describe('Event Creation', () => {
    describe('with valid data', () => {
      test('should create event with all required fields', () => {
        // test implementation
      });
    });
  });
});

// ❌ Bad: Unclear scope
describe('Tests', () => {
  test('test1', () => {
    // test implementation
  });
});
```

### Test Names

Follow the pattern: `should [expected behavior] when [condition]`

```javascript
// ✅ Good: Descriptive and specific
test('should create calendar event when provided valid event data')
test('should return authentication error when API key is invalid')
test('should generate ISO timestamp when converting local datetime')

// ❌ Bad: Vague or implementation-focused
test('creates event')
test('API test')
test('check date conversion')
```

### Variable Names

```javascript
// ✅ Good: Clear and descriptive
const mockEventData = { title: 'Test Meeting' };
const expectedApiResponse = { success: true };
const invalidApiKey = 'invalid-key-123';

// ❌ Bad: Unclear or abbreviated
const data = {};
const resp = {};
const key = 'invalid';
```

---

## 🔧 Code Standards

### Test Structure

Use the **AAA Pattern** (Arrange, Act, Assert):

```javascript
test('should calculate meeting duration correctly', () => {
  // Arrange
  const startTime = '2024-01-15 14:00:00';
  const endTime = '2024-01-15 16:30:00';
  const expectedDuration = 150; // minutes

  // Act
  const actualDuration = calculateDuration(startTime, endTime);

  // Assert
  expect(actualDuration).toBe(expectedDuration);
});
```

### Setup and Teardown

```javascript
describe('API Client', () => {
  let mockServer;
  let testEnvironment;

  // Setup before all tests in suite
  beforeAll(async () => {
    mockServer = new MockApiServer();
    await mockServer.start();
  });

  // Cleanup after all tests in suite
  afterAll(async () => {
    await mockServer.stop();
  });

  // Setup before each test
  beforeEach(() => {
    testEnvironment = createTestEnvironment();
    jest.clearAllMocks();
  });

  // Cleanup after each test
  afterEach(() => {
    cleanupTestEnvironment(testEnvironment);
  });
});
```

### Assertion Standards

#### Specific Assertions

```javascript
// ✅ Good: Specific and meaningful
expect(event.title).toBe('Team Meeting');
expect(event.attendees).toHaveLength(3);
expect(event.start_time).toMatch(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/);

// ❌ Bad: Too generic
expect(event).toBeTruthy();
expect(event.title).toBeDefined();
```

#### Object Matching

```javascript
// ✅ Good: Partial object matching
expect(createdEvent).toMatchObject({
  title: expect.any(String),
  start_time: expect.stringMatching(/^\d{4}-\d{2}-\d{2}/),
  attendees: expect.arrayContaining(['test@example.com'])
});

// ❌ Bad: Brittle exact matching
expect(createdEvent).toEqual({
  title: 'Meeting',
  start_time: '2024-01-15 15:00:00',
  // ... all properties must match exactly
});
```

#### Error Testing

```javascript
// ✅ Good: Specific error testing
await expect(processInvalidEvent(invalidData))
  .rejects
  .toThrow('Invalid event data: missing required field "title"');

// ❌ Bad: Generic error testing
await expect(processInvalidEvent(invalidData)).rejects.toThrow();
```

### Mock Standards

#### Mock External Dependencies

```javascript
// ✅ Good: Mock external services
jest.mock('../../services/anthropic-client', () => ({
  sendRequest: jest.fn().mockResolvedValue(mockApiResponse)
}));

// ❌ Bad: Testing real external services in unit tests
// (This belongs in integration tests)
```

#### Mock Functions

```javascript
// ✅ Good: Clear mock setup
const mockNotificationService = {
  notify: jest.fn(),
  isEnabled: jest.fn().mockReturnValue(true)
};

beforeEach(() => {
  jest.clearAllMocks();
});

// ❌ Bad: Unclear mock state
const mockService = jest.fn();
```

### Async Testing Standards

```javascript
// ✅ Good: Proper async/await usage
test('should process async operation', async () => {
  const result = await processAsyncOperation();
  expect(result).toBeDefined();
});

// ✅ Good: Promise rejection testing
test('should handle async errors', async () => {
  await expect(failingAsyncOperation()).rejects.toThrow('Expected error');
});

// ❌ Bad: Missing await or return
test('async operation', () => {
  processAsyncOperation(); // Missing await
  expect(result).toBeDefined(); // Will execute before async completes
});
```

---

## 📊 Coverage Requirements

### Minimum Coverage Thresholds

| Metric | Minimum | Target | Excellent |
|--------|---------|--------|-----------|
| Statements | 70% | 80% | 90%+ |
| Branches | 70% | 80% | 90%+ |
| Functions | 70% | 85% | 95%+ |
| Lines | 70% | 80% | 90%+ |

### Coverage Configuration

```javascript
// jest.config.js
module.exports = {
  collectCoverage: false, // Enabled with --coverage flag
  collectCoverageFrom: [
    'LLMCal.popclipext/**/*.{js,sh}',
    'tests/**/*.js',
    '!tests/mocks/**',
    '!**/*.test.js'
  ],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70
    }
  }
};
```

### Coverage Exceptions

Some areas may have lower coverage due to technical constraints:

1. **AppleScript execution** (Cannot be tested in CI)
2. **System integration** (Requires specific macOS setup)
3. **Error recovery paths** (Difficult to simulate reliably)

Document exceptions with reasoning:

```javascript
/* istanbul ignore next: AppleScript execution cannot be tested in CI */
function executeAppleScript(script) {
  return exec(`osascript -e "${script}"`);
}
```

### Coverage Reporting

```bash
# Generate coverage reports
npm run test:coverage

# View HTML report
open coverage/lcov-report/index.html

# Check coverage thresholds
npm run test:ci
```

---

## ⚡ Performance Standards

### Test Execution Time Targets

| Test Type | Individual Test | Test Suite | CI Target |
|-----------|----------------|------------|-----------|
| Unit | <100ms | <10s | <15s |
| Integration | <5s | <20s | <30s |
| E2E | <30s | <60s | <90s |
| **Total** | - | <45s | <60s |

### Performance Testing

```javascript
test('performance benchmark: event processing', async () => {
  const startTime = performance.now();
  
  await processMultipleEvents(testEvents);
  
  const endTime = performance.now();
  const duration = endTime - startTime;
  
  expect(duration).toBeLessThan(1000); // 1 second max
  
  // Log for performance tracking
  console.log(`Event processing took ${duration.toFixed(2)}ms`);
});
```

### Memory Testing

```javascript
test('memory usage: should not leak memory', async () => {
  const initialMemory = process.memoryUsage().heapUsed;
  
  // Perform memory-intensive operations
  for (let i = 0; i < 100; i++) {
    await processLargeEvent(largeTestData);
  }
  
  // Force garbage collection (with --expose-gc)
  if (global.gc) {
    global.gc();
  }
  
  const finalMemory = process.memoryUsage().heapUsed;
  const memoryGrowth = finalMemory - initialMemory;
  
  // Memory growth should be reasonable (less than 50MB)
  expect(memoryGrowth).toBeLessThan(50 * 1024 * 1024);
});
```

### Performance Monitoring

Track performance trends in CI:

```javascript
// Store performance metrics
const performanceMetrics = {
  timestamp: new Date().toISOString(),
  testSuite: 'unit',
  duration: testDuration,
  memoryUsage: process.memoryUsage(),
  nodeVersion: process.version
};
```

---

## 📚 Documentation Standards

### Test Documentation Requirements

Each test file must include:

```javascript
/**
 * Unit tests for calendar.sh functions
 * Testing main calendar processing and AppleScript generation
 * 
 * Coverage:
 * - Event creation workflow
 * - Date/time processing
 * - API response handling
 * - Error scenarios
 * 
 * Dependencies:
 * - Mock Anthropic API
 * - Mock file system
 * - Test fixtures
 */

describe('Calendar Processing', () => {
  // tests here
});
```

### Inline Documentation

```javascript
test('should convert datetime format for AppleScript', () => {
  // This test ensures datetime strings are properly formatted
  // for AppleScript consumption. AppleScript requires specific
  // component extraction (year, month, day, hour, minute)
  
  const input = '2024-01-15 15:30:00';
  const result = parseForAppleScript(input);
  
  expect(result).toMatchObject({
    year: 2024,
    month: 1,
    day: 15,
    hour: 15,
    minute: 30
  });
});
```

### Test Case Documentation

```javascript
/**
 * Test Case: Authentication Error Handling
 * 
 * Scenario: User provides invalid API key
 * Given: Invalid Anthropic API key
 * When: Making API request
 * Then: Should return authentication error
 * And: Should not crash the application
 * 
 * Business Value: Graceful error handling improves user experience
 * Risk Level: High (affects core functionality)
 */
test('should handle authentication error gracefully', async () => {
  // test implementation
});
```

---

## 🔍 Review Process

### Test Code Review Checklist

#### Functionality
- [ ] Tests cover the stated requirements
- [ ] Edge cases and error conditions are tested
- [ ] Tests are independent and isolated
- [ ] Setup and teardown are properly implemented

#### Code Quality
- [ ] Test names clearly describe the scenario
- [ ] AAA pattern is followed (Arrange, Act, Assert)
- [ ] Assertions are specific and meaningful
- [ ] No duplicate test logic

#### Performance
- [ ] Tests complete within time limits
- [ ] No unnecessary delays or waits
- [ ] Mocks are used appropriately for external dependencies

#### Documentation
- [ ] Test purpose is clear
- [ ] Complex logic is commented
- [ ] Test data is self-explanatory

### Review Process Steps

1. **Automated Checks**: CI runs linting, formatting, and basic tests
2. **Peer Review**: Another developer reviews test logic and coverage
3. **Integration Testing**: Tests run in CI environment
4. **Performance Review**: Execution times and resource usage checked
5. **Documentation Review**: Test documentation and comments verified

---

## 🚪 Quality Gates

### Pre-commit Gates

Before code can be committed:

```bash
# Run pre-commit hooks
npm run lint
npm run test:unit
npm run test:integration
```

### Pull Request Gates

Before code can be merged:

1. **All tests pass** in CI environment
2. **Coverage thresholds** are maintained or improved  
3. **No new security vulnerabilities** detected
4. **Performance benchmarks** are met
5. **Code review** approval received

### Release Gates

Before releasing new versions:

1. **Full test suite** passes (unit + integration + E2E)
2. **Security scan** passes
3. **Performance regression tests** pass
4. **Manual smoke testing** on target environment completed

### Continuous Monitoring

Monitor these metrics continuously:

```javascript
const qualityMetrics = {
  testPassRate: '> 95%',
  averageTestDuration: '< 30s',
  flakeRate: '< 1%',
  coverageThreshold: '> 70%',
  securityIssues: '0 critical, < 5 medium'
};
```

### Quality Dashboard

Track quality metrics over time:

- **Test execution trends** (duration, pass rate)
- **Coverage evolution** (by module, over time)
- **Flaky test identification** (most unstable tests)
- **Performance regression** (execution time trends)

---

## 🔧 Tool Configuration

### Jest Configuration Standards

```javascript
module.exports = {
  // Test environment
  testEnvironment: 'node',
  
  // Test patterns
  testMatch: [
    '**/tests/**/*.test.js'
  ],
  
  // Setup and teardown
  globalSetup: './tests/setup/global-setup.js',
  globalTeardown: './tests/setup/global-teardown.js',
  setupFiles: ['./jest.setup.js'],
  
  // Performance
  testTimeout: 10000, // 10 seconds
  maxWorkers: '50%',
  
  // Coverage
  collectCoverageFrom: [
    'LLMCal.popclipext/**/*.{js,sh}',
    '!**/*.test.js'
  ],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70
    }
  },
  
  // Reporting
  reporters: [
    'default',
    ['jest-html-reporter', {
      pageTitle: 'LLMCal Test Report',
      outputPath: 'coverage/test-report.html'
    }]
  ]
};
```

### ESLint Configuration for Tests

```javascript
// .eslintrc.js
module.exports = {
  env: {
    node: true,
    jest: true
  },
  overrides: [
    {
      files: ['**/*.test.js'],
      rules: {
        // Relaxed rules for test files
        'max-lines-per-function': 'off',
        'no-magic-numbers': 'off',
        'prefer-const': 'error'
      }
    }
  ]
};
```

---

## 📈 Metrics and KPIs

### Testing KPIs

| KPI | Target | Measurement |
|-----|--------|-------------|
| Test Coverage | >70% | Lines covered / Total lines |
| Test Execution Time | <45s | Full test suite duration |
| Flaky Test Rate | <1% | Failed tests / Total test runs |
| Defect Escape Rate | <5% | Production bugs / Total features |
| Test Automation Rate | >90% | Automated tests / Total test cases |

### Quality Trends

Monitor monthly:

- **Coverage trend** (improving/declining)
- **Test suite growth** (tests added vs. features added)
- **Performance trends** (execution time over time)
- **Failure patterns** (most common failure types)

---

## 🚀 Continuous Improvement

### Regular Reviews

#### Weekly
- Review flaky tests and fix root causes
- Monitor test execution performance
- Update test data as needed

#### Monthly
- Analyze coverage reports and identify gaps
- Review and refactor duplicate test code
- Update test documentation

#### Quarterly
- Full testing strategy review
- Tool and framework evaluation
- Performance benchmark updates
- Testing standard updates

### Innovation Areas

Explore these areas for testing improvements:

1. **Visual regression testing** for UI components
2. **Property-based testing** for complex business logic
3. **Mutation testing** for test quality validation
4. **AI-assisted test generation** for edge cases
5. **Contract testing** for API integrations

---

## 📖 References and Resources

### Testing Resources

- [Jest Documentation](https://jestjs.io/)
- [Testing Best Practices](https://github.com/goldbergyoni/javascript-testing-best-practices)
- [Test Pyramid Concepts](https://martinfowler.com/articles/practical-test-pyramid.html)

### Project-Specific Resources

- [Testing Guide](./TESTING.md) - Comprehensive testing guide
- [Test Cases](./TEST_CASES.md) - Detailed test case documentation
- [CI/CD Documentation](./.github/workflows/) - Automated testing workflows

---

This testing standards document establishes the foundation for high-quality, maintainable testing in the LLMCal project. Following these standards ensures consistent test quality, reliable CI/CD pipelines, and confidence in the application's reliability and maintainability.