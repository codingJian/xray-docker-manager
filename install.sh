#!/bin/bash

# ==========================================
# 项目：Xray-Docker-Manager 引导程序
# ==========================================

# 定义你的 GitHub 仓库信息
REPO_URL="https://raw.githubusercontent.com/codingJian/xray-docker-manager/main"
LOCAL_DIR="/opt/xray-manager"
SCRIPTS_DIR="${LOCAL_DIR}/scripts"

# 确保以 root 用户运行
if [ "$(id -u)" != "0" ]; then
    echo -e "\033[31m错误：请使用 root 用户运行此脚本！\033[0m"
    exit 1
fi

echo -e "\033[36m正在初始化 Xray-Docker-Manager...\033[0m"

# ==========================================
# 🆕 新增核心逻辑：强制清理旧的脚本缓存
# ==========================================
if [ -d "$SCRIPTS_DIR" ]; then
    echo -e "\033[33m检测到本地旧版本缓存，正在清理...\033[0m"
    rm -rf "$SCRIPTS_DIR"
fi

# 1. 重新创建干净的工作目录
mkdir -p "$SCRIPTS_DIR"

# 2. 动态下载/更新所有子模块文件 (加入时间戳防止CDN缓存)
MODULES=("core.sh" "menu.sh" "env_check.sh" "firewall.sh" "xray_reality.sh" "bbr.sh" "ssl.sh")

for module in "${MODULES[@]}"; do
    curl -fsSL "${REPO_URL}/scripts/${module}?t=$(date +%s)" -o "${SCRIPTS_DIR}/${module}"
    chmod +x "${SCRIPTS_DIR}/${module}"
done

# 3. 引入核心工具和菜单模块并启动主程序
source "${SCRIPTS_DIR}/core.sh"
source "${SCRIPTS_DIR}/menu.sh"

# 4. 创建全局快捷命令
SHORTCUT_PATH="/usr/local/bin/xray-manager"
if [ ! -f "$SHORTCUT_PATH" ]; then
    echo -e "\033[36m正在为您创建快捷命令 'xray-manager'...\033[0m"
    cat > "$SHORTCUT_PATH" << 'EOF'
#!/bin/bash
export LOCAL_DIR="/opt/xray-manager"
if [ -f "${LOCAL_DIR}/scripts/menu.sh" ]; then
    source "${LOCAL_DIR}/scripts/core.sh"
    source "${LOCAL_DIR}/scripts/menu.sh"
    show_main_menu
else
    echo -e "\033[31m❌ 找不到面板核心文件，请重新运行一键安装脚本。\033[0m"
fi
EOF
    chmod +x "$SHORTCUT_PATH"
    echo -e "\033[32m✅ 快捷命令创建成功！以后只需在终端输入 xray-manager 即可随时打开本面板！\033[0m"
fi

# 启动主菜单 (位于 menu.sh 中)
show_main_menu