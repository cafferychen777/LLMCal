#!/bin/bash
# 将选中的文本写入临时文件
echo "$POPCLIP_TEXT" > /tmp/popclip_test.txt
# 显示通知
osascript -e "display notification \"$POPCLIP_TEXT\" with title \"PopClip Test\""
