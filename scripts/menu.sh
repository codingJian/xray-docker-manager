#!/bin/bash

# 动态引入其他功能模块
source "${LOCAL_DIR}/scripts/xray_reality.sh"
source "${LOCAL_DIR}/scripts/firewall.sh"
source "${LOCAL_DIR}/scripts/bbr.sh"

show_main_menu() {
    while true; do
        clear
        echo ""
        print_line
        echo -e "${GREEN}  🚀 Xray-Docker-Manager (多功能瑞士军刀面板)${RESET}"
        print_line
        echo -e "  ${YELLOW}1.${RESET} ➕ 创建 Xray REALITY 多实例节点"
        echo -e "  ${YELLOW}2.${RESET} ⚙️  管理/修改已有实例 (含 VLESS 链接分享)"
        echo -e "  ${YELLOW}3.${RESET} 🛡️  防火墙管理 (开放端口 / 屏蔽 BT 种子)"
        echo -e "  ${YELLOW}4.${RESET} 🚀 一键开启 BBR 核心网络加速"
        echo -e "  ${YELLOW}5.${RESET} 🔐 TLS 证书管理 (acme.sh 独立功能)"
        echo -e "  ${YELLOW}6.${RESET} 🧹 系统清理与卸载"
        echo -e "  ${YELLOW}0.${RESET} ❌ 退出脚本"
        print_line
        
        read -e -p "请选择操作 [0-6]: " MAIN_CHOICE

        case $MAIN_CHOICE in
            1) deploy_reality_instance ;;  # 函数定义在 xray_reality.sh
            2) manage_reality_menu ;;      # 函数定义在 xray_reality.sh
            3) manage_firewall_menu ;;     # 函数定义在 firewall.sh
            4) enable_bbr ;;               # 函数定义在 bbr.sh
            5) echo "开发中..." ; sleep 2 ;;
            6) uninstall_all ;;
            7)  # 更新面板逻辑
               clear
               echo -e "${CYAN}正在拉取最新版本的面板代码...${RESET}"
               bash <(curl -fsSL https://raw.githubusercontent.com/codingJian/xray-docker-manager/main/install.sh)
               exit 0
               ;;
            0) echo -e "${CYAN}感谢使用，再见！${RESET}"; exit 0 ;;
            *) echo -e "${RED}无效输入！${RESET}"; sleep 1 ;;
        esac
    done
}