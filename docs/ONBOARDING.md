# LLMCal First-Time User Onboarding Guide

Welcome to LLMCal! This guide will help you get started quickly and make the most of your AI-powered calendar assistant.

## 🎉 Welcome to LLMCal!

LLMCal transforms how you create calendar events. Simply select text describing an event anywhere on your Mac, and let AI do the heavy lifting of parsing dates, times, locations, and creating perfectly formatted calendar entries.

### What Makes LLMCal Special?

- **🤖 AI-Powered**: Understands natural language like "weekly team standup every Monday 9am"
- **⚡ Lightning Fast**: Create events in seconds with a single click
- **🌍 Smart**: Handles timezones, recurring patterns, meeting links, and attendees automatically
- **🔒 Private**: Your data stays on your device

## 🚀 Quick Start (5 Minutes)

### Step 1: Install PopClip
PopClip is the foundation that makes LLMCal work.

1. **Download PopClip**: Visit [popclip.app](https://www.popclip.app)
2. **Install and Launch**: Follow the installation instructions
3. **Grant Permissions**: When prompted, enable PopClip in:
   - System Settings → Privacy & Security → Accessibility

### Step 2: Get Your AI Key
LLMCal uses Anthropic's Claude AI for natural language processing.

1. **Visit Anthropic**: Go to [console.anthropic.com](https://console.anthropic.com)
2. **Sign Up/Login**: Create an account if you don't have one
3. **Create API Key**: 
   - Navigate to "API Keys" in the dashboard
   - Click "Create Key"
   - Copy the key (starts with `sk-ant-`)
   - **Keep it safe!** You'll need it in the next step

### Step 3: Install LLMCal
1. **Download**: Get the latest `LLMCal.popclipext.zip` from [GitHub Releases](https://github.com/cafferychen777/LLMCal/releases)
2. **Install**: Double-click the downloaded file
3. **Confirm**: Click "Install Extension" when PopClip asks

### Step 4: Configure
1. **Open PopClip Settings**: Right-click the PopClip icon in your menu bar → Extensions
2. **Find LLMCal**: Look for the calendar icon in the extensions list
3. **Add API Key**: Click the settings gear → paste your Anthropic API key → Save
4. **Grant Calendar Access**: Allow PopClip to access your calendar when prompted

### Step 5: Test It!
1. **Select this text**: "Team meeting tomorrow at 2pm for 1 hour"
2. **Look for PopClip**: A menu should appear above your selection
3. **Click Calendar Icon**: The LLMCal icon should be visible
4. **Check Your Calendar**: A new event should appear!

🎊 **Congratulations!** You're now ready to use LLMCal!

## 📚 Learning Path

### Beginner (Week 1)
Start with these simple examples to get comfortable:

#### Basic Events
Try selecting and converting these texts:
- "Lunch meeting tomorrow at noon"
- "Conference call Friday 3pm"
- "Dentist appointment next Monday 10am"

#### With Durations
- "Team standup tomorrow 9am for 30 minutes"
- "Client presentation Thursday 2pm, 2 hours"
- "Workshop Saturday 10am-4pm"

### Intermediate (Week 2)
Master more complex scenarios:

#### Recurring Events
- "Weekly team meeting every Monday 9am"
- "Monthly review last Friday of each month 2pm"
- "Daily standup weekdays 9:30am for 15 minutes"

#### With Locations
- "Product demo at Conference Room A tomorrow 3pm"
- "Coffee meeting at Starbucks downtown Friday noon"
- "Remote call from home office Monday 10am"

#### With Attendees
- "Planning session with john@company.com and sarah@company.com Tuesday 2pm"
- "Client call with team@client.com Wednesday 10am"

### Advanced (Week 3+)
Handle complex, real-world scenarios:

#### Meeting Links
- "Zoom standup https://zoom.us/j/123 every Monday 9am"
- "Teams call https://teams.microsoft.com/l/456 tomorrow 2pm"
- "Google Meet https://meet.google.com/abc-def-ghi Friday 10am"

#### Timezone Handling
- "Call with NYC team Monday 9am EST (my time 6am PST)"
- "London meeting Tuesday 14:00 GMT"
- "Sydney sync Friday 10am AEST"

#### Complex Patterns
- "Quarterly business review every 3 months on 15th at 2pm"
- "Bi-weekly one-on-one every other Thursday 10am"
- "End of sprint demo every 2 weeks Friday 4pm"

## 🎯 Pro Tips

### Writing Better Event Descriptions

#### ✅ Good Examples
- **Clear timeframes**: "tomorrow 2pm" vs "sometime tomorrow"
- **Specific durations**: "for 1 hour" vs "brief meeting"
- **Complete information**: Include who, what, when, where

#### ❌ Common Mistakes
- **Vague timing**: "later today" (be specific)
- **Missing context**: "meeting" (what kind? with whom?)
- **Ambiguous dates**: "next week" (which day?)

### Keyboard Shortcuts
- **Quick select**: Double-click a word, then drag to extend selection
- **Select paragraph**: Triple-click to select entire paragraph
- **Select sentence**: Hold Option and click

### Language Tips
LLMCal understands natural language in multiple languages:

#### English Variations
- "Meeting tomorrow 2pm" ✅
- "Reunion mañana a las 2pm" ✅ (Spanish)
- "会议明天下午2点" ✅ (Chinese)
- "Réunion demain 14h" ✅ (French)

#### Time Formats
- "2pm", "14:00", "2:00 PM" all work
- "2-3pm", "2pm to 3pm", "2pm for 1 hour" all work

## 🛠️ Troubleshooting Quick Fixes

### PopClip Doesn't Appear
1. **Check if PopClip is running**: Look for icon in menu bar
2. **Try selecting text again**: Sometimes takes a moment
3. **Check accessibility permissions**: System Settings → Privacy & Security → Accessibility

### "Invalid API Key" Error
1. **Double-check the key**: Should start with `sk-ant-`
2. **No extra spaces**: Copy-paste carefully
3. **Key still active**: Check at [console.anthropic.com](https://console.anthropic.com)

### Events Not Appearing in Calendar
1. **Check calendar permissions**: PopClip needs calendar access
2. **Restart Calendar app**: Sometimes helps with sync issues
3. **Check correct calendar**: Events might be in different calendar

### Text Not Recognized
1. **Be more specific**: "Team meeting Monday 2pm" vs "meeting Monday"
2. **Include duration**: "for 1 hour" or "30 minutes"
3. **Try shorter text**: Very long paragraphs might confuse AI

## 🌟 Advanced Features

### Custom Configurations
Create `~/.llmcal/config` for advanced settings:

```bash
# Default timezone
DEFAULT_TIMEZONE=America/New_York

# Preferred calendar
DEFAULT_CALENDAR=Work Events

# Default reminder time
DEFAULT_REMINDER_MINUTES=15

# Language override
LANGUAGE=en
```

### Batch Processing
Select multiple event descriptions at once:

```
Team standup Monday 9am
Client call Tuesday 2pm  
Project review Friday 3pm
```

All three events will be created automatically!

### Integration with Other Apps
LLMCal works great with:
- **Email**: Select meeting details from emails
- **Slack/Teams**: Copy event info from messages
- **Documents**: Extract dates from meeting notes
- **Web pages**: Grab event info from websites

## 🆘 Getting Help

### Self-Service Resources
1. **Documentation**: Check [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. **FAQ**: Most common questions answered in [README.md](../README.md)
3. **Demo**: Try the interactive demo at [cafferychen777.github.io/LLMCal](https://cafferychen777.github.io/LLMCal/)

### Community Support
1. **GitHub Discussions**: Ask questions at [github.com/cafferychen777/LLMCal/discussions](https://github.com/cafferychen777/LLMCal/discussions)
2. **Issues**: Report bugs at [github.com/cafferychen777/LLMCal/issues](https://github.com/cafferychen777/LLMCal/issues)
3. **Examples**: Share your use cases with the community

### Before Asking for Help
1. **Try the basics**: Restart PopClip, check API key
2. **Search existing issues**: Your question might be answered
3. **Include details**: System version, error messages, steps to reproduce

## 📈 Usage Analytics (Optional)

Track your productivity improvement:

### Week 1 Baseline
- Time spent creating calendar events manually: _____ minutes/day
- Average events created per day: _____
- Errors in event details: _____

### After 30 Days
- Time saved with LLMCal: _____ minutes/day
- Events created per day: _____
- Accuracy improvement: _____%

### Success Metrics
- **Time Savings**: Most users save 2-5 minutes per event
- **Accuracy**: AI parsing is 95%+ accurate for well-written descriptions
- **Adoption**: Users typically create 3x more calendar events with LLMCal

## 🎊 Congratulations!

You're now equipped to make the most of LLMCal! Remember:

- **Start simple**: Basic events first, then move to complex scenarios
- **Practice regularly**: The more you use it, the better you'll get
- **Experiment**: Try different phrasings to see what works best
- **Share feedback**: Help improve LLMCal for everyone

Welcome to the future of calendar management! 🚀

---

**Questions?** Check out our [Troubleshooting Guide](TROUBLESHOOTING.md) or join the [community discussions](https://github.com/cafferychen777/LLMCal/discussions).