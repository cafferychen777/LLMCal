# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2025-08-24

### Added
- **Multi-day recurring events support** - Now correctly handles TTh (Tuesday/Thursday) and MWF (Monday/Wednesday/Friday) class schedules
- **LLM-based intelligent calendar selection** - AI analyzes content to automatically select appropriate calendars
- **Priority-based calendar system** - Seven specialized calendars: High Priority, Medium Priority, Low Priority, Work, Personal, Meetings, Deadlines
- **Claude Opus 4.1 model support** - Added support for the most powerful Claude model ($15/$75 per MTok)
- **Extended event fields** - Support for all-day events, status, excluded dates, and priority levels
- **Model usage logging** - System now logs which Claude model is being used for each request

### Changed
- **Updated to latest Claude models** - Default model changed to Claude Sonnet 4.0
- **Simplified model selection** - Three clear options: Opus 4.1 (most powerful), Sonnet 4.0 (balanced), Haiku 3.5 (fast & affordable)
- **Enhanced prompt engineering** - Improved instructions for recurring events and calendar type selection
- **Bash 3.2 compatibility** - Replaced associative arrays with file-based caching for macOS compatibility

### Fixed
- **Multi-day recurring events** - Fixed issue where TTh classes only created Tuesday events (now uses FREQ=WEEKLY;BYDAY=TU,TH)
- **AppleScript status property** - Removed unsupported status property that caused Calendar app errors
- **JSON field validation** - All new fields (calendar_type, priority, allday, excluded_dates) are now properly preserved
- **Model pricing display** - Updated Haiku 3.5 pricing to correct values ($0.80/$4 per MTok)

### Removed
- **Deprecated Sonnet versions** - Removed claude-3-7-sonnet and claude-3-5-sonnet models
- **Status property in Calendar** - Removed as it's not supported by macOS Calendar AppleScript

## [Unreleased]

### Added
- Comprehensive documentation suite (API.md, INSTALLATION.md, DEVELOPMENT.md, TROUBLESHOOTING.md)
- Multi-language support for French, German, and Japanese
- Advanced error handling and user feedback system
- Dark mode support for demo application
- Responsive design for demo application
- First-time user onboarding guide

### Changed
- Enhanced README.md with detailed installation steps and troubleshooting
- Improved internationalization system with dynamic language switching
- Optimized animation performance in demo application
- Enhanced error message UI in PopClip extension

### Fixed
- Project naming inconsistency (quickcal → LLMCal)
- Package.json metadata and licensing information

## [1.0.0] - 2025-01-24

### Added
- 🤖 **AI-Powered Event Creation** - Uses Claude AI to understand natural language descriptions
- ⚡️ **PopClip Integration** - Seamless calendar event creation from selected text
- 🌐 **Meeting Link Support** - Automatic detection and addition of Zoom, Teams, Google Meet links
- 📍 **Location Handling** - Support for both physical and virtual meeting locations
- ⏰ **Smart Reminders** - Configurable event alerts based on text descriptions
- 🔄 **Recurring Events** - Support for daily, weekly, monthly, and yearly recurring patterns
- 👥 **Attendee Management** - Automatic extraction of participant email addresses
- 🌍 **Timezone Support** - Intelligent handling of different timezone specifications
- 📱 **Demo Application** - Interactive web demo showcasing extension capabilities
- 🌐 **Internationalization** - Multi-language support (English, Chinese, Spanish)

### Technical Features
- **Apple Calendar Integration** - Direct integration with macOS Calendar.app
- **Google Calendar Sync** - Support for Google Calendar through Apple Calendar sync
- **Environment Configuration** - Flexible configuration through environment variables
- **Comprehensive Logging** - Detailed logging system for debugging and monitoring
- **Error Recovery** - Robust error handling with user-friendly messages
- **Security** - Secure API key storage and handling
- **Testing Suite** - Comprehensive test coverage for core functionality

### Supported Event Types
- One-time meetings and appointments
- Recurring events (daily, weekly, monthly, yearly)
- All-day events
- Multi-day events
- Events with specific timezones
- Events with multiple attendees
- Events with meeting links (Zoom, Teams, Google Meet, etc.)
- Events with custom reminders

### System Requirements
- macOS 10.15 Catalina or later
- PopClip 2022.5 or later
- Anthropic API key
- Calendar.app access permissions
- Active internet connection

### Installation
- PopClip extension package (LLMCal.popclipext)
- One-click installation through PopClip
- Automatic configuration wizard
- Comprehensive setup documentation

### Performance
- Average response time: < 3 seconds
- Support for batch event creation
- Efficient memory usage
- Rate limiting compliance

### Security & Privacy
- Local processing of calendar data
- Secure API key storage
- No data retention beyond event creation
- GDPR compliant design
- Minimal permission requirements

---

## Release Process

### Version Numbering
- **Major (X.0.0)** - Breaking changes, major feature additions
- **Minor (X.Y.0)** - New features, backwards compatible
- **Patch (X.Y.Z)** - Bug fixes, small improvements

### Release Checklist
- [ ] Update version numbers in all relevant files
- [ ] Run full test suite
- [ ] Update documentation
- [ ] Create release notes
- [ ] Tag release in Git
- [ ] Update demo application
- [ ] Announce release

### Support Policy
- **Current version** - Full support and updates
- **Previous major version** - Security updates for 6 months
- **Older versions** - Community support only

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for information on how to contribute to this project.

## License

This project is licensed under the GNU Affero General Public License Version 3 (AGPLv3) with Commons Clause. See [LICENSE](LICENSE) for details.
