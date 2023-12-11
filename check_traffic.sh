#!/bin/bash

# 获取第一个非本地回环网络接口的名称
NETWORK_INTERFACE=$(ip link | awk -F': ' '$0 !~ "lo|virbr|docker|br-|^[^0-9]"{print $2;getline}' | head -n 1)

# 如果没有找到网络接口，则退出
if [ -z "$NETWORK_INTERFACE" ]; then
    echo "没有找到有效的网络接口。"
    exit 1
fi

# 流量阈值 (1.8TB in MiB)
THRESHOLD=1843200

# 脚本名称
SCRIPT_NAME="check_traffic.sh"

# 脚本的完整路径
SCRIPT_PATH="/root/${SCRIPT_NAME}"

# 检测网卡是否存在
if ! ip a show $NETWORK_INTERFACE &> /dev/null; then
    echo "网卡 ${NETWORK_INTERFACE} 不存在。"
    exit 1
fi

# 检查 vnstat 是否安装
if ! command -v vnstat &> /dev/null; then
    echo "vnstat 未安装，正在安装..."
    sudo apt-get update
    sudo apt-get install -y vnstat
    # 初始化 vnStat 数据库
    sudo vnstat -u -i $NETWORK_INTERFACE
    sudo systemctl start vnstat
    sudo systemctl enable vnstat
fi

# 检查计划任务是否存在
if ! crontab -l | grep -q "$SCRIPT_NAME"; then
    echo "添加计划任务..."
    (crontab -l 2>/dev/null; echo "*/10 * * * * $SCRIPT_PATH") | crontab -
fi

# 检查流量并停止服务的函数
check_traffic() {
    # 使用vnstat --json获取本月发送数据量
    local current_usage=$(vnstat -i $NETWORK_INTERFACE --json m | jq '.interfaces[0].traffic.month[0].tx')

    # 将字节转换为MiB
    current_usage=$(echo "$current_usage / 1024 / 1024" | bc)

    if [ "$current_usage" -ge "$THRESHOLD" ]; then
        systemctl stop XrayR.service
    fi
}

# 调用检查流量函数
check_traffic
