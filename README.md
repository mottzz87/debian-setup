# 🚀 Server Bootstrap & Provision System

一套用于快速初始化与部署服务器环境的脚本集合，适用于个人项目 / 小型生产环境（如 Web 服务、Node.js 应用、Docker 部署等）。

---

## 🧠 设计理念

本项目采用**分层设计（Layered Architecture）**：

| 层级       | 脚本              | 作用                                        |
| -------- | --------------- | ----------------------------------------- |
| 🔐 安全层   | `init.sh`       | 初始化服务器安全（SSH / 用户 / 防火墙）                  |
| 🧱 基础设施层 | `provision.sh`  | 安装系统级服务（Docker / Nginx / Fail2ban / Node） |
| 💻 用户层   | `user.sh`       | 优化开发体验（Zsh / Alias / Shell 工具）            |
| 🚀 应用层   | `deploy.sh`（可选） | 部署具体业务（如网站、API）                           |

---

## ⚙️ 适用场景

* 云服务器初始化（Oracle / AWS / VPS）
* Node.js / Docker 项目部署
* 个人开发环境标准化
* 多服务器统一配置

---

## 📦 功能概览

### 🔐 init.sh（一次性执行）

* 创建非 root 用户（如：admin）
* 配置 SSH 公钥登录
* 禁止 root 登录
* 修改 SSH 端口
* 启用防火墙（UFW）

---

### 🧱 provision.sh（可重复执行）

系统级能力：

* Docker / Docker Compose
* Nginx
* Fail2ban（防暴力破解）
* Node.js（LTS）
* PM2（进程管理）
* 基础工具（git / curl / vim 等）

---

### 💻 user.sh（可重复执行）

用户体验：

* Zsh + Oh My Zsh
* 自动补全 / 高亮插件
* 常用 alias（git / docker / sudo）
* zoxide（快速目录跳转）
* fzf（模糊搜索）
* fnm（Node 版本管理）

---

## 🚀 快速开始

### 1️⃣ 初始化服务器（只执行一次）

```bash
bash init.sh
```

👉 完成后使用新用户登录：

```bash
ssh -p <port> admin@your-server-ip
```

---

### 2️⃣ 部署基础设施

```bash
sudo bash provision.sh
```

---

### 3️⃣ 配置用户环境

```bash
sudo bash user.sh
```

---

### 4️⃣ 重新登录生效

```bash
exit
ssh -p <port> admin@your-server-ip
```

---

## 🔑 权限模型

本项目遵循标准 Linux 安全模型：

* ❌ 禁止 root 直接登录
* ✅ 使用 `admin` 用户登录
* 🔐 使用 `sudo` 进行提权

示例：

```bash
# 临时执行
sudo systemctl restart nginx

# 进入 root shell
sudo -i
```

---

## 📁 推荐目录结构

```bash
.
├── init.sh
├── provision.sh
├── user.sh
└── deploy.sh   # 可选
```

---

## 🔄 幂等性（Idempotent）

所有脚本设计为可重复执行：

* 已安装的软件不会重复安装
* 配置文件安全覆盖或检测
* 可用于新服务器 / 老服务器同步

---

## ⚠️ 注意事项

* `init.sh` 仅应执行一次（会修改 SSH 配置）
* `provision.sh` 和 `user.sh` 可安全重复执行
* 执行前请确认 SSH 公钥正确，否则可能无法登录

---

## 🛠 常用命令

```bash
# 快速提权（如果已配置 alias）
r

# Docker
dps     # docker ps
dcu     # docker compose up -d
dcd     # docker compose down

# Git
gs      # git status
gp      # git pull
```

---

## 🚀 后续扩展（建议）

你可以基于本项目继续扩展：

* 自动 HTTPS（Let's Encrypt）
* Nginx 反向代理模板
* Docker Compose 模板
* 自动部署脚本（CI/CD）
* 日志监控（Prometheus / Grafana）

---

## 🧠 设计目标

* 简单但不简陋
* 可维护而非一次性脚本
* 从“会用服务器”到“管理服务器”

---

## 📄 License

MIT

---

