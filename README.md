# LLMCal — AI Calendar Extension for PopClip

<div align="center">
  <img src="LLMCal.popclipext/LLMCal.png" alt="LLMCal Logo" width="120">
  
  <h3>Turn highlighted text into calendar events in seconds</h3>
  
  <p>
    <a href="https://github.com/cafferychen777/LLMCal/releases">
      <img src="https://img.shields.io/github/v/release/cafferychen777/LLMCal" alt="Latest Release">
    </a>
    <a href="https://github.com/cafferychen777/LLMCal/stargazers">
      <img src="https://img.shields.io/github/stars/cafferychen777/LLMCal" alt="GitHub stars">
    </a>
    <a href="https://github.com/cafferychen777/LLMCal/blob/main/LICENSE">
      <img src="https://img.shields.io/badge/License-AGPLv3-blue" alt="License">
    </a>
    <img src="https://img.shields.io/badge/macOS-12%2B-black?logo=apple" alt="macOS 12+">
    <img src="https://img.shields.io/badge/PopClip-2022.5%2B-orange" alt="PopClip 2022.5+">
  </p>

  <p>
    <strong>
      <a href="#quick-start">Quick Start</a> • 
      <a href="#features">Features</a> • 
      <a href="#installation">Installation</a> • 
      <a href="#usage">Usage</a> • 
      <a href="docs/FAQ.md">FAQ</a>
    </strong>
  </p>
</div>

---

**LLMCal** is a PopClip extension that uses AI to convert natural language text into calendar events. Simply highlight text describing an event and click the calendar icon — it automatically extracts titles, times, locations, attendees, meeting links, and reminders.

## ✨ Key Features

- 🤖 **AI-Powered**: Uses Claude AI to understand natural language
- ⚡ **One-Click Creation**: Highlight text → Click calendar icon → Done
- 🌐 **Meeting Links**: Auto-detects Zoom, Teams, Google Meet URLs
- 📍 **Smart Locations**: Handles both physical and virtual meeting places
- ⏰ **Intelligent Reminders**: Sets alerts based on text descriptions
- 🔄 **Recurring Events**: Supports various repeat patterns
- 👥 **Attendees**: Extracts email addresses from text
- 🌍 **Time Zones**: Understands different time zone formats
- 📱 **Calendar Integration**: Works with Apple Calendar and Google Calendar (via macOS sync)

## 🚀 Quick Start

### Prerequisites

1. **macOS 12+** with **PopClip** installed ([download here](https://www.popclip.app/))
2. **Anthropic API key** ([get one here](https://console.anthropic.com/))

### Installation

1. Download the latest `LLMCal.popclipext.zip` from [Releases](https://github.com/cafferychen777/LLMCal/releases)
2. Double-click the file to install in PopClip
3. Open PopClip preferences and configure LLMCal with your API key

### First Use

1. Select this text: *"Team meeting tomorrow at 2pm for 1 hour"*
2. Click the calendar icon in PopClip
3. Watch the event appear in your calendar! 🎉

## 📖 Usage Examples

Simply highlight any of these text examples and click the calendar icon:

```text
"Team meeting tomorrow at 2pm for 1 hour"

"Weekly standup every Monday at 9:30am, 30 minutes, Zoom: https://zoom.us/j/123"

"Product demo next Tuesday 3pm with client@example.com, remind me 15 minutes before"

"Monthly review last Friday of each month, 2-4pm, Conference Room A"

"1:1 with manager Thursday 10am PST (1pm EST), 30 min, Teams: https://teams.microsoft.com/l/123"
```

## 🔧 Requirements

- **macOS 12+** (Monterey or later)
- **PopClip 2022.5+** ([download](https://www.popclip.app/))
- **Anthropic API key** ([get one](https://console.anthropic.com/))
- **Calendar.app** access permissions
- **Internet connection** for AI processing

## 📱 Google Calendar Integration

LLMCal works with Google Calendar through macOS integration:

1. **Setup**: System Settings → Internet Accounts → Add Google Account → Enable Calendar
2. **Usage**: Events created via LLMCal automatically sync to Google Calendar
3. **Sync**: Bi-directional sync between Apple Calendar and Google Calendar

## ❓ FAQ

**Q: Does it work with Google Calendar?**  
A: Yes! Connect your Google account to Apple Calendar in System Settings.

**Q: Does it support recurring events?**  
A: Yes, it understands patterns like "every Monday" or "monthly".

**Q: What meeting links are supported?**  
A: Zoom, Teams, Google Meet, and most other meeting URLs.

**Q: Why PopClip instead of a browser extension?**  
A: Works system-wide in any app (Mail, Notes, Slack) without switching to browser.

**Q: How is this different from native calendar parsing?**  
A: AI-powered extraction is more reliable for attendees, time zones, and complex patterns.

## 🔒 Privacy & Security

- API key stored securely in PopClip settings
- No event data stored or transmitted beyond calendar creation
- Processing done through Claude AI
- Minimal permissions: text selection and calendar access

## 🛠️ Troubleshooting

**Calendar Access Issues:**
1. System Settings → Privacy & Security → Full Disk Access → Enable PopClip
2. Restart Calendar.app

**API Key Problems:**
1. Verify key at [console.anthropic.com](https://console.anthropic.com/)
2. Check for extra spaces
3. Restart PopClip after updating

**PopClip Not Appearing:**
1. Ensure PopClip is running (menu bar icon visible)
2. System Settings → Accessibility → Enable PopClip

For more help, see [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) or [open an issue](https://github.com/cafferychen777/LLMCal/issues).

## 🤝 Support & Contributing

- **Issues**: [Report bugs or request features](https://github.com/cafferychen777/LLMCal/issues)
- **Discussions**: [Join the community](https://github.com/cafferychen777/LLMCal/discussions)
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md)
- **Security**: Report privately via [Security Advisory](https://github.com/cafferychen777/LLMCal/security/advisories)

## 📄 License

This project is licensed under the GNU Affero General Public License Version 3 (AGPLv3) with Commons Clause - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <sub>Made with ❤️ for the macOS community</sub>
</div>
