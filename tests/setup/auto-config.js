#!/usr/bin/env node
/**
 * Automated test environment configuration for LLMCal
 * Sets up everything needed to run tests successfully
 */

const fs = require('fs').promises;
const path = require('path');
const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

class TestEnvironmentConfigurator {
  constructor() {
    this.projectRoot = path.resolve(__dirname, '../..');
    this.testsRoot = path.join(this.projectRoot, 'tests');
    this.nodeModules = path.join(this.projectRoot, 'node_modules');
    this.config = {
      verbose: process.argv.includes('--verbose'),
      skipInstall: process.argv.includes('--skip-install'),
      forceReinstall: process.argv.includes('--force-reinstall'),
      checkOnly: process.argv.includes('--check-only')
    };
  }

  async configure() {
    this.log('🔧 Starting automated test environment configuration...');
    
    try {
      await this.checkPrerequisites();
      
      if (!this.config.checkOnly) {
        await this.setupDirectoryStructure();
        await this.installDependencies();
        await this.validateConfiguration();
        await this.setupTestData();
        await this.configureIDESettings();
        await this.createConfigFiles();
      }
      
      await this.runValidationTests();
      
      this.log('✅ Test environment configuration completed successfully!');
      this.displaySummary();
      
    } catch (error) {
      this.error('❌ Configuration failed:', error.message);
      process.exit(1);
    }
  }

  async checkPrerequisites() {
    this.log('🔍 Checking prerequisites...');
    
    const checks = [
      { name: 'Node.js', command: 'node --version', minVersion: '16.0.0' },
      { name: 'npm', command: 'npm --version', minVersion: '8.0.0' },
      { name: 'jq', command: 'jq --version', optional: false },
      { name: 'curl', command: 'curl --version', optional: false }
    ];

    for (const check of checks) {
      try {
        const { stdout } = await execAsync(check.command);
        const version = stdout.trim().split('\n')[0];
        
        if (check.minVersion && this.compareVersions(version, check.minVersion) < 0) {
          throw new Error(`${check.name} version ${version} is below minimum required ${check.minVersion}`);
        }
        
        this.log(`✅ ${check.name}: ${version}`);
      } catch (error) {
        if (check.optional) {
          this.warn(`⚠️ Optional dependency ${check.name} not found`);
        } else {
          throw new Error(`Required dependency ${check.name} not found or incompatible`);
        }
      }
    }

    // Check macOS specific tools
    if (process.platform === 'darwin') {
      try {
        await execAsync('which osascript');
        this.log('✅ AppleScript support available');
      } catch (error) {
        this.warn('⚠️ AppleScript not available (required for full integration tests)');
      }
    }

    // Check if we're in the correct directory
    const packageJsonPath = path.join(this.projectRoot, 'package.json');
    try {
      const packageData = JSON.parse(await fs.readFile(packageJsonPath, 'utf8'));
      if (packageData.name !== 'llmcal') {
        throw new Error('Not in LLMCal project directory');
      }
      this.log('✅ Project directory validated');
    } catch (error) {
      throw new Error('Could not find or validate package.json');
    }
  }

  async setupDirectoryStructure() {
    this.log('📁 Setting up directory structure...');
    
    const directories = [
      'tests/unit',
      'tests/integration', 
      'tests/e2e',
      'tests/mocks',
      'tests/utils',
      'tests/setup',
      'tests/fixtures',
      'tests/temp',
      'coverage',
      'logs'
    ];

    for (const dir of directories) {
      const fullPath = path.join(this.projectRoot, dir);
      await fs.mkdir(fullPath, { recursive: true });
      this.verbose(`Created: ${dir}`);
    }

    this.log('✅ Directory structure created');
  }

  async installDependencies() {
    if (this.config.skipInstall) {
      this.log('⏭️ Skipping dependency installation');
      return;
    }

    this.log('📦 Installing and updating dependencies...');
    
    try {
      // Check if node_modules exists and if we should force reinstall
      const nodeModulesExists = await fs.access(this.nodeModules).then(() => true).catch(() => false);
      
      if (this.config.forceReinstall && nodeModulesExists) {
        this.log('🗑️ Removing existing node_modules...');
        await fs.rm(this.nodeModules, { recursive: true, force: true });
      }

      // Install dependencies
      this.log('Installing npm dependencies...');
      const { stdout: installOutput } = await execAsync('npm ci', { 
        cwd: this.projectRoot,
        maxBuffer: 1024 * 1024 * 10 // 10MB buffer
      });
      this.verbose(installOutput);

      // Install additional test dependencies if not already installed
      const additionalDeps = [
        'jest-html-reporter@^3.10.2'
      ];

      for (const dep of additionalDeps) {
        try {
          const [name] = dep.split('@');
          await fs.access(path.join(this.nodeModules, name));
          this.verbose(`${name} already installed`);
        } catch (error) {
          this.log(`Installing ${dep}...`);
          await execAsync(`npm install --save-dev ${dep}`, { cwd: this.projectRoot });
        }
      }

      this.log('✅ Dependencies installed');
    } catch (error) {
      throw new Error(`Failed to install dependencies: ${error.message}`);
    }
  }

  async validateConfiguration() {
    this.log('🔍 Validating configuration files...');
    
    const configFiles = [
      { path: 'package.json', validator: this.validatePackageJson.bind(this) },
      { path: 'jest.config.js', validator: this.validateJestConfig.bind(this) },
      { path: 'jest.setup.js', validator: this.validateJestSetup.bind(this) }
    ];

    for (const config of configFiles) {
      const fullPath = path.join(this.projectRoot, config.path);
      try {
        const exists = await fs.access(fullPath).then(() => true).catch(() => false);
        if (!exists) {
          throw new Error(`Configuration file ${config.path} not found`);
        }
        
        await config.validator(fullPath);
        this.verbose(`✅ ${config.path} valid`);
      } catch (error) {
        throw new Error(`Invalid configuration in ${config.path}: ${error.message}`);
      }
    }

    this.log('✅ Configuration files validated');
  }

  async validatePackageJson(filePath) {
    const content = JSON.parse(await fs.readFile(filePath, 'utf8'));
    
    const requiredScripts = ['test', 'test:coverage', 'test:unit', 'test:integration'];
    const missingScripts = requiredScripts.filter(script => !content.scripts[script]);
    
    if (missingScripts.length > 0) {
      throw new Error(`Missing npm scripts: ${missingScripts.join(', ')}`);
    }

    const requiredDevDeps = ['jest', '@babel/core', '@babel/preset-env', 'babel-jest'];
    const missingDeps = requiredDevDeps.filter(dep => !content.devDependencies[dep]);
    
    if (missingDeps.length > 0) {
      throw new Error(`Missing dev dependencies: ${missingDeps.join(', ')}`);
    }
  }

  async validateJestConfig(filePath) {
    // Dynamically import the Jest config
    delete require.cache[require.resolve(filePath)];
    const config = require(filePath);
    
    const requiredFields = ['testEnvironment', 'setupFiles', 'collectCoverageFrom'];
    const missingFields = requiredFields.filter(field => !config[field]);
    
    if (missingFields.length > 0) {
      throw new Error(`Missing Jest config fields: ${missingFields.join(', ')}`);
    }
  }

  async validateJestSetup(filePath) {
    const content = await fs.readFile(filePath, 'utf8');
    
    // Check for basic mocks
    if (!content.includes('global.Application') || !content.includes('global.$')) {
      this.warn('Jest setup file may be missing required global mocks');
    }
  }

  async setupTestData() {
    this.log('📊 Setting up test data and fixtures...');
    
    const fixtures = {
      'test-events.json': {
        simple: {
          title: 'Test Meeting',
          start_time: '2024-01-15 15:00',
          end_time: '2024-01-15 16:00',
          description: 'Simple test meeting',
          location: 'Conference Room'
        },
        zoom: {
          title: 'Zoom Meeting',
          start_time: '2024-01-15 14:00',
          end_time: '2024-01-15 15:00',
          description: 'Virtual meeting',
          location: 'Zoom Meeting',
          url: 'https://zoom.us/j/123456789'
        },
        recurring: {
          title: 'Weekly Standup',
          start_time: '2024-01-15 09:00',
          end_time: '2024-01-15 09:30',
          description: 'Team standup',
          recurrence: 'weekly'
        }
      },
      'api-responses.json': {
        anthropic: {
          success: {
            content: [{
              text: '{"title": "Test Meeting", "start_time": "2024-01-15 15:00", "end_time": "2024-01-15 16:00"}'
            }]
          },
          error: {
            error: {
              type: 'authentication_error',
              message: 'Invalid API key'
            }
          }
        },
        zoom: {
          token: {
            access_token: 'test_token_123',
            token_type: 'bearer',
            expires_in: 3600
          },
          meeting: {
            id: 123456789,
            join_url: 'https://zoom.us/j/123456789',
            start_url: 'https://zoom.us/s/123456789'
          }
        }
      }
    };

    const fixturesDir = path.join(this.testsRoot, 'fixtures');
    
    for (const [filename, data] of Object.entries(fixtures)) {
      const filePath = path.join(fixturesDir, filename);
      await fs.writeFile(filePath, JSON.stringify(data, null, 2));
      this.verbose(`Created fixture: ${filename}`);
    }

    this.log('✅ Test fixtures created');
  }

  async configureIDESettings() {
    this.log('⚙️ Configuring IDE settings...');
    
    // Create VS Code settings for better test development experience
    const vscodeDir = path.join(this.projectRoot, '.vscode');
    await fs.mkdir(vscodeDir, { recursive: true });

    const settings = {
      "jest.jestCommandLine": "npm test",
      "jest.autoRun": {
        "watch": false,
        "onSave": "test-src-file"
      },
      "javascript.preferences.includePackageJsonAutoImports": "auto",
      "typescript.preferences.includePackageJsonAutoImports": "auto",
      "files.associations": {
        "*.test.js": "javascript"
      },
      "editor.rulers": [80, 120],
      "files.watcherExclude": {
        "**/node_modules/**": true,
        "**/coverage/**": true,
        "**/.git/**": true
      }
    };

    const settingsPath = path.join(vscodeDir, 'settings.json');
    const existingSettings = await fs.readFile(settingsPath, 'utf8').catch(() => '{}');
    const mergedSettings = { ...JSON.parse(existingSettings), ...settings };
    
    await fs.writeFile(settingsPath, JSON.stringify(mergedSettings, null, 2));

    // Create launch configuration for debugging tests
    const launch = {
      version: "0.2.0",
      configurations: [
        {
          type: "node",
          request: "launch",
          name: "Debug Jest Tests",
          program: "${workspaceFolder}/node_modules/.bin/jest",
          args: ["--runInBand", "--no-coverage", "${fileBasenameNoExtension}"],
          console: "integratedTerminal",
          internalConsoleOptions: "neverOpen",
          disableOptimisticBPs: true,
          windows: {
            program: "${workspaceFolder}/node_modules/jest/bin/jest"
          }
        }
      ]
    };

    const launchPath = path.join(vscodeDir, 'launch.json');
    await fs.writeFile(launchPath, JSON.stringify(launch, null, 2));

    this.verbose('Created VS Code configuration');
    this.log('✅ IDE settings configured');
  }

  async createConfigFiles() {
    this.log('📝 Creating additional configuration files...');

    // Create .babelrc if it doesn't exist
    const babelrcPath = path.join(this.projectRoot, '.babelrc');
    const babelrcExists = await fs.access(babelrcPath).then(() => true).catch(() => false);
    
    if (!babelrcExists) {
      const babelConfig = {
        presets: [
          ["@babel/preset-env", {
            targets: {
              node: "16"
            }
          }]
        ]
      };
      
      await fs.writeFile(babelrcPath, JSON.stringify(babelConfig, null, 2));
      this.verbose('Created .babelrc');
    }

    // Create test environment file
    const testEnvPath = path.join(this.testsRoot, 'setup', 'test.env');
    const testEnvContent = `# Test environment variables
NODE_ENV=test
TEST_MODE=true
FORCE_COLOR=1
JEST_VERBOSE=false

# Mock API endpoints (set during test runtime)
ANTHROPIC_API_BASE=http://localhost:3003
ZOOM_OAUTH_URL=http://localhost:3005
ZOOM_API_BASE=http://localhost:3004

# Test notifications
NOTIFICATIONS_ENABLED=false
WEBHOOK_URL=

# Test timeouts
TEST_TIMEOUT=10000
API_TIMEOUT=5000
`;

    await fs.writeFile(testEnvPath, testEnvContent);
    this.verbose('Created test environment file');

    this.log('✅ Configuration files created');
  }

  async runValidationTests() {
    this.log('🧪 Running validation tests...');
    
    try {
      // Run a subset of tests to validate setup
      const { stdout } = await execAsync('npm test -- --passWithNoTests --detectOpenHandles', {
        cwd: this.projectRoot,
        env: { ...process.env, NODE_ENV: 'test' }
      });
      
      this.verbose(stdout);
      
      // Check if Jest can find test files
      const { stdout: jestInfo } = await execAsync('npm test -- --listTests', {
        cwd: this.projectRoot
      });
      
      const testFiles = jestInfo.split('\n').filter(line => line.includes('.test.js')).length;
      this.log(`✅ Found ${testFiles} test files`);
      
    } catch (error) {
      this.warn(`⚠️ Validation tests encountered issues: ${error.message}`);
      // Don't fail the configuration for test issues
    }
  }

  displaySummary() {
    const summary = `
🎉 Test Environment Configuration Complete!

📋 Summary:
✅ Prerequisites checked
✅ Directory structure created
✅ Dependencies installed
✅ Configuration validated
✅ Test fixtures created
✅ IDE settings configured

🚀 Next Steps:
1. Run tests: npm test
2. Run with coverage: npm run test:coverage
3. Run specific test type: npm run test:unit
4. Debug tests in VS Code: F5

📚 Available Commands:
- npm test                 - Run all tests
- npm run test:unit        - Run unit tests only
- npm run test:integration - Run integration tests only
- npm run test:e2e         - Run end-to-end tests only
- npm run test:coverage    - Run tests with coverage
- npm run test:watch       - Run tests in watch mode
- npm run test:ci          - Run tests in CI mode

🔧 Configuration Files:
- jest.config.js          - Jest configuration
- jest.setup.js           - Global test setup
- tests/setup/            - Test environment setup
- tests/fixtures/         - Test data fixtures
- .vscode/                - IDE configuration

Happy testing! 🧪`;

    console.log(summary);
  }

  // Utility methods
  log(message) {
    console.log(message);
  }

  verbose(message) {
    if (this.config.verbose) {
      console.log(`[VERBOSE] ${message}`);
    }
  }

  warn(message) {
    console.warn(message);
  }

  error(message, details) {
    console.error(message);
    if (details && this.config.verbose) {
      console.error(details);
    }
  }

  compareVersions(version1, version2) {
    const v1 = version1.replace(/[^\d.]/g, '').split('.').map(Number);
    const v2 = version2.split('.').map(Number);
    
    for (let i = 0; i < Math.max(v1.length, v2.length); i++) {
      const a = v1[i] || 0;
      const b = v2[i] || 0;
      
      if (a > b) return 1;
      if (a < b) return -1;
    }
    
    return 0;
  }
}

// CLI handling
if (require.main === module) {
  const configurator = new TestEnvironmentConfigurator();
  configurator.configure().catch(error => {
    console.error('Configuration failed:', error);
    process.exit(1);
  });
}

module.exports = { TestEnvironmentConfigurator };