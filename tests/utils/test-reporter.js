/**
 * Custom test reporter for LLMCal
 * Generates detailed test reports and summaries
 */

const fs = require('fs').promises;
const path = require('path');

class LLMCalTestReporter {
  constructor(globalConfig, options) {
    this.globalConfig = globalConfig;
    this.options = options;
    this.testResults = [];
    this.startTime = Date.now();
  }

  onRunStart(results, options) {
    console.log('🚀 Starting LLMCal test suite...');
    this.startTime = Date.now();
  }

  onTestStart(test) {
    const suiteName = test.context.config.testPathPattern || 'All Tests';
    console.log(`🧪 Running: ${path.basename(test.path)}`);
  }

  onTestResult(test, testResult) {
    const duration = testResult.perfStats.end - testResult.perfStats.start;
    const status = testResult.numFailingTests === 0 ? '✅ PASS' : '❌ FAIL';
    
    console.log(`${status} ${path.basename(testResult.testFilePath)} (${duration}ms)`);
    
    // Store results for summary
    this.testResults.push({
      testFilePath: testResult.testFilePath,
      numPassingTests: testResult.numPassingTests,
      numFailingTests: testResult.numFailingTests,
      numPendingTests: testResult.numPendingTests,
      duration: duration,
      success: testResult.numFailingTests === 0,
      failures: testResult.testResults.filter(t => t.status === 'failed'),
      coverage: testResult.coverage
    });

    // Log failures immediately
    if (testResult.numFailingTests > 0) {
      console.log('❌ Failures:');
      testResult.testResults
        .filter(t => t.status === 'failed')
        .forEach(failure => {
          console.log(`   - ${failure.title}`);
          if (failure.failureMessages.length > 0) {
            console.log(`     ${failure.failureMessages[0].split('\n')[0]}`);
          }
        });
    }
  }

  async onRunComplete(contexts, results) {
    const totalTime = Date.now() - this.startTime;
    
    console.log('\n📊 Test Summary:');
    console.log(`   Total Tests: ${results.numTotalTests}`);
    console.log(`   Passed: ${results.numPassedTests}`);
    console.log(`   Failed: ${results.numFailedTests}`);
    console.log(`   Skipped: ${results.numPendingTests}`);
    console.log(`   Duration: ${totalTime}ms`);

    // Generate detailed report
    await this.generateDetailedReport(results, totalTime);
    
    // Generate JUnit XML for CI
    await this.generateJUnitReport(results);
    
    // Generate coverage summary
    if (this.globalConfig.collectCoverage) {
      await this.generateCoverageSummary();
    }

    const success = results.numFailedTests === 0;
    console.log(`\n${success ? '🎉' : '💥'} Tests ${success ? 'completed successfully!' : 'failed!'}`);
  }

  async generateDetailedReport(results, totalTime) {
    const report = {
      timestamp: new Date().toISOString(),
      summary: {
        totalTests: results.numTotalTests,
        passedTests: results.numPassedTests,
        failedTests: results.numFailedTests,
        skippedTests: results.numPendingTests,
        totalTime: totalTime,
        success: results.numFailedTests === 0
      },
      testFiles: this.testResults.map(result => ({
        file: path.relative(process.cwd(), result.testFilePath),
        passed: result.numPassingTests,
        failed: result.numFailingTests,
        skipped: result.numPendingTests,
        duration: result.duration,
        success: result.success,
        failures: result.failures.map(f => ({
          title: f.title,
          message: f.failureMessages[0] ? f.failureMessages[0].split('\n')[0] : 'Unknown error'
        }))
      })),
      coverage: results.coverageMap ? this.extractCoverageSummary(results.coverageMap) : null
    };

    const reportPath = path.join(process.cwd(), 'coverage', 'detailed-report.json');
    await fs.mkdir(path.dirname(reportPath), { recursive: true });
    await fs.writeFile(reportPath, JSON.stringify(report, null, 2));

    // Also generate HTML report
    await this.generateHtmlReport(report);
  }

  async generateHtmlReport(report) {
    const html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LLMCal Test Report</title>
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
            max-width: 1200px; 
            margin: 0 auto; 
            padding: 20px;
            line-height: 1.6;
        }
        .header { 
            text-align: center; 
            margin-bottom: 40px; 
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 10px;
        }
        .summary { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
            gap: 20px; 
            margin-bottom: 40px; 
        }
        .stat-card { 
            padding: 20px; 
            border-radius: 8px; 
            text-align: center;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .stat-card.success { background: #d4edda; border-left: 4px solid #28a745; }
        .stat-card.danger { background: #f8d7da; border-left: 4px solid #dc3545; }
        .stat-card.warning { background: #fff3cd; border-left: 4px solid #ffc107; }
        .stat-card.info { background: #d1ecf1; border-left: 4px solid #17a2b8; }
        .stat-number { font-size: 2em; font-weight: bold; margin-bottom: 10px; }
        .stat-label { color: #666; font-size: 0.9em; }
        .test-file { 
            margin-bottom: 30px; 
            padding: 20px; 
            border-radius: 8px; 
            background: #f8f9fa;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .test-file.success { border-left: 4px solid #28a745; }
        .test-file.failure { border-left: 4px solid #dc3545; }
        .file-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; }
        .file-name { font-weight: bold; font-size: 1.1em; }
        .file-stats { font-size: 0.9em; color: #666; }
        .failure-list { margin-top: 15px; }
        .failure-item { 
            padding: 10px; 
            margin: 5px 0; 
            background: #fff; 
            border-left: 3px solid #dc3545; 
            border-radius: 4px;
        }
        .failure-title { font-weight: bold; color: #dc3545; }
        .failure-message { color: #666; font-size: 0.9em; margin-top: 5px; }
        .coverage-section { margin-top: 40px; padding: 20px; background: #f8f9fa; border-radius: 8px; }
        .coverage-bar { 
            height: 20px; 
            background: #e9ecef; 
            border-radius: 10px; 
            overflow: hidden; 
            margin: 10px 0;
        }
        .coverage-fill { 
            height: 100%; 
            background: linear-gradient(90deg, #28a745, #20c997); 
            transition: width 0.3s ease;
        }
        .timestamp { color: #666; font-size: 0.9em; margin-top: 20px; text-align: center; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🧪 LLMCal Test Report</h1>
        <p>Comprehensive test results for the LLMCal PopClip extension</p>
    </div>

    <div class="summary">
        <div class="stat-card ${report.summary.success ? 'success' : 'danger'}">
            <div class="stat-number">${report.summary.totalTests}</div>
            <div class="stat-label">Total Tests</div>
        </div>
        <div class="stat-card success">
            <div class="stat-number">${report.summary.passedTests}</div>
            <div class="stat-label">Passed</div>
        </div>
        <div class="stat-card ${report.summary.failedTests > 0 ? 'danger' : 'info'}">
            <div class="stat-number">${report.summary.failedTests}</div>
            <div class="stat-label">Failed</div>
        </div>
        <div class="stat-card ${report.summary.skippedTests > 0 ? 'warning' : 'info'}">
            <div class="stat-number">${report.summary.skippedTests}</div>
            <div class="stat-label">Skipped</div>
        </div>
        <div class="stat-card info">
            <div class="stat-number">${(report.summary.totalTime / 1000).toFixed(1)}s</div>
            <div class="stat-label">Duration</div>
        </div>
    </div>

    <h2>📁 Test Files</h2>
    ${report.testFiles.map(file => `
        <div class="test-file ${file.success ? 'success' : 'failure'}">
            <div class="file-header">
                <div class="file-name">${file.success ? '✅' : '❌'} ${file.file}</div>
                <div class="file-stats">
                    ${file.passed} passed, ${file.failed} failed, ${file.skipped} skipped (${file.duration}ms)
                </div>
            </div>
            ${file.failures.length > 0 ? `
                <div class="failure-list">
                    <strong>Failures:</strong>
                    ${file.failures.map(failure => `
                        <div class="failure-item">
                            <div class="failure-title">${failure.title}</div>
                            <div class="failure-message">${failure.message}</div>
                        </div>
                    `).join('')}
                </div>
            ` : ''}
        </div>
    `).join('')}

    ${report.coverage ? `
        <div class="coverage-section">
            <h2>📊 Coverage Summary</h2>
            <div>
                <strong>Statements:</strong> ${report.coverage.statements}%
                <div class="coverage-bar">
                    <div class="coverage-fill" style="width: ${report.coverage.statements}%"></div>
                </div>
            </div>
            <div>
                <strong>Branches:</strong> ${report.coverage.branches}%
                <div class="coverage-bar">
                    <div class="coverage-fill" style="width: ${report.coverage.branches}%"></div>
                </div>
            </div>
            <div>
                <strong>Functions:</strong> ${report.coverage.functions}%
                <div class="coverage-bar">
                    <div class="coverage-fill" style="width: ${report.coverage.functions}%"></div>
                </div>
            </div>
            <div>
                <strong>Lines:</strong> ${report.coverage.lines}%
                <div class="coverage-bar">
                    <div class="coverage-fill" style="width: ${report.coverage.lines}%"></div>
                </div>
            </div>
        </div>
    ` : ''}

    <div class="timestamp">
        Generated on ${new Date(report.timestamp).toLocaleString()}
    </div>
</body>
</html>`;

    const htmlPath = path.join(process.cwd(), 'coverage', 'test-report.html');
    await fs.writeFile(htmlPath, html);
  }

  async generateJUnitReport(results) {
    const xml = `<?xml version="1.0" encoding="UTF-8" ?>
<testsuites name="LLMCal Test Suite" tests="${results.numTotalTests}" failures="${results.numFailedTests}" time="${(Date.now() - this.startTime) / 1000}">
${this.testResults.map(result => `
  <testsuite name="${path.basename(result.testFilePath)}" tests="${result.numPassingTests + result.numFailingTests}" failures="${result.numFailingTests}" time="${result.duration / 1000}">
${result.failures.map(failure => `
    <testcase classname="${path.basename(result.testFilePath)}" name="${failure.title}" time="0">
      <failure message="${failure.failureMessages[0] ? failure.failureMessages[0].split('\n')[0].replace(/"/g, '&quot;') : 'Unknown error'}">
        ${failure.failureMessages[0] ? failure.failureMessages[0].replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;') : 'Unknown error'}
      </failure>
    </testcase>
`).join('')}
  </testsuite>
`).join('')}
</testsuites>`;

    const xmlPath = path.join(process.cwd(), 'coverage', 'junit.xml');
    await fs.mkdir(path.dirname(xmlPath), { recursive: true });
    await fs.writeFile(xmlPath, xml);
  }

  async generateCoverageSummary() {
    // This would integrate with Istanbul coverage reports
    // For now, create a placeholder summary
    const summary = {
      timestamp: new Date().toISOString(),
      message: "Coverage reporting is configured. Run 'npm run test:coverage' to generate coverage data.",
      threshold: {
        statements: 70,
        branches: 70,
        functions: 70,
        lines: 70
      }
    };

    const summaryPath = path.join(process.cwd(), 'coverage', 'coverage-summary.json');
    await fs.mkdir(path.dirname(summaryPath), { recursive: true });
    await fs.writeFile(summaryPath, JSON.stringify(summary, null, 2));
  }

  extractCoverageSummary(coverageMap) {
    // Extract coverage percentages from Istanbul coverage map
    if (!coverageMap || !coverageMap.getCoverageSummary) {
      return null;
    }

    const summary = coverageMap.getCoverageSummary();
    return {
      statements: summary.statements.pct,
      branches: summary.branches.pct,
      functions: summary.functions.pct,
      lines: summary.lines.pct
    };
  }
}

module.exports = LLMCalTestReporter;