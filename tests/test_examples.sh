#!/bin/bash

# Example test cases for LLMCal
# Note: You need to set your API key in the PopClip extension settings
# or export POPCLIP_OPTION_ANTHROPIC_API_KEY environment variable

SCRIPT_PATH="../LLMCal.popclipext/calendar.sh"

echo "===== LLMCal Test Examples ====="
echo "These examples demonstrate various calendar event types"
echo ""

# Example 1: Simple meeting
echo "Test 1: Simple meeting"
echo 'Text: "Team meeting tomorrow at 3pm"'
# POPCLIP_OPTION_ANTHROPIC_API_KEY="your-api-key" POPCLIP_TEXT="Team meeting tomorrow at 3pm" bash "$SCRIPT_PATH"

# Example 2: Recurring class (Tuesday/Thursday)
echo ""
echo "Test 2: Recurring class (TTh)"
echo 'Text: "STAT 605 - Advanced Statistical Computations, TTh 2:20pm - 3:35pm BLOC 448"'
# This will create a recurring event for both Tuesday and Thursday

# Example 3: High priority urgent meeting
echo ""
echo "Test 3: Urgent CEO meeting"
echo 'Text: "URGENT! CEO meeting tomorrow 10am, must attend"'
# This will be placed in the High Priority calendar

# Example 4: Deadline
echo ""
echo "Test 4: Project deadline"
echo 'Text: "Project report due December 15, 5:00 PM"'
# This will be placed in the Deadlines calendar

# Example 5: Personal event
echo ""
echo "Test 5: Personal dinner"
echo 'Text: "Dinner with family Saturday 7pm at home"'
# This will be placed in the Personal calendar

# Example 6: All-day event
echo ""
echo "Test 6: All-day conference"
echo 'Text: "Annual conference all day on March 20, 2025"'
# This will create an all-day event

# Example 7: Zoom meeting
echo ""
echo "Test 7: Zoom meeting with link"
echo 'Text: "Online team sync tomorrow 2pm https://zoom.us/j/123456789"'
# If Zoom integration is configured, this will create a Zoom meeting

# Example 8: Weekly recurring seminar
echo ""
echo "Test 8: Weekly seminar"
echo 'Text: "Statistics seminar every Friday 11:30am-12:20pm in BLOC 150"'
# This will create a weekly recurring event

# Example 9: Complex email parsing
echo ""
echo "Test 9: Extract event from email"
echo 'Text: "Dear Student, your thesis defense is scheduled for September 19, 2025 at 2:00 PM in Room 302. Please prepare a 20-minute presentation."'
# The AI will extract the relevant event information

# Example 10: Chinese text
echo ""
echo "Test 10: Chinese event"
echo 'Text: "下周二下午2点部门例会，讨论Q4计划"'
# This will correctly parse Chinese text and create the event

echo ""
echo "===== How to Run Tests ====="
echo "1. Set your Anthropic API key in environment variable:"
echo '   export API_KEY="your-api-key-here"'
echo ""
echo "2. Run a test:"
echo '   POPCLIP_OPTION_ANTHROPIC_API_KEY="$API_KEY" POPCLIP_TEXT="your text" bash ../LLMCal.popclipext/calendar.sh'
echo ""
echo "3. Check the logs:"
echo '   tail -f ~/Library/Logs/LLMCal/llmcal.log'
echo ""
echo "===== Supported Features ====="
echo "- Multi-day recurring events (TTh, MWF)"
echo "- Intelligent calendar selection (7 different calendars)"
echo "- All-day events"
echo "- Priority levels (high, medium, low)"
echo "- Multiple Claude models (Opus 4.1, Sonnet 4.0, Haiku 3.5)"
echo "- Zoom meeting integration"
echo "- Multi-language support (English, Chinese, etc.)"