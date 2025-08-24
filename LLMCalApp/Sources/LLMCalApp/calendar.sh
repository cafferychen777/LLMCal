#!/bin/bash

# 启用调试模式
set -x

# 检查环境变量
echo "Current environment："
echo "ANTHROPIC_API_KEY length: ${#ANTHROPIC_API_KEY}"
echo "SELECTED_LLM: $SELECTED_LLM"
echo "PATH: $PATH"

# 检查参数
if [ $# -lt 1 ]; then
    echo "错误：缺少参数"
    exit 1
fi

# 获取输入文本
input_text="$1"
is_base64=false

# 检查是否使用 Base64 编码
if [ "$2" = "--base64" ]; then
    is_base64=true
fi

# 如果是 Base64 编码，则解码
if [ "$is_base64" = true ]; then
    input_text=$(echo "$input_text" | base64 --decode)
fi

echo "输入文本：$input_text"

# 获取当前日期作为参考
TODAY=$(date +%Y-%m-%d)
TOMORROW=$(date -v+1d +%Y-%m-%d)
DAY_AFTER_TOMORROW=$(date -v+2d +%Y-%m-%d)

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
    \"model\": \"claude-3-5-sonnet-20241022\",
    \"max_tokens\": 1024,
    \"messages\": [{
        \"role\": \"user\",
        \"content\": \"Convert text to calendar event: '$input_text'\\nUse these dates:\\n- Today: $TODAY\\n- Tomorrow: $TOMORROW\\nReturn only JSON with: title, start_time ('$TOMORROW 15:00' format), end_time ('$TOMORROW 16:00' format), description\"
    }]
}"

# 调用 Claude API 并处理响应
RESPONSE=$(curl -s -X POST "https://api.anthropic.com/v1/messages" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$JSON_PAYLOAD")

# 使用 Python 脚本处理响应
EVENT_JSON=$(echo "$RESPONSE" | python3 "$TEMP_PYTHON_FILE")

# 解析 JSON 响应
if ! PARSED_JSON=$(echo "$RESPONSE" | jq -r '.content[0].text' 2>/dev/null); then
    echo "Error: Failed to parse initial JSON response"
    exit 1
fi

# 提取各个字段
TITLE=$(echo "$PARSED_JSON" | jq -r '.title // empty')
START_TIME=$(echo "$PARSED_JSON" | jq -r '.start_time // empty')
END_TIME=$(echo "$PARSED_JSON" | jq -r '.end_time // empty')
DESCRIPTION=$(echo "$PARSED_JSON" | jq -r '.description // empty')

# 检查必要字段是否存在
if [ -z "$TITLE" ] || [ -z "$START_TIME" ] || [ -z "$END_TIME" ]; then
    echo "错误：缺少必要字段"
    exit 1
fi

# 创建日历事件的 AppleScript
APPLE_SCRIPT="tell application \"System Events\"
    tell application \"Calendar\"
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
            make new event with properties {summary:\"$TITLE\", start date:startDate, end date:endDate, description:\"$DESCRIPTION\"}
        end tell
    end tell
end tell"

# 执行 AppleScript
if osascript -e "$APPLE_SCRIPT"; then
    echo "成功：事件已添加到日历"
    exit 0
else
    echo "错误：无法添加事件到日历"
    exit 1
fi

# 清理临时文件
rm -f "$TEMP_PYTHON_FILE"
