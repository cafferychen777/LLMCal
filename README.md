# LLMCal - AI-Powered Calendar Event Creator for PopClip

LLMCal is a powerful PopClip extension that uses AI to convert selected text into calendar events. It understands natural language descriptions and automatically creates events with proper titles, times, locations, meeting links, and reminders.

## Features

- 🤖 **AI-Powered**: Uses Claude AI to understand natural language event descriptions
- ⚡️ **Quick Creation**: Create calendar events with a single click
- 🌐 **Meeting Links**: Automatically extracts and adds meeting URLs (Zoom, Teams, Google Meet, etc.)
- 📍 **Location Support**: Handles both physical and virtual meeting locations
- ⏰ **Smart Reminders**: Sets up event alerts based on text descriptions
- 🔄 **Recurring Events**: Supports various recurring event patterns
- 👥 **Attendees**: Automatically adds event participants from email addresses in the text
- 🌍 **Time Zones**: Understands and handles different time zones in event descriptions

## Installation

1. Download the latest release (`LLMCal.popclipext.zip`)
2. Double-click the downloaded file to install it in PopClip
3. When prompted, click "Install Extension"
4. Open PopClip's preferences and click on the LLMCal extension settings
5. Enter your Anthropic API key (Get one from [https://console.anthropic.com/](https://console.anthropic.com/))

## Usage

1. Select any text that describes an event, for example:
   - "Team meeting tomorrow at 2pm for 1 hour"
   - "Weekly standup every Monday at 9:30am, 30 minutes, Zoom link: https://zoom.us/j/123"
   - "Lunch with John next Friday at noon at Starbucks downtown"
2. Click the calendar icon in the PopClip menu
3. The event will be automatically created in your calendar with all relevant details

## Example Inputs

```
"Product demo next Tuesday 3pm with client@example.com, 1 hour on Zoom https://zoom.us/j/123, remind me 15 minutes before"

"Monthly team review on the last Friday of each month, 2pm-4pm, Conference Room A, reminder 1 day before"

"Weekly 1:1 with manager every Thursday 10am PST (my time 1pm EST), 30 minutes, Teams link: https://teams.microsoft.com/l/123"
```

## Requirements

- macOS 10.15 or later
- PopClip 2022.5 or later
- Anthropic API key
- Calendar.app access permission
- Internet connection

## Privacy & Security

- Your API key is stored securely in PopClip's settings
- No event data is stored or transmitted except to create the calendar event
- All natural language processing is done through Claude AI
- The extension only requires necessary permissions: text selection and calendar access

## Troubleshooting

If you encounter any issues:
1. Make sure your Anthropic API key is correctly entered in the extension settings
2. Check that you've granted calendar access permissions to PopClip
3. Ensure your text selection includes all necessary event details
4. Verify your internet connection

## Support

For issues, feature requests, or contributions, please visit the [GitHub repository](https://github.com/cafferychen777/LLMCal).

## License

MIT License - feel free to modify and reuse this extension according to your needs.
