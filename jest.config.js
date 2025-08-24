module.exports = {
  testEnvironment: 'node',
  transform: {
    '^.+\\.js$': ['babel-jest', { configFile: './.babelrc' }]
  },
  transformIgnorePatterns: [
    '/node_modules/',
  ],
  setupFiles: ['./jest.setup.js'],
  
  // Coverage configuration
  collectCoverage: false, // Set to true by --coverage flag
  collectCoverageFrom: [
    'LLMCal.popclipext/**/*.{js,sh}',
    'tests/**/*.js',
    '!tests/mocks/**',
    '!**/node_modules/**',
    '!**/*.test.js',
    '!jest.config.js',
    '!jest.setup.js'
  ],
  coverageDirectory: 'coverage',
  coverageReporters: [
    'text',
    'text-summary',
    'html',
    'lcov',
    'clover',
    'json'
  ],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70
    }
  },
  
  // Test patterns and locations
  testMatch: [
    '**/tests/**/*.test.js',
    '**/__tests__/**/*.js'
  ],
  
  // Test timeout (10 seconds for integration tests)
  testTimeout: 10000,
  
  // Verbose output for CI
  verbose: process.env.CI === 'true',
  
  // HTML reporting
  reporters: [
    'default',
    [
      'jest-html-reporter',
      {
        pageTitle: 'LLMCal Test Report',
        outputPath: 'coverage/test-report.html',
        includeFailureMsg: true,
        includeSuiteFailure: true
      }
    ]
  ],
  
  // Test organization
  testPathIgnorePatterns: [
    '/node_modules/',
    '/coverage/',
    '/dist/'
  ],
  
  // Mock settings
  clearMocks: true,
  restoreMocks: true,
  
  // Performance
  maxWorkers: '50%',
  
  // Error handling
  bail: 0, // Continue running tests after failures
  
  // Global test setup
  globalSetup: './tests/setup/global-setup.js',
  globalTeardown: './tests/setup/global-teardown.js'
}; 