# Contributing to LLMCal

Thank you for your interest in contributing to LLMCal! This guide will help you get started with contributing to the project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contribution Guidelines](#contribution-guidelines)
- [Issue Guidelines](#issue-guidelines)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Community](#community)

## 🤝 Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

### Our Standards

**Examples of behavior that contributes to creating a positive environment:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

**Examples of unacceptable behavior:**
- The use of sexualized language or imagery and unwelcome sexual attention or advances
- Trolling, insulting/derogatory comments, and personal or political attacks
- Public or private harassment
- Publishing others' private information without explicit permission
- Other conduct which could reasonably be considered inappropriate

## 🚀 Getting Started

### Prerequisites

Before contributing, make sure you have:

- **macOS 10.15+** (for full development and testing)
- **Node.js 16+** and **npm** for demo development
- **PopClip** installed and configured
- **Anthropic API key** for testing
- **Git** for version control
- **Shell scripting** knowledge (bash)
- **JavaScript/TypeScript** knowledge (for demo)

### First Contribution

Looking to make your first contribution? Here are some good starting points:

1. **Documentation improvements** - Fix typos, add examples, improve clarity
2. **Translation updates** - Add or improve translations in `i18n.json`
3. **Bug fixes** - Look for issues labeled `good first issue`
4. **Feature enhancements** - Small improvements to existing features

## 🛠️ Development Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/LLMCal.git
cd LLMCal

# Add upstream remote
git remote add upstream https://github.com/cafferychen777/LLMCal.git
```

### 2. Environment Setup

```bash
# Install demo dependencies
cd demo
npm install

# Install development tools
npm install -g shellcheck  # For shell script linting
```

### 3. Configuration

```bash
# Create environment configuration
cat > .env << EOF
ANTHROPIC_API_KEY=your_api_key_here
DEFAULT_TIMEZONE=America/New_York
LOG_LEVEL=debug
EOF

# Copy to PopClip extension for testing
cp .env LLMCal.popclipext/
```

### 4. Verify Setup

```bash
# Test shell scripts
cd LLMCal.popclipext
./test.sh

# Test demo application
cd ../demo
npm run dev
```

## 📝 Contribution Guidelines

### What We Welcome

- **Bug fixes** - Help us squash bugs and improve stability
- **Feature enhancements** - Improvements to existing functionality
- **New features** - Well-thought-out additions that fit the project scope
- **Performance improvements** - Make LLMCal faster and more efficient
- **Documentation** - Help others understand and use LLMCal
- **Translations** - Make LLMCal accessible to more users worldwide
- **Tests** - Improve code coverage and reliability

### What We Don't Accept

- **Breaking changes** without thorough discussion and approval
- **Major architectural changes** without prior consultation
- **Features that significantly increase complexity** without clear benefits
- **Code that doesn't follow our standards** (will be requested to fix)
- **Contributions without tests** for new functionality

## 🐛 Issue Guidelines

### Before Creating an Issue

1. **Search existing issues** to avoid duplicates
2. **Check the FAQ** and documentation
3. **Try the latest version** - your issue might be already fixed
4. **Test with minimal configuration** to isolate the problem

### Creating Great Issues

Use our issue templates and include:

#### Bug Reports
- **Clear title** - Describe the problem concisely
- **Environment details** - macOS version, PopClip version, LLMCal version
- **Steps to reproduce** - Detailed, numbered steps
- **Expected vs actual behavior** - What should happen vs what happens
- **Screenshots/logs** - Visual evidence of the problem
- **Error messages** - Include full error text

#### Feature Requests
- **Clear use case** - Why is this feature needed?
- **Proposed solution** - How should it work?
- **Alternatives considered** - What other approaches did you consider?
- **Additional context** - Screenshots, mockups, examples

#### Questions
- **Clear question** - What specifically do you need help with?
- **Context** - What are you trying to accomplish?
- **What you've tried** - Show your attempt and research

### Issue Labels

We use labels to categorize and prioritize issues:

- `bug` - Something isn't working correctly
- `enhancement` - Improvement to existing functionality
- `feature` - New feature request
- `documentation` - Documentation improvements
- `good first issue` - Good for newcomers
- `help wanted` - Community help requested
- `priority: high` - Critical issues
- `priority: medium` - Important issues
- `priority: low` - Nice to have

## 🔄 Pull Request Guidelines

### Before Submitting

1. **Create an issue first** (for significant changes)
2. **Fork the repository** and create a feature branch
3. **Keep changes focused** - One feature/fix per PR
4. **Test thoroughly** - Ensure your changes work
5. **Update documentation** - Keep docs in sync
6. **Add tests** - For new functionality

### Pull Request Process

#### 1. Branch Naming

Use descriptive branch names:
```bash
# Features
git checkout -b feature/add-recurring-events
git checkout -b feature/google-calendar-integration

# Bug fixes
git checkout -b fix/timezone-parsing-error
git checkout -b fix/memory-leak-in-demo

# Documentation
git checkout -b docs/update-installation-guide
git checkout -b docs/add-api-examples

# Maintenance
git checkout -b chore/update-dependencies
git checkout -b refactor/simplify-date-parsing
```

#### 2. Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) format:

```bash
# Format
type(scope): subject

body (optional)

footer (optional)

# Examples
feat(calendar): add support for recurring events
fix(api): handle null response from Anthropic API
docs(readme): update installation instructions
test(calendar): add unit tests for date parsing
chore(deps): update dependencies to latest versions
```

#### 3. Pull Request Template

When creating a PR, include:

```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] I have tested these changes locally
- [ ] I have added/updated tests as appropriate
- [ ] All existing tests pass

## Documentation
- [ ] I have updated the documentation as needed
- [ ] I have updated the CHANGELOG.md

## Screenshots (if applicable)
[Add screenshots here]

## Additional Notes
[Any additional information]
```

#### 4. Review Process

1. **Automated checks** must pass (linting, tests)
2. **Peer review** from at least one maintainer
3. **Manual testing** by reviewers when needed
4. **Documentation review** for user-facing changes
5. **Final approval** from project maintainers

### Review Criteria

Reviewers will check for:
- **Code quality** - Readable, maintainable, efficient
- **Functionality** - Works as intended, handles edge cases
- **Testing** - Adequate test coverage
- **Documentation** - Clear and up-to-date
- **Compatibility** - Works with supported versions
- **Security** - No security vulnerabilities

## 🎯 Coding Standards

### Shell Scripts (`.sh` files)

```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Use meaningful variable names
readonly API_KEY="${ANTHROPIC_API_KEY}"
readonly LOG_FILE="/tmp/llmcal.log"

# Function naming: lowercase with underscores
get_system_language() {
    local language
    language=$(defaults read .GlobalPreferences AppleLanguages | head -1)
    echo "${language}"
}

# Error handling
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed" >&2
    exit 1
fi

# Logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $*" >> "${LOG_FILE}"
}

# Use ShellCheck and follow its suggestions
```

### JavaScript/TypeScript (Demo)

```typescript
// Use TypeScript for better type safety
interface CalendarEvent {
  title: string;
  startTime: Date;
  endTime: Date;
  location?: string;
  attendees?: string[];
}

// Use meaningful names and consistent formatting
const createCalendarEvent = async (eventData: CalendarEvent): Promise<boolean> => {
  try {
    // Implementation
    return true;
  } catch (error) {
    console.error('Failed to create calendar event:', error);
    throw error;
  }
};

// Use React best practices
const EventComponent: React.FC<{ event: CalendarEvent }> = ({ event }) => {
  return (
    <div className="event-container">
      <h3>{event.title}</h3>
      <p>{event.startTime.toLocaleString()}</p>
    </div>
  );
};
```

### File Organization

```
LLMCal/
├── docs/                          # Documentation
│   ├── API.md                    # API reference
│   ├── DEVELOPMENT.md            # Developer guide
│   ├── INSTALLATION.md           # Installation guide
│   └── TROUBLESHOOTING.md        # Troubleshooting
├── LLMCal.popclipext/            # PopClip extension
│   ├── calendar.sh               # Main script
│   ├── i18n.json                 # Translations
│   └── lib/                      # Utility scripts
├── demo/                         # Demo application
│   ├── src/                      # Source files
│   └── public/                   # Static assets
└── tests/                        # Test files
    ├── unit/                     # Unit tests
    ├── integration/              # Integration tests
    └── fixtures/                 # Test data
```

## 🧪 Testing

### Running Tests

```bash
# Run all tests
npm test

# Run specific test suites
npm run test:unit
npm run test:integration

# Run tests with coverage
npm run test:coverage

# Run shell script tests
cd LLMCal.popclipext
./test.sh
```

### Writing Tests

#### Unit Tests (JavaScript)

```javascript
import { parseEventText } from '../src/utils/parser';

describe('parseEventText', () => {
  test('should parse basic event information', () => {
    const text = 'Meeting tomorrow at 2pm for 1 hour';
    const result = parseEventText(text);
    
    expect(result.title).toBe('Meeting');
    expect(result.duration).toBe(60);
  });

  test('should handle edge cases', () => {
    const text = '';
    const result = parseEventText(text);
    
    expect(result).toBeNull();
  });
});
```

#### Integration Tests (Bash)

```bash
#!/bin/bash
# test_calendar_integration.sh

source "$(dirname "$0")/test_helpers.sh"

test_create_event() {
    local input="Team meeting tomorrow 2pm"
    local result
    
    result=$(echo "$input" | ./calendar.sh)
    assert_contains "$result" "Event created successfully"
}

test_invalid_api_key() {
    ANTHROPIC_API_KEY="invalid_key"
    local result
    
    result=$(echo "Meeting today" | ./calendar.sh 2>&1)
    assert_contains "$result" "Invalid API key"
}

run_tests
```

### Test Guidelines

- **Write tests for new features** - All new functionality should have tests
- **Test edge cases** - Consider empty inputs, invalid data, error conditions
- **Use descriptive test names** - Make it clear what the test is checking
- **Keep tests focused** - One test should verify one specific behavior
- **Mock external dependencies** - Don't rely on real API calls in tests

## 📚 Documentation

### Documentation Standards

- **Clear and concise** - Use simple language, avoid jargon
- **Include examples** - Show, don't just tell
- **Keep it updated** - Documentation should match current functionality
- **Consider all users** - Beginners to advanced users
- **Use consistent formatting** - Follow existing style

### Types of Documentation

#### Code Documentation
```bash
# Function: get_system_timezone
# Description: Retrieves the system timezone setting
# Arguments: None
# Returns: Timezone string (e.g., "America/New_York")
# Example: timezone=$(get_system_timezone)
get_system_timezone() {
    # Implementation
}
```

#### User Documentation
- **Installation guides** - Step-by-step setup instructions
- **Usage examples** - Common use cases and workflows
- **Troubleshooting** - Solutions to common problems
- **FAQ** - Frequently asked questions

#### Developer Documentation
- **API reference** - Function signatures and usage
- **Architecture overview** - How components work together
- **Contributing guide** - How to contribute (this document)
- **Coding standards** - Style guides and best practices

## 🌍 Internationalization

### Adding Translations

1. **Update `i18n.json`** with new language strings:

```json
{
  "en": {
    "success": "Event successfully added to calendar",
    "error": "Failed to add event to calendar"
  },
  "fr": {
    "success": "Événement ajouté au calendrier avec succès",
    "error": "Échec de l'ajout de l'événement au calendrier"
  },
  "de": {
    "success": "Ereignis erfolgreich zum Kalender hinzugefügt",
    "error": "Fehler beim Hinzufügen des Ereignisses zum Kalender"
  },
  "ja": {
    "success": "イベントがカレンダーに正常に追加されました",
    "error": "イベントの追加に失敗しました"
  }
}
```

2. **Test translations** in different language environments
3. **Update documentation** in the new language (optional but appreciated)

### Translation Guidelines

- **Use native speakers** when possible
- **Consider cultural context** - not just direct translation
- **Test in context** - Make sure translations fit in the UI
- **Keep formatting** - Maintain placeholders and formatting codes

## 💬 Community

### Getting Help

- **GitHub Discussions** - General questions and discussions
- **GitHub Issues** - Bug reports and feature requests
- **Documentation** - Check existing docs first
- **Code examples** - Look at existing code for patterns

### Community Guidelines

- **Be respectful** - Treat everyone with respect
- **Be patient** - Maintainers are volunteers
- **Be constructive** - Provide actionable feedback
- **Be collaborative** - Work together towards solutions

### Recognition

Contributors who make significant contributions will be:
- **Listed in CONTRIBUTORS.md** - Recognition for your work
- **Mentioned in release notes** - Credit for specific contributions
- **Invited to be maintainers** - For long-term, high-quality contributors

## 🎉 Thank You!

Every contribution, no matter how small, helps make LLMCal better for everyone. Whether you're fixing a typo, adding a feature, or helping other users, your efforts are appreciated!

---

**Questions?** Feel free to ask in [GitHub Discussions](https://github.com/cafferychen777/LLMCal/discussions) or open an issue.

**Ready to contribute?** Check out our [good first issues](https://github.com/cafferychen777/LLMCal/labels/good%20first%20issue) to get started!