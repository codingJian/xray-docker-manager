# 🚀 Xray-Docker-Manager

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Supported-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![License](https://img.shields.io/badge/License-AGPL%20v3-blue?style=for-the-badge)

> A smart, multi-instance Docker manager for Xray REALITY (VLESS+Vision).
> 基于 Docker 的 Xray REALITY (VLESS) 多实例智能管理脚本，支持一键部署、修改参数与无缝热更新。

---

## ✨ 核心特性 / Features

- 🐳 **纯净 Docker 部署**：不污染宿主机环境，所有的运行和配置均在容器中进行。
- 🔀 **多实例平行运行**：支持在同一台服务器上开启多个端口、绑定不同域名的完全独立的 Xray 节点。
- 🔐 **极致安全**：私钥仅存留在本地文件中，终端面板仅展示客户端必需的公钥和配置，防泄漏。
- ⚡ **智能无缝热更新**：一键拉取官方最新镜像并重启容器，节点升级闪断时间小于 2 秒。
- 🛠️ **全交互式 UI**：友好的命令行菜单，小白也能轻松修改端口、伪装域名 (SNI) 和 IPv6 路由策略。

## 📦 一键安装与运行 / Quick Start

请确保您的服务器为 Linux 系统（推荐 Ubuntu/Debian），并使用 `root` 用户登录。执行以下命令即可启动交互式管理面板：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/codingJian/xray-docker-manager/main/install.sh)
```

安装完成后，系统将自动创建配置目录 `/opt/xray-manager`，并生成快捷命令 `xray-manager`。

---

## 🛠️ 使用指南 / Usage

### 启动管理面板
安装完成后，在终端输入以下任意命令即可进入交互式管理菜单：
```bash
xray-manager
# 或
/opt/xray-manager/manage.sh
```

### 主要功能模块
在管理面板中，您可以轻松完成以下操作：

1. **创建新实例**：自定义端口、域名 (SNI)，自动生成 Xray REALITY 配置。
2. **查看节点信息**：获取客户端所需的分享链接 (VLESS+Vision)，私钥不会显示在屏幕上。
3. **修改配置**：动态调整端口、路由规则 (IPv4/IPv6)、目标网站等参数，修改后自动热重载。
4. **删除实例**：安全移除指定端口的容器及配置文件。
5. **更新核心**：一键拉取最新官方镜像并重启所有实例，实现无缝升级。

---

## 📂 目录结构与存储 / Directory Structure

所有数据均持久化存储在宿主机的 `/opt/xray-manager` 目录下：

```
/opt/xray-manager/
├── manage.sh          # 主管理脚本 (可通过 xray-manager 命令调用)
├── instances/         # 存放各实例的独立配置
│   ├── {port}_config.json  # Xray 配置文件
│   └── {port}_key.pem      # REALITY 私钥文件 (请注意备份与权限保护)
└── logs/              # 容器运行日志
```

> 💡 **提示**：重装系统前请务必备份 `/opt/xray-manager` 目录，否则配置将丢失。

---

## 🔥 高级功能 / Advanced Features

- **防火墙自动管理**：脚本会自动检测并配置 `ufw` 或 `firewalld`，放行节点端口，无需手动操作。
- **BBR 加速优化**：内置 TCP BBR 拥塞控制算法开启选项，提升网络吞吐性能。
- **证书管理**：支持自动申请与更新 TLS 证书（如需配合 Nginx/Caddy 使用）。
- **多用户隔离**：每个实例拥有独立的配置文件与私钥，互不干扰。

---

## 🗑️ 卸载方法 / Uninstall

如需彻底移除本管理器及所有实例，请执行：

```bash
/opt/xray-manager/uninstall.sh
```

卸载程序将：
1. 停止并删除所有相关的 Docker 容器。
2. 清理 `/opt/xray-manager` 目录下的所有配置文件。
3. 移除 `xray-manager` 快捷命令。

> ⚠️ **警告**：卸载操作不可逆，所有节点配置将被永久删除，请谨慎操作。

---

## 📄 许可证 / License

本项目采用 AGPL v3 许可证。详见 [LICENSE](LICENSE) 文件。
