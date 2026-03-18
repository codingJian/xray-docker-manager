# 🚀 Xray-Docker-Manager

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Supported-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue.style=for-the-badge)

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
bash <(curl -sL [https://raw.githubusercontent.com/codingjian/xray-docker-manager/main/install.sh](https://raw.githubusercontent.com/codingjian/xray-docker-manager/main/install.sh))
