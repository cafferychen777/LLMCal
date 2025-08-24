/**
 * Test result notification service
 * Sends notifications about test results via various channels
 */

const fs = require('fs').promises;
const path = require('path');

class NotificationService {
  constructor(config = {}) {
    this.config = {
      enabled: process.env.NOTIFICATIONS_ENABLED === 'true',
      webhookUrl: process.env.WEBHOOK_URL,
      email: process.env.NOTIFICATION_EMAIL,
      channels: ['console', 'file'],
      ...config
    };
  }

  async notifyTestStart(testSuite) {
    if (!this.config.enabled) return;

    const message = {
      type: 'test_start',
      timestamp: new Date().toISOString(),
      suite: testSuite,
      message: `🚀 Starting test suite: ${testSuite}`
    };

    await this.sendNotification(message);
  }

  async notifyTestComplete(results) {
    if (!this.config.enabled) return;

    const success = results.numFailedTests === 0;
    const message = {
      type: 'test_complete',
      timestamp: new Date().toISOString(),
      success: success,
      summary: {
        total: results.numTotalTests,
        passed: results.numPassedTests,
        failed: results.numFailedTests,
        skipped: results.numPendingTests
      },
      message: success 
        ? `✅ All tests passed! (${results.numPassedTests}/${results.numTotalTests})`
        : `❌ ${results.numFailedTests} test(s) failed out of ${results.numTotalTests}`
    };

    await this.sendNotification(message);
  }

  async notifyTestFailure(testFile, failure) {
    if (!this.config.enabled) return;

    const message = {
      type: 'test_failure',
      timestamp: new Date().toISOString(),
      testFile: path.basename(testFile),
      failure: {
        title: failure.title,
        message: failure.failureMessages[0] ? failure.failureMessages[0].split('\n')[0] : 'Unknown error'
      },
      message: `❌ Test failure in ${path.basename(testFile)}: ${failure.title}`
    };

    await this.sendNotification(message);
  }

  async notifyCoverageThreshold(coverage, thresholds) {
    if (!this.config.enabled) return;

    const belowThreshold = Object.keys(thresholds).filter(
      key => coverage[key] < thresholds[key]
    );

    if (belowThreshold.length > 0) {
      const message = {
        type: 'coverage_warning',
        timestamp: new Date().toISOString(),
        coverage: coverage,
        thresholds: thresholds,
        belowThreshold: belowThreshold,
        message: `⚠️ Coverage below threshold: ${belowThreshold.join(', ')}`
      };

      await this.sendNotification(message);
    }
  }

  async sendNotification(message) {
    const promises = [];

    if (this.config.channels.includes('console')) {
      promises.push(this.sendConsoleNotification(message));
    }

    if (this.config.channels.includes('file')) {
      promises.push(this.sendFileNotification(message));
    }

    if (this.config.channels.includes('webhook') && this.config.webhookUrl) {
      promises.push(this.sendWebhookNotification(message));
    }

    if (this.config.channels.includes('macos') && process.platform === 'darwin') {
      promises.push(this.sendMacOSNotification(message));
    }

    await Promise.allSettled(promises);
  }

  async sendConsoleNotification(message) {
    const emoji = this.getMessageEmoji(message.type);
    const timestamp = new Date(message.timestamp).toLocaleTimeString();
    console.log(`${emoji} [${timestamp}] ${message.message}`);
  }

  async sendFileNotification(message) {
    try {
      const logDir = path.join(process.cwd(), 'coverage', 'notifications');
      await fs.mkdir(logDir, { recursive: true });
      
      const logFile = path.join(logDir, 'test-notifications.jsonl');
      const logEntry = JSON.stringify(message) + '\n';
      
      await fs.appendFile(logFile, logEntry);
    } catch (error) {
      console.error('Failed to write notification to file:', error.message);
    }
  }

  async sendWebhookNotification(message) {
    try {
      const payload = {
        text: message.message,
        attachments: [{
          color: this.getMessageColor(message.type),
          fields: this.formatMessageFields(message),
          ts: Math.floor(new Date(message.timestamp).getTime() / 1000)
        }]
      };

      // This would send to Slack, Discord, etc.
      console.log('Webhook payload ready:', payload);
      
      // Uncomment for actual webhook sending:
      // const response = await fetch(this.config.webhookUrl, {
      //   method: 'POST',
      //   headers: { 'Content-Type': 'application/json' },
      //   body: JSON.stringify(payload)
      // });
      
    } catch (error) {
      console.error('Failed to send webhook notification:', error.message);
    }
  }

  async sendMacOSNotification(message) {
    try {
      const { exec } = require('child_process');
      const { promisify } = require('util');
      const execAsync = promisify(exec);

      const title = 'LLMCal Tests';
      const subtitle = this.getMessageTitle(message.type);
      const body = message.message.replace(/[🚀✅❌⚠️]/g, '').trim();

      const command = `osascript -e 'display notification "${body}" with title "${title}" subtitle "${subtitle}"'`;
      
      await execAsync(command);
    } catch (error) {
      console.error('Failed to send macOS notification:', error.message);
    }
  }

  getMessageEmoji(type) {
    const emojis = {
      test_start: '🚀',
      test_complete: '✅',
      test_failure: '❌',
      coverage_warning: '⚠️',
      performance_warning: '🐌',
      error: '💥'
    };
    return emojis[type] || '📢';
  }

  getMessageColor(type) {
    const colors = {
      test_start: '#36a64f',
      test_complete: '#36a64f',
      test_failure: '#ff0000',
      coverage_warning: '#ffaa00',
      performance_warning: '#ffaa00',
      error: '#ff0000'
    };
    return colors[type] || '#808080';
  }

  getMessageTitle(type) {
    const titles = {
      test_start: 'Starting Tests',
      test_complete: 'Tests Complete',
      test_failure: 'Test Failure',
      coverage_warning: 'Coverage Warning',
      performance_warning: 'Performance Warning',
      error: 'Error'
    };
    return titles[type] || 'Notification';
  }

  formatMessageFields(message) {
    const fields = [];

    if (message.type === 'test_complete' && message.summary) {
      fields.push({
        title: 'Summary',
        value: `${message.summary.passed}/${message.summary.total} passed, ${message.summary.failed} failed, ${message.summary.skipped} skipped`,
        short: false
      });
    }

    if (message.type === 'test_failure' && message.failure) {
      fields.push({
        title: 'Test File',
        value: message.testFile,
        short: true
      });
      fields.push({
        title: 'Failed Test',
        value: message.failure.title,
        short: true
      });
    }

    if (message.type === 'coverage_warning' && message.coverage) {
      fields.push({
        title: 'Coverage',
        value: Object.entries(message.coverage)
          .map(([key, value]) => `${key}: ${value}%`)
          .join('\n'),
        short: true
      });
      fields.push({
        title: 'Thresholds',
        value: Object.entries(message.thresholds)
          .map(([key, value]) => `${key}: ${value}%`)
          .join('\n'),
        short: true
      });
    }

    return fields;
  }

  // Integration with Jest reporter
  static createJestReporter() {
    return class JestNotificationReporter {
      constructor(globalConfig, options) {
        this.notificationService = new NotificationService(options);
      }

      async onRunStart(results) {
        await this.notificationService.notifyTestStart('LLMCal Test Suite');
      }

      async onRunComplete(contexts, results) {
        await this.notificationService.notifyTestComplete(results);

        // Check coverage thresholds
        if (results.coverageMap && this.globalConfig.coverageThreshold) {
          const summary = results.coverageMap.getCoverageSummary();
          const coverage = {
            statements: summary.statements.pct,
            branches: summary.branches.pct,
            functions: summary.functions.pct,
            lines: summary.lines.pct
          };

          await this.notificationService.notifyCoverageThreshold(
            coverage,
            this.globalConfig.coverageThreshold.global
          );
        }
      }

      async onTestResult(test, testResult) {
        // Notify on failures
        testResult.testResults
          .filter(t => t.status === 'failed')
          .forEach(async failure => {
            await this.notificationService.notifyTestFailure(testResult.testFilePath, failure);
          });
      }
    };
  }

  // Generate notification summary report
  async generateSummaryReport() {
    try {
      const logFile = path.join(process.cwd(), 'coverage', 'notifications', 'test-notifications.jsonl');
      
      if (!(await fs.access(logFile).then(() => true).catch(() => false))) {
        return null;
      }

      const logContent = await fs.readFile(logFile, 'utf8');
      const notifications = logContent
        .split('\n')
        .filter(line => line.trim())
        .map(line => JSON.parse(line));

      const summary = {
        totalNotifications: notifications.length,
        byType: notifications.reduce((acc, notif) => {
          acc[notif.type] = (acc[notif.type] || 0) + 1;
          return acc;
        }, {}),
        timeRange: {
          start: notifications[0]?.timestamp,
          end: notifications[notifications.length - 1]?.timestamp
        },
        recentFailures: notifications
          .filter(n => n.type === 'test_failure')
          .slice(-10)
          .map(n => ({
            testFile: n.testFile,
            failure: n.failure.title,
            timestamp: n.timestamp
          }))
      };

      const reportPath = path.join(process.cwd(), 'coverage', 'notification-summary.json');
      await fs.writeFile(reportPath, JSON.stringify(summary, null, 2));

      return summary;
    } catch (error) {
      console.error('Failed to generate notification summary:', error.message);
      return null;
    }
  }
}

module.exports = { NotificationService };