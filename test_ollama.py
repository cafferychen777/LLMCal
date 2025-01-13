import requests
import json
from datetime import datetime, timedelta

def get_formatted_dates():
    today = datetime.now()
    
    # 计算下周三的日期
    current_weekday = today.weekday()  # 0 是周一，2 是周三
    days_until_next_wednesday = (2 - current_weekday + 7) % 7
    if days_until_next_wednesday == 0:
        days_until_next_wednesday = 7
    next_wednesday = today + timedelta(days=days_until_next_wednesday)
    
    dates = {
        'today': today.strftime('%Y-%m-%d'),
        'tomorrow': (today + timedelta(days=1)).strftime('%Y-%m-%d'),
        'day_after_tomorrow': (today + timedelta(days=2)).strftime('%Y-%m-%d'),
        'next_wednesday': next_wednesday.strftime('%Y-%m-%d')
    }
    
    # 打印日期上下文以便调试
    print("\nDate context:")
    print(f"Today: {dates['today']}")
    print(f"Tomorrow: {dates['tomorrow']}")
    print(f"Day after tomorrow: {dates['day_after_tomorrow']}")
    print(f"Next Wednesday: {dates['next_wednesday']}")
    print("-" * 50)
    
    return dates

def test_calendar_parsing(test_text):
    print(f"\nTesting text: {test_text}")
    print("-" * 50)
    
    dates = get_formatted_dates()
    
    headers = {
        "x-api-key": "YOUR_ANTHROPIC_API_KEY",
        "content-type": "application/json"
    }
    
    try:
        response = requests.post(
            'https://api.anthropic.com/v1/messages',
            headers=headers,
            json={
                "model": "claude-3-opus-20240229",
                "max_tokens": 1024,
                "messages": [{
                    "role": "user",
                    "content": f"""Convert the following text into a calendar event.
                    CRITICAL DATE MAPPINGS (must use exactly these dates):
                    - "今天" = {dates['today']}
                    - "明天" = {dates['tomorrow']}
                    - "后天" = {dates['day_after_tomorrow']}
                    - "下周三" = {dates['next_wednesday']}

                    Requirements:
                    1. Always provide a meaningful title
                    2. Extract start_time and end_time in exact "YYYY-MM-DD HH:mm" format
                    3. Add a brief description
                    4. Return ONLY valid JSON with these fields: title, start_time, end_time, description
                    5. If time is ambiguous (like just saying "下午"), use reasonable business hours (2pm-5pm)
                    6. Duration expressions like "一小时" should be used to calculate end_time

                    Text to convert: {test_text}

                    Response must be ONLY valid JSON with no other text."""
                }]
            }
        )
        
        response_data = response.json()
        if 'content' in response_data:
            event_json = json.loads(response_data['content'][0]['text'])
            print("\nParsed event:")
            print(json.dumps(event_json, indent=2, ensure_ascii=False))
            return event_json
        else:
            print("Error: Unexpected API response format")
            return None

    except Exception as e:
        print(f"Error: {str(e)}")
        return None

if __name__ == "__main__":
    test_cases = [
        "下周三下午3点开产品评审会，大约1小时",
        "明天上午10点和客户开会讨论项目进展，预计2小时",
        "后天下午2:30有个团队周会，半小时左右"
    ]
    
    for test_case in test_cases:
        test_calendar_parsing(test_case)