#!/bin/bash

# ==========================================
# 模块：Xray REALITY 核心业务逻辑
# ==========================================

# 实际执行 Docker 部署的底层核心函数
deploy_instance_core() {
    local INSTANCE=$1
    local PORT=$2
    local DEST=$3
    local SNI=$4
    local STRATEGY=$5

    local WORK_DIR="${BASE_DIR}/${INSTANCE}"
    local KEY_FILE="${WORK_DIR}/UUID-key.txt"
    local ENV_FILE="${WORK_DIR}/.xray_env"

    mkdir -p "$WORK_DIR"
    # 日志目录与权限管理
    mkdir -p "$WORK_DIR/logs"
    chown 65534:65534 "$WORK_DIR/logs"  # 解决容器内 nobody 用户的写入权限问题
    
    # 检查并生成密钥
    if [ ! -f "$KEY_FILE" ]; then
        echo -e "${CYAN}正在生成新的 UUID 和 x25519 密钥对...${RESET}"
        UUID=$(docker run --rm ghcr.io/xtls/xray-core uuid)
        KEYS=$(docker run --rm ghcr.io/xtls/xray-core x25519)
        PRIVATE_KEY=$(echo "$KEYS" | grep "Private key:" | awk '{print $3}')
        PUBLIC_KEY=$(echo "$KEYS" | grep "Public key:" | awk '{print $3}')
        
        echo "UUID: $UUID" > "$KEY_FILE"
        echo "Private key: $PRIVATE_KEY" >> "$KEY_FILE"
        echo "Public key: $PUBLIC_KEY" >> "$KEY_FILE"
    fi
    
    # 读取密钥
    local UUID=$(grep "UUID" "$KEY_FILE" | awk '{print $2}')
    local PRIVATE_KEY=$(grep "Private key" "$KEY_FILE" | awk '{print $3}')
    local PUBLIC_KEY=$(grep "Public key" "$KEY_FILE" | awk '{print $3}')

    # 保存环境参数供日后读取
    cat > "$ENV_FILE" <<EOF
PORT=$PORT
DEST=$DEST
SNI=$SNI
DOMAIN_STRATEGY=$STRATEGY
EOF

    echo -e "${CYAN}正在生成配置...${RESET}"
    # 生成 config.json
    cat > "${WORK_DIR}/config.json" <<EOF
{
  "log": {
    "loglevel": "warning", 
    "access": "/etc/xray/logs/access.log",
    "error": "/etc/xray/logs/error.log"
  },
  "dns": {"servers": ["https+local://1.1.1.1/dns-query", "1.1.1.1", "8.8.8.8", "localhost"]},
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "tag": "vless_reality",
      "settings": {
        "clients": [{"id": "$UUID", "flow": "xtls-rprx-vision"}],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "$DEST",
          "serverNames": ["$SNI"],
          "privateKey": "$PRIVATE_KEY", 
          "shortIds": ["1a", "2b"]
        }
      },
      "sniffing": {"enabled": true, "destOverride": ["http", "tls", "quic"], "routeOnly": true}
    }
  ],
  "outbounds": [
    {"protocol": "freedom", "tag": "direct", "settings": {"domainStrategy": "$STRATEGY"}},
    {"protocol": "blackhole", "tag": "block"}
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {"type": "field", "ip": ["geoip:private", "geoip:cn"], "outboundTag": "block"},
      {"type": "field", "domain": ["geosite:category-ads-all"], "outboundTag": "block"},
      {"type": "field", "protocol": ["bittorrent"], "outboundTag": "block"}
    ]
  }
}
EOF

    # 生成 docker-compose.yml
    cat > "${WORK_DIR}/docker-compose.yml" <<EOF
services:
  xray:
    image: ghcr.io/xtls/xray-core:latest
    container_name: xray-${INSTANCE}
    restart: always
    network_mode: "host" 
    volumes:
      - ./config.json:/etc/xray/config.json:ro
      - ./logs:/etc/xray/logs:rw
    command: run -c /etc/xray/config.json
EOF

    echo -e "${CYAN}正在启动 $INSTANCE 容器...${RESET}"
    cd "$WORK_DIR" || exit
    docker compose down &>/dev/null
    docker compose up -d

    echo -e "${GREEN}✅ 部署完成！${RESET}"
    show_client_info "$INSTANCE"
}

# 菜单选项 1：创建新实例
deploy_reality_instance() {
    # 确保 Docker 已经安装（调用 core.sh 或这里直接检查）
    if ! command -v docker &> /dev/null; then
        echo -e "${CYAN}正在为您安装 Docker...${RESET}"
        curl -fsSL https://get.docker.com | bash
        systemctl enable docker && systemctl start docker
    fi

    echo ""
    read -e -p "请输入要开放的端口 [默认 443]: " PORT
    PORT=${PORT:-443}

    read -e -p "请输入实例名称 [默认 vless-reality-${PORT}]: " INSTANCE_NAME
    INSTANCE_NAME=${INSTANCE_NAME:-vless-reality-${PORT}}

    if [ -d "${BASE_DIR}/${INSTANCE_NAME}" ]; then
        echo -e "${RED}❌ 错误：该实例名称 (${INSTANCE_NAME}) 已存在！${RESET}"
        sleep 2
        return
    fi

    read -e -p "请输入伪装目标 dest [默认 learn.microsoft.com:443]: " DEST
    DEST=${DEST:-learn.microsoft.com:443}
    read -e -p "请输入服务器名称 SNI [默认 learn.microsoft.com]: " SNI
    SNI=${SNI:-learn.microsoft.com}
    read -e -p "是否优先使用 IPv6? (y/n) [默认 y]: " IPV6_CHOICE
    if [[ "$IPV6_CHOICE" == "n" || "$IPV6_CHOICE" == "N" ]]; then
        STRATEGY="AsIs"
    else
        STRATEGY="UseIPv6"
    fi

    deploy_instance_core "$INSTANCE_NAME" "$PORT" "$DEST" "$SNI" "$STRATEGY"
    
    echo -e "${CYAN}按回车键返回主菜单...${RESET}"
    read -r
}

# 辅助函数：选择实例
select_instance() {
    local instances=($(find "$BASE_DIR" -mindepth 2 -maxdepth 2 -name "UUID-key.txt" -exec dirname {} \; | xargs -n 1 basename 2>/dev/null))
    if [ ${#instances[@]} -eq 0 ]; then
        echo -e "${YELLOW}当前没有检测到任何 Xray 实例。${RESET}"
        sleep 2
        return 1
    fi
    echo -e "${CYAN}========== 当前运行的实例 ==========${RESET}"
    for i in "${!instances[@]}"; do
        echo -e "  ${YELLOW}$((i+1)).${RESET} ${instances[$i]}"
    done
    echo -e "${CYAN}====================================${RESET}"
    read -e -p "请输入对应的序号选择实例 (按0返回): " idx
    if [[ "$idx" == "0" ]]; then return 1; fi
    if ! [[ "$idx" =~ ^[0-9]+$ ]] || [ "$idx" -lt 1 ] || [ "$idx" -gt "${#instances[@]}" ]; then
        echo -e "${RED}输入无效！${RESET}"
        sleep 1
        return 1
    fi
    SELECTED_INSTANCE="${instances[$((idx-1))]}"
    return 0
}

# 显示客户端信息 (新增一键链接拼接功能)
show_client_info() {
    local INSTANCE=$1
    local WORK_DIR="${BASE_DIR}/${INSTANCE}"
    local KEY_FILE="${WORK_DIR}/UUID-key.txt"
    local ENV_FILE="${WORK_DIR}/.xray_env"

    if [ ! -f "$KEY_FILE" ] || [ ! -f "$ENV_FILE" ]; then
        echo -e "${RED}未找到实例配置！${RESET}"
        return
    fi

    source "$ENV_FILE"
    local UUID=$(grep "UUID" "$KEY_FILE" | awk '{print $2}')
    local PUBLIC_KEY=$(grep "Public key" "$KEY_FILE" | awk '{print $3}')
    local IP=$(get_public_ip)

    echo ""
    echo -e "${YELLOW}======================================================${RESET}"
    echo -e "${CYAN} 📱 实例 [ ${INSTANCE} ] 的连接参数如下：${RESET}"
    echo -e "${YELLOW}======================================================${RESET}"
    echo -e " 🌐 地址 (Address)       : ${GREEN}${IP}${RESET}"
    echo -e " 🔌 端口 (Port)          : ${GREEN}${PORT}${RESET}"
    echo -e " 🔑 用户ID (UUID)        : ${GREEN}${UUID}${RESET}"
    echo -e " 🌊 流控 (Flow)          : ${GREEN}xtls-rprx-vision${RESET}"
    echo -e " 📡 传输协议 (Network)   : ${GREEN}tcp${RESET}"
    echo -e " 🔒 底层安全 (TLS)       : ${GREEN}reality${RESET}"
    echo -e " 🏷️  SNI (服务器名称)    : ${GREEN}${SNI}${RESET}"
    echo -e " 🆔 公钥 (PublicKey)     : ${GREEN}${PUBLIC_KEY}${RESET}"
    echo -e " 🤏 短ID (ShortId)       : ${GREEN}1a${RESET}"
    echo -e " 🛡️  指纹 (Fingerprint)  : ${GREEN}chrome${RESET}"
    echo -e "${YELLOW}======================================================${RESET}"
    
    # 拼接一键导入链接
    local VLESS_LINK="vless://${UUID}@${IP}:${PORT}?security=reality&sni=${SNI}&fp=chrome&pbk=${PUBLIC_KEY}&sid=1a&type=tcp&flow=xtls-rprx-vision#${INSTANCE}"
    echo -e "🔗 一键导入链接 (复制到 v2rayN/v2rayNG 等客户端): \n${GREEN}${VLESS_LINK}${RESET}"
    echo -e "${YELLOW}======================================================${RESET}"
}

# 修改实例
reconfigure_instance() {
    local INSTANCE=$1
    local WORK_DIR="${BASE_DIR}/${INSTANCE}"
    source "${WORK_DIR}/.xray_env"
    echo -e "${CYAN}正在重新配置实例 [ $INSTANCE ]... (直接回车保持旧配置)${RESET}"
    read -e -p "请输入新端口 [当前 $PORT]: " NEW_PORT
    PORT=${NEW_PORT:-$PORT}
    read -e -p "请输入新 dest [当前 $DEST]: " NEW_DEST
    DEST=${NEW_DEST:-$DEST}
    read -e -p "请输入新 SNI [当前 $SNI]: " NEW_SNI
    SNI=${NEW_SNI:-$SNI}
    read -e -p "是否优先使用 IPv6? (y/n) [当前策略 $DOMAIN_STRATEGY]: " NEW_IPV6
    if [[ "$NEW_IPV6" == "n" || "$NEW_IPV6" == "N" ]]; then
        DOMAIN_STRATEGY="AsIs"
    elif [[ "$NEW_IPV6" == "y" || "$NEW_IPV6" == "Y" ]]; then
        DOMAIN_STRATEGY="UseIPv6"
    fi
    deploy_instance_core "$INSTANCE" "$PORT" "$DEST" "$SNI" "$DOMAIN_STRATEGY"
}

# 菜单选项 2：管理实例面板
manage_reality_menu() {
    if ! select_instance; then return; fi
    while true; do
        clear
        echo ""
        echo -e "${CYAN}>>> 当前管理实例: ${YELLOW}${SELECTED_INSTANCE}${RESET}"
        echo -e "  ${YELLOW}1.${RESET} 👁️  查看此实例配置与一键链接"
        echo -e "  ${YELLOW}2.${RESET} ⚙️  修改此实例配置 (更改端口/伪装域名等)"
        echo -e "  ${YELLOW}3.${RESET} 🔄 更新此实例 Xray 核心"
        echo -e "  ${YELLOW}4.${RESET} 🗑️  彻底卸载此实例"
        echo -e "  ${YELLOW}0.${RESET} ↩️  返回主菜单"
        echo -e "${CYAN}------------------------------------------------------${RESET}"
        read -e -p "请选择操作 [0-4]: " SUB_CHOICE

        case $SUB_CHOICE in
            1) show_client_info "$SELECTED_INSTANCE"; echo -e "\n按回车键继续..."; read -r ;;
            2) reconfigure_instance "$SELECTED_INSTANCE"; echo -e "\n按回车键继续..."; read -r ;;
            3) 
               echo -e "${CYAN}正在拉取更新...${RESET}"
               cd "${BASE_DIR}/${SELECTED_INSTANCE}" && docker compose pull && docker compose up -d
               echo -e "${GREEN}✅ 更新完成！${RESET}"; sleep 2 ;;
            4) 
               read -e -p "⚠️ 确定删除 [ $SELECTED_INSTANCE ] 吗？(y/n): " DEL_CHOICE
               if [[ "$DEL_CHOICE" == "y" || "$DEL_CHOICE" == "Y" ]]; then
                   cd "${BASE_DIR}/${SELECTED_INSTANCE}" && docker compose down
                   rm -rf "${BASE_DIR}/${SELECTED_INSTANCE}"
                   echo -e "${GREEN}已彻底销毁！${RESET}"; sleep 2; break
               fi ;;
            0) break ;;
            *) echo -e "${RED}无效输入！${RESET}"; sleep 1 ;;
        esac
    done
}