#!/bin/bash

# 定义全局颜色
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RED="\033[31m"
RESET="\033[0m"

# 全局路径定义
BASE_DIR="/root/xray-docker"

# 公共函数：获取服务器公网 IP
get_public_ip() {
    IP=$(curl -s4 ifconfig.me)
    if [ -z "$IP" ]; then
        IP=$(curl -s6 ifconfig.me)
    fi
    echo "$IP"
}

# 公共函数：打印分隔线
print_line() {
    echo -e "${CYAN}======================================================${RESET}"
}