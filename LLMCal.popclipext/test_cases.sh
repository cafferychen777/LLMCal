#!/bin/bash

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试用例数组
declare -a test_cases=(
    "每周二和周四下午4点与欧洲团队开会（他们是巴黎时间晚上11点），1小时，地点：线上 Zoom，链接：https://zoom.us/j/123456789，提醒：提前15分钟和1天，参与者：alice@europe.com, bob@europe.com"
    "每月第一个周三早上8点参加全球研讨会（新加坡下午10点，伦敦下午2点），2小时，地点：线上 Teams，链接：https://teams.microsoft.com/l/meetup-join/123，提醒：提前30分钟和2小时，与会者：moderator@global.com, asia@team.com, europe@team.com"
    "每两周一次的产品评审会，从周五下午3点开始，持续3小时（悉尼时间是周六早上8点开始），地点：会议室A，提醒：提前10分钟，参与者：pm@company.com, design@company.com, dev@company.com"
    "每月最后一个工作日下午5点财务部门例会，90分钟（纽约时间下午6点），地点：财务部会议室，提醒：提前1小时，参与者：finance@company.com, accounting@company.com"
    "每周一三五早上7点上斯坦福在线课程（加州时间早上5点，北京时间晚上9点），45分钟，地点：线上课堂，链接：https://stanford.zoom.us/j/987654321，提前5分钟提醒，参与者：instructor@stanford.edu"
    "每周四晚上11点与东京团队同步（他们是周五下午1点），持续1小时，地点：Google Meet，链接：https://meet.google.com/abc-defg-hij，提醒：提前15分钟和1小时，参与者：tokyo@team.com, osaka@team.com"
    "每三个月的第一个周一上午10点董事会会议（伦敦时间下午4点），3小时，地点：董事会议室，提醒：提前1天和2小时，参与者：ceo@company.com, cfo@company.com, cto@company.com"
    "每个工作日早上9:30团队晨会（远程团队是西雅图早上7:30），30分钟，地点：线上 Slack Huddle，链接：https://slack.com/huddle/123，提醒：提前5分钟，参与者：team@company.com"
    "本周五下午2点开始，之后每月第二和第四个周五下午2点项目评审（悉尼时间是凌晨5点），90分钟，地点：线上 WebEx，链接：https://webex.com/meet/123，提醒：提前30分钟和1天，参与者：australia@team.com, project@company.com"
    "从1月20日开始，每两周一次周三下午1点与印度团队开会（他们是晚上11:30），1小时，地点：线上 Microsoft Teams，链接：https://teams.microsoft.com/l/meeting/123，提醒：提前15分钟，参与者：bangalore@team.com, delhi@team.com"
    "明天下午2点产品演示，1小时，地点：线上，链接：https://zoom.us/j/demo123，提醒：提前5分钟、15分钟和30分钟"
    "下周一早上9点技术分享会，2小时，地点：线上 Zoom，链接：https://zoom.us/j/tech456，提醒：提前1天和1小时，参与者：tech@company.com"
    "每周三下午3点在线培训课程，1小时，地点：线上课堂，链接：https://learn.company.com/training123，提醒：提前10分钟和1小时"
    "明天上午11点客户会议，45分钟，地点：线上 Google Meet，链接：https://meet.google.com/xyz-123-abc，提醒：提前2小时，参与者：client@example.com"
    "下周四下午4点项目启动会，2小时，地点：线上 Teams，链接：https://teams.microsoft.com/l/meeting/456，提醒：提前1天、2小时和30分钟，参与者：project@company.com, team@company.com"
    "明天下午3点与市场部讨论新产品发布，2小时，参与者：marketing@company.com, product@company.com, pr@company.com"
    "下周一早上10点产品演示，1小时，参与者：client@bigcorp.com, sales@company.com, demo@company.com"
    "每周五下午4点团队回顾会议，1小时，参与者：team@company.com, manager@company.com, qa@company.com"
    "明天下午3点在咖啡厅讨论项目计划，1小时，地点：星巴克中央公园店"
    "下周二早上10点客户拜访，2小时，地点：客户总部 123 Main Street"
    "每周五下午4点在健身房团建，1小时，地点：LA Fitness downtown分店"
    "明天中午12点团队午餐会，90分钟，地点：意大利餐厅 Il Fornaio"
    "下周三下午2点产品发布会，3小时，地点：会展中心大厅A，参与者：press@company.com, marketing@company.com"
)

# 测试计数器
total_tests=0
passed_tests=0
failed_tests=0

# 创建日志目录
log_dir="test_logs"
mkdir -p "$log_dir"
timestamp=$(date +"%Y%m%d_%H%M%S")
log_file="$log_dir/test_run_$timestamp.log"

# 记录日志的函数
log() {
    echo -e "$1" | tee -a "$log_file"
}

# 运行单个测试用例
run_test() {
    local test_case="$1"
    local test_num="$2"
    
    log "\n${BLUE}运行测试 #$test_num: $test_case${NC}"
    
    # 设置 POPCLIP_TEXT 环境变量
    export POPCLIP_TEXT="$test_case"
    
    # 运行 calendar.sh 并捕获输出
    output=$(./calendar.sh 2>&1)
    exit_code=$?
    
    # 检查执行结果
    if [ $exit_code -eq 0 ]; then
        log "${GREEN}✓ 测试通过${NC}"
        log "输出:\n$output"
        ((passed_tests++))
    else
        log "${RED}✗ 测试失败${NC}"
        log "错误输出:\n$output"
        ((failed_tests++))
    fi
    
    # 记录详细信息到日志
    log "详细信息:"
    log "- 输入文本: $test_case"
    log "- 退出代码: $exit_code"
    log "- 完整输出: \n$output"
    log "----------------------------------------"
}

# 主测试流程
main() {
    log "开始测试运行 - $(date)"
    log "测试环境:"
    log "- 操作系统: $(uname -a)"
    log "- 当前目录: $(pwd)"
    log "- 脚本版本: $(grep -m 1 'VERSION=' calendar.sh || echo '未指定')"
    log "----------------------------------------"
    
    # 运行所有测试用例
    total_tests=${#test_cases[@]}
    for i in "${!test_cases[@]}"; do
        run_test "${test_cases[$i]}" "$((i+1))"
    done
    
    # 输出测试总结
    log "\n测试运行完成 - $(date)"
    log "测试总结:"
    log "- 总测试数: $total_tests"
    log "- 通过: ${GREEN}$passed_tests${NC}"
    log "- 失败: ${RED}$failed_tests${NC}"
    log "- 成功率: $(( (passed_tests * 100) / total_tests ))%"
    log "详细日志已保存到: $log_file"
}

# 运行测试
main
