#!/bin/bash

# 定义全局颜色
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RED="\033[31m"
RESET="\033[0m"

# 全局路径定义
BASE_DIR="/opt/xray-manager/instances"

# 彻底卸载与清理功能
uninstall_all() {
    echo ""
    echo -e "${RED}======================================================${RESET}"
    echo -e "${RED}⚠️ 危险操作警告：您正在进行彻底卸载！${RESET}"
    echo -e "${RED}此操作将删除：${RESET}"
    echo -e " 1. 所有正在运行的 Xray 实例容器"
    echo -e " 2. 所有的配置文件、私钥数据 (/opt/xray-manager)"
    echo -e " 3. 系统全局快捷命令 (xray-manager)"
    echo -e "${RED}======================================================${RESET}"
    
    read -e -p "您确定要继续并销毁一切吗？(输入 y 确认, 其它取消): " CONFIRM
    
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        echo -e "\n${CYAN}正在停止并移除所有实例的 Docker 容器...${RESET}"
        # 遍历实例目录，安全关闭每一个运行中的容器
        local instances=($(find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null))
        for instance_dir in "${instances[@]}"; do
            if [ -f "${instance_dir}/docker-compose.yml" ]; then
                echo -e "${YELLOW}正在停用实例: $(basename "$instance_dir")${RESET}"
                cd "$instance_dir" && docker compose down &>/dev/null
            fi
        done
        
        echo -e "${CYAN}正在删除硬盘上的所有数据与配置目录...${RESET}"
        rm -rf /opt/xray-manager
        
        echo -e "${CYAN}正在移除全局快捷命令...${RESET}"
        rm -f /usr/local/bin/xray-manager
        
        echo -e "${GREEN}✅ 彻底卸载完成！系统已恢复纯净状态，感谢您的使用！${RESET}"
        exit 0
    else
        echo -e "${GREEN}已取消卸载操作，返回主菜单。${RESET}"
        sleep 2
    fi
}

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