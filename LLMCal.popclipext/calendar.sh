#!/bin/bash

# 创建日志目录和文件
LOG_DIR="$HOME/Library/Logs/QuickCal"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/quickcal.log"

# 记录日志的函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOG_FILE"
}

# 获取系统语言
get_language() {
    local sys_lang=$(defaults read .GlobalPreferences AppleLanguages | awk 'NR==2 {print $1}' | tr -d '",')
    case "$sys_lang" in
        zh*) echo "zh" ;;
        es*) echo "es" ;;
        *) echo "en" ;;
    esac
}

# 获取翻译文本
get_translation() {
    local lang=$(get_language)
    local key=$1
    local translations_file="$POPCLIP_BUNDLE_PATH/i18n.json"
    
    if [ -f "$translations_file" ]; then
        python3 - "$translations_file" "$lang" "$key" <<'EOF'
import sys, json

try:
    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        data = json.load(f)
    lang = sys.argv[2]
    key = sys.argv[3]
    text = data.get(lang, {}).get(key, data['en'][key])
    print(text)
except Exception as e:
    print(f"Translation error: {str(e)}", file=sys.stderr)
    print(data['en'][key])
EOF
    else
        log "Translation file not found: $translations_file"
        case "$key" in
            "processing") echo "Processing..." ;;
            "success") echo "Event added to calendar" ;;
            "error") echo "Failed to add event" ;;
            *) echo "Unknown message" ;;
        esac
    fi
}

log "开始处理文本: $POPCLIP_TEXT"

# 显示处理开始的通知
processing_msg=$(get_translation "processing")
osascript -e "display notification \"$processing_msg\" with title \"LLMCal\""

# 获取当前日期作为参考
TODAY=$(date +%Y-%m-%d)
TOMORROW=$(date -v+1d +%Y-%m-%d)
DAY_AFTER_TOMORROW=$(date -v+2d +%Y-%m-%d)
NEXT_WEDNESDAY=$(date -v+wed +%Y-%m-%d)

# 创建临时 Python 文件来处理 JSON
TEMP_PYTHON_FILE="/tmp/process_event.py"
cat > "$TEMP_PYTHON_FILE" << 'EOF'
import sys
import json

def process_response(response_text):
    try:
        response = json.loads(response_text)
        content = response['content'][0]['text']
        # 移除可能的前导和尾随空格
        content = content.strip()
        # 解析事件数据
        event = json.loads(content)
        return event
    except Exception as e:
        print(f"Error processing response: {str(e)}", file=sys.stderr)
        return None

if __name__ == "__main__":
    response_text = sys.stdin.read()
    event = process_response(response_text)
    if event:
        print(json.dumps(event))
    else:
        print("{}")
EOF

# 准备 API 请求
JSON_PAYLOAD="{
    \"model\": \"claude-3-5-haiku-20241022\",
    \"max_tokens\": 1024,
    \"messages\": [{
        \"role\": \"user\",
        \"content\": \"Convert text to calendar event: '$POPCLIP_TEXT'\\nUse these dates:\\n- Today: $TODAY\\n- Tomorrow: $TOMORROW\\nReturn only JSON with: title, start_time ('$TOMORROW 15:00' format), end_time ('$TOMORROW 16:00' format), description, location (meeting place or address or 'online' for virtual meetings), url (meeting link for virtual meetings), alerts (array of minutes before event, e.g. [5, 15, 30, 1440] for 5 min, 15 min, 30 min, and 1 day before), recurrence (possible values: 'daily', 'weekly', 'biweekly', 'monthly', 'monthly_last_friday', 'none'), attendees (array of email addresses)\"
    }]
}"

log "发送 API 请求..."
log "请求内容: $JSON_PAYLOAD"

# 调用 Claude API 并处理响应
RESPONSE=$(curl -s -X POST "https://api.anthropic.com/v1/messages" \
    -H "x-api-key: $POPCLIP_OPTION_ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$JSON_PAYLOAD")

log "API 响应: $RESPONSE"

# 使用 Python 脚本处理响应
EVENT_JSON=$(echo "$RESPONSE" | python3 "$TEMP_PYTHON_FILE")
log "处理后的事件数据: $EVENT_JSON"

# 解析 JSON 响应
if ! PARSED_JSON=$(echo "$RESPONSE" | jq -r '.content[0].text' 2>/dev/null); then
    log "Error: Failed to parse initial JSON response"
    exit 1
fi

# 提取各个字段
TITLE=$(echo "$PARSED_JSON" | jq -r '.title // empty')
START_TIME=$(echo "$PARSED_JSON" | jq -r '.start_time // empty')
END_TIME=$(echo "$PARSED_JSON" | jq -r '.end_time // empty')
DESCRIPTION=$(echo "$PARSED_JSON" | jq -r '.description // empty')
LOCATION=$(echo "$PARSED_JSON" | jq -r '.location // empty')
URL=$(echo "$PARSED_JSON" | jq -r '.url // empty')
ALERTS=$(echo "$PARSED_JSON" | jq -r '.alerts[]' 2>/dev/null || echo "")
RECURRENCE=$(echo "$PARSED_JSON" | jq -r '.recurrence // empty')
ATTENDEES=$(echo "$PARSED_JSON" | jq -r '.attendees[]' 2>/dev/null || echo "")

# 记录解析结果
log "标题: $TITLE"
log "开始时间: $START_TIME"
log "结束时间: $END_TIME"
log "描述: $DESCRIPTION"
log "地点: $LOCATION"
log "会议链接: $URL"
log "提醒: $ALERTS"
log "重复: $RECURRENCE"

# 检查必要字段是否存在
if [ -z "$TITLE" ] || [ -z "$START_TIME" ] || [ -z "$END_TIME" ]; then
    osascript -e 'display notification "无法解析日历事件" with title "错误"'
    log "错误：缺少必要字段"
    exit 1
fi

# 构建参与者的 AppleScript 代码
ATTENDEES_SCRIPT=""
if [ -n "$ATTENDEES" ]; then
    while IFS= read -r email; do
        ATTENDEES_SCRIPT="$ATTENDEES_SCRIPT
        make new attendee at end of attendees with properties {email:\"$email\"}"
    done <<< "$ATTENDEES"
fi

# 创建日历事件的 AppleScript
if [ "$RECURRENCE" = "daily" ]; then
    RECURRENCE_RULE="FREQ=DAILY;INTERVAL=1"
elif [ "$RECURRENCE" = "weekly" ]; then
    RECURRENCE_RULE="FREQ=WEEKLY;INTERVAL=1"
elif [ "$RECURRENCE" = "biweekly" ]; then
    RECURRENCE_RULE="FREQ=WEEKLY;INTERVAL=2"
elif [ "$RECURRENCE" = "monthly" ]; then
    RECURRENCE_RULE="FREQ=MONTHLY;INTERVAL=1"
elif [ "$RECURRENCE" = "monthly_last_friday" ]; then
    RECURRENCE_RULE="FREQ=MONTHLY;BYDAY=-1FR"
fi

APPLE_SCRIPT="tell application \"Calendar\"
    set startDate to (current date)
    set year of startDate to (text 1 thru 4 of \"$START_TIME\") as integer
    set month of startDate to (text 6 thru 7 of \"$START_TIME\") as integer
    set day of startDate to (text 9 thru 10 of \"$START_TIME\") as integer
    set hours of startDate to (text 12 thru 13 of \"$START_TIME\") as integer
    set minutes of startDate to (text 15 thru 16 of \"$START_TIME\") as integer
    
    set endDate to (current date)
    set year of endDate to (text 1 thru 4 of \"$END_TIME\") as integer
    set month of endDate to (text 6 thru 7 of \"$END_TIME\") as integer
    set day of endDate to (text 9 thru 10 of \"$END_TIME\") as integer
    set hours of endDate to (text 12 thru 13 of \"$END_TIME\") as integer
    set minutes of endDate to (text 15 thru 16 of \"$END_TIME\") as integer
    
    tell calendar 1
        set eventProps to {summary:\"$TITLE\", start date:startDate, end date:endDate, description:\"$DESCRIPTION\"}"

# 添加地点（如果有）
if [ -n "$LOCATION" ]; then
    APPLE_SCRIPT="$APPLE_SCRIPT
        set eventProps to eventProps & {location:\"$LOCATION\"}"
fi

# 添加会议链接（如果有）
if [ -n "$URL" ]; then
    APPLE_SCRIPT="$APPLE_SCRIPT
        set eventProps to eventProps & {url:\"$URL\"}"
fi

# 添加重复规则（如果有）
if [ -n "$RECURRENCE_RULE" ]; then
    APPLE_SCRIPT="$APPLE_SCRIPT
        set eventProps to eventProps & {recurrence:\"$RECURRENCE_RULE\"}"
fi

APPLE_SCRIPT="$APPLE_SCRIPT
        set newEvent to make new event with properties eventProps"

# 添加提醒（如果有）
if [ -n "$ALERTS" ]; then
    APPLE_SCRIPT="$APPLE_SCRIPT
        tell newEvent"
    while IFS= read -r minutes; do
        APPLE_SCRIPT="$APPLE_SCRIPT
            make new sound alarm at end of sound alarms with properties {trigger interval:-$minutes}"
    done <<< "$ALERTS"
    APPLE_SCRIPT="$APPLE_SCRIPT
        end tell"
fi

# 添加参与者（如果有）
if [ -n "$ATTENDEES" ]; then
    APPLE_SCRIPT="$APPLE_SCRIPT
        tell newEvent"
    while IFS= read -r email; do
        APPLE_SCRIPT="$APPLE_SCRIPT
            make new attendee at end of attendees with properties {email:\"$email\"}"
    done <<< "$ATTENDEES"
    APPLE_SCRIPT="$APPLE_SCRIPT
        end tell"
fi

APPLE_SCRIPT="$APPLE_SCRIPT
    end tell
end tell"

log "执行 AppleScript: $APPLE_SCRIPT"

# 执行 AppleScript
osascript -e "$APPLE_SCRIPT"

# 如果成功创建事件，显示成功通知
if [ $? -eq 0 ]; then
    success_msg=$(get_translation "success")
    osascript -e "display notification \"$success_msg\" with title \"LLMCal\""
    log "成功创建事件"
else
    error_msg=$(get_translation "error")
    osascript -e "display notification \"$error_msg\" with title \"LLMCal\""
    log "创建事件失败"
fi

# 清理临时文件
rm -f "$TEMP_PYTHON_FILE"

log "处理完成"
