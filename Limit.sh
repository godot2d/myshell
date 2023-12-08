#!/bin/bash

# 获取总内存（以MB为单位）和计算90%
total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
ninety_percent_mem=$((total_mem * 80 / 100 / 1024))

# 获取CPU核心数量
cpu_cores=$(grep -c ^processor /proc/cpuinfo)

# 假设每个核心的CPUShares为1024，计算总的CPUShares并取90%
total_cpu_shares=$((1024 * cpu_cores))
ninety_percent_cpu=$((total_cpu_shares * 90 / 100))

# 文件路径
service_file="/etc/systemd/system/XrayR.service"

# 检查并插入/更新 MemoryLimit
if grep -q "MemoryLimit" $service_file; then
    # 更新现有的MemoryLimit
    sed -i "s/MemoryLimit=.*/MemoryLimit=${ninety_percent_mem}M/" $service_file
else
    # 插入新的MemoryLimit
    sed -i "/\[Service\]/a MemoryLimit=${ninety_percent_mem}M" $service_file
fi

# 检查并插入/更新 CPUShares
if grep -q "CPUShares" $service_file; then
    # 更新现有的CPUShares
    sed -i "s/CPUShares=.*/CPUShares=${ninety_percent_cpu}/" $service_file
else
    # 插入新的CPUShares
    sed -i "/\[Service\]/a CPUShares=${ninety_percent_cpu}" $service_file
fi

# 重新加载systemd并重启服务
systemctl daemon-reload
systemctl restart XrayR.service
