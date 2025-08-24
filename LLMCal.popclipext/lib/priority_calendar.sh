#!/bin/bash

# Priority-based Calendar Management for LLMCal
# Handles calendar selection based on event priority and type

# Source required modules
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Calendar names for different priorities and types
readonly CALENDAR_HIGH_PRIORITY="High Priority"
readonly CALENDAR_MEDIUM_PRIORITY="Medium Priority"
readonly CALENDAR_LOW_PRIORITY="Low Priority"
readonly CALENDAR_WORK="Work"
readonly CALENDAR_PERSONAL="Personal"
readonly CALENDAR_DEADLINE="Deadlines"
readonly CALENDAR_MEETING="Meetings"
readonly CALENDAR_DEFAULT=""  # Set your default calendar here

# Priority keywords for detection
readonly HIGH_PRIORITY_KEYWORDS="urgent|important|critical|asap|emergency|high priority|必须|紧急|重要|立即|马上"
readonly MEDIUM_PRIORITY_KEYWORDS="review|appointment|scheduled|medium priority|预约|计划|安排"
readonly LOW_PRIORITY_KEYWORDS="tentative|optional|maybe|if possible|low priority|可选|备选|有空|如果"

# Work-related keywords
readonly WORK_KEYWORDS="work|office|business|meeting|conference|review|project|client|team|colleague|manager|工作|办公|项目|客户|团队"
readonly PERSONAL_KEYWORDS="personal|family|friend|birthday|vacation|doctor|dentist|私人|家庭|朋友|生日|假期"

# Create calendar if it doesn't exist
ensure_calendar_exists() {
    local calendar_name="$1"
    local calendar_color="$2"
    
    # Check if calendar exists
    local existing_calendars
    existing_calendars=$(osascript -e 'tell application "Calendar" to get name of every calendar' 2>/dev/null)
    
    if ! echo "$existing_calendars" | grep -q "$calendar_name"; then
        # Create new calendar
        osascript << EOF
tell application "Calendar"
    make new calendar with properties {name:"$calendar_name"}
end tell
EOF
        echo "Created new calendar: $calendar_name"
    fi
}

# Determine priority level from text
determine_priority() {
    local text="$1"
    local text_lower=$(echo "$text" | tr '[:upper:]' '[:lower:]')
    
    # Check for high priority indicators
    if echo "$text_lower" | grep -qE "$HIGH_PRIORITY_KEYWORDS"; then
        echo "high"
    # Check for medium priority indicators
    elif echo "$text_lower" | grep -qE "$MEDIUM_PRIORITY_KEYWORDS"; then
        echo "medium"
    # Default to low priority
    else
        echo "low"
    fi
}

# Determine event type (work vs personal)
determine_event_type() {
    local text="$1"
    local text_lower=$(echo "$text" | tr '[:upper:]' '[:lower:]')
    
    # Count work-related keywords
    local work_count=0
    for keyword in $(echo "$WORK_KEYWORDS" | tr '|' ' '); do
        if echo "$text_lower" | grep -q "$keyword"; then
            work_count=$((work_count + 1))
        fi
    done
    
    # Count personal keywords
    local personal_count=0
    for keyword in $(echo "$PERSONAL_KEYWORDS" | tr '|' ' '); do
        if echo "$text_lower" | grep -q "$keyword"; then
            personal_count=$((personal_count + 1))
        fi
    done
    
    # Determine type based on keyword counts
    if [ $work_count -gt $personal_count ]; then
        echo "work"
    elif [ $personal_count -gt 0 ]; then
        echo "personal"
    else
        echo "general"
    fi
}

# Select appropriate calendar based on event data
select_calendar_for_event() {
    local text="$1"
    local title="$2"
    local location="$3"
    local attendees="$4"
    
    # Combine all text for analysis
    local full_text="$text $title $location $attendees"
    
    # Determine priority and type
    local priority=$(determine_priority "$full_text")
    local event_type=$(determine_event_type "$full_text")
    
    # Special cases - check these first
    if echo "$full_text" | grep -qiE "deadline|due|截止|期限|到期|最后"; then
        echo "$CALENDAR_DEADLINE"
        return
    fi
    
    if echo "$full_text" | grep -qiE "meeting|conference|会议|例会|讨论会|研讨"; then
        echo "$CALENDAR_MEETING"
        return
    fi
    
    # Select calendar based on priority and type
    case "$priority" in
        "high")
            echo "$CALENDAR_HIGH_PRIORITY"
            ;;
        "medium")
            if [ "$event_type" = "work" ]; then
                echo "$CALENDAR_WORK"
            elif [ "$event_type" = "personal" ]; then
                echo "$CALENDAR_PERSONAL"
            else
                echo "$CALENDAR_MEDIUM_PRIORITY"
            fi
            ;;
        "low")
            if [ "$event_type" = "work" ]; then
                echo "$CALENDAR_WORK"
            elif [ "$event_type" = "personal" ]; then
                echo "$CALENDAR_PERSONAL"
            else
                echo "$CALENDAR_LOW_PRIORITY"
            fi
            ;;
        *)
            echo "$CALENDAR_DEFAULT"
            ;;
    esac
}

# Initialize priority calendars with colors
initialize_priority_calendars() {
    ensure_calendar_exists "$CALENDAR_HIGH_PRIORITY" "red"
    ensure_calendar_exists "$CALENDAR_MEDIUM_PRIORITY" "orange"
    ensure_calendar_exists "$CALENDAR_LOW_PRIORITY" "yellow"
    ensure_calendar_exists "$CALENDAR_WORK" "blue"
    ensure_calendar_exists "$CALENDAR_PERSONAL" "green"
    ensure_calendar_exists "$CALENDAR_DEADLINE" "purple"
    ensure_calendar_exists "$CALENDAR_MEETING" "cyan"
}

# Get calendar name for AppleScript
get_calendar_for_applescript() {
    local calendar_name="$1"
    
    # If empty or not specified, use default
    if [ -z "$calendar_name" ]; then
        echo "calendar \"$CALENDAR_DEFAULT\""
    else
        echo "calendar \"$calendar_name\""
    fi
}

# Export functions
export -f ensure_calendar_exists
export -f determine_priority
export -f determine_event_type
export -f select_calendar_for_event
export -f initialize_priority_calendars
export -f get_calendar_for_applescript