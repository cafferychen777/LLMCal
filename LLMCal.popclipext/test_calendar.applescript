tell application "Calendar"
    -- 创建一个基本事件
    tell calendar 1
        make new event with properties {summary:"测试会议", start date:current date, end date:(current date + 3600), description:"测试会议描述"}
    end tell
end tell
