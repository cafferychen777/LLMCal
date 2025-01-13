tell application "Calendar"
    tell calendar 1
        -- 创建事件并获取引用
        set theEvent to make new event with properties {summary:"每日测试会议", start date:current date, end date:(current date + 3600), description:"测试重复会议", recurrence:"FREQ=DAILY;INTERVAL=1"}
    end tell
end tell
