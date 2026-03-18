#!/bin/bash

# ==========================================
# 项目：Xray-Docker-Manager 引导程序
# ==========================================

# 定义的 GitHub 仓库信息
REPO_URL="https://raw.githubusercontent.com/codingJian/xray-docker-manager/main"
LOCAL_DIR="/root/.xray-manager"
SCRIPTS_DIR="${LOCAL_DIR}/scripts"

# 确保以 root 用户运行
if [ "$(id -u)" != "0" ]; then
    echo -e "\033[31m错误：请使用 root 用户运行此脚本！\033[0m"
    exit 1
fi

echo -e "\033[36m正在初始化 Xray-Docker-Manager...\033[0m"

# 1. 创建本地工作目录
mkdir -p "$SCRIPTS_DIR"

# 2. 动态下载/更新所有子模块文件 (加入时间戳防止CDN缓存)
# 这里罗列你所有的模块文件
MODULES=("core.sh" "menu.sh" "env_check.sh" "firewall.sh" "xray_reality.sh" "bbr.sh" "ssl.sh")

for module in "${MODULES[@]}"; do
    curl -sL "${REPO_URL}/scripts/${module}?t=$(date +%s)" -o "${SCRIPTS_DIR}/${module}"
    chmod +x "${SCRIPTS_DIR}/${module}"
done

# 3. 引入核心工具和菜单模块并启动主程序
source "${SCRIPTS_DIR}/core.sh"
source "${SCRIPTS_DIR}/menu.sh"

# 启动主菜单 (位于 menu.sh 中)
show_main_menu