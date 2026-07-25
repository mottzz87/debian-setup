# 🚀 Debian Server Bootstrap & Provision System

一套用于快速初始化、加固与部署 Debian 服务器环境的自动化脚本。

适用于：

- VPS / 云服务器初始化
- Debian 开发环境
- Docker / Node.js 服务部署
- Nginx 反向代理
- 个人生产环境
- 小型 SaaS / API 服务

支持：

- Debian 12 / 13
- Oracle Cloud
- AWS EC2
- Vultr
- RackNerd
- 其它 Debian 系 VPS

---

# ✨ 特性

## 🔐 安全优先

自动完成：

- 禁止 root SSH 登录
- 创建管理员用户
- SSH 公钥登录
- 修改 SSH 端口
- UFW 防火墙
- Fail2ban 防爆破（Full Profile）
- Cloudflare Real IP（Full Profile）

---

## 🧱 基础环境

自动安装：

- Git
- Curl
- Zsh
- eza
- bat
- fastfetch
- zoxide
- fzf
- ripgrep
- fd
- htop
- btop

---

## 🚀 Full Profile

额外安装：

- Docker
- Docker Compose
- Nginx
- Fail2ban
- Node.js LTS

适用于生产服务器。

---

## 💻 Shell 优化

自动配置：

- Oh My Zsh
- zsh-autosuggestions
- zsh-syntax-highlighting
- zoxide
- fzf
- 常用 Alias
- Fastfetch

---

## 🔄 幂等设计

支持重复执行：

- 更新配置
- 修复环境
- 新增插件
- 更新安全规则

不会重复安装已有组件。

---

# 🧠 架构

```
install.sh
        │
        ▼
ssh-init.sh
        │
        ▼
provision-base.sh
        │
        ├──────────────┐
        ▼              │
root-init.sh          │
        │              │
        ▼              │
user-init.sh          │
                       │
PROFILE=full          │
        │              │
        ▼              │
provision-service.sh ──┘
```

---

# 📁 项目结构

```text
debian-setup/
├── install.sh
├── ssh-init.sh
├── provision-base.sh
├── provision-service.sh
├── root-init.sh
├── user-init.sh
│
├── nginx/
├── fail2ban/
└── README.md
```

---

# 🚀 快速开始

## Minimal（推荐开发服务器）

仅安装：

- SSH
- 基础工具
- Zsh
- Shell 环境

```bash
apt-get update && \
apt-get install -y curl && \
PROFILE=minimal \
SSH_PUBKEY="YOUR_PUBLIC_KEY" \
SSH_PASSWORD="YOUR_PASSWORD" \
ENABLE_NOPASSWD=true \
bash <(curl -fsSL https://raw.githubusercontent.com/mottzz87/debian-setup/main/install.sh)
```

---

## Full（推荐生产服务器）

额外安装：

- Docker
- Nginx
- Fail2ban
- Node.js

```bash
apt-get update && \
apt-get install -y curl && \
PROFILE=full \
SSH_PUBKEY="YOUR_PUBLIC_KEY" \
SSH_PASSWORD="YOUR_PASSWORD" \
ENABLE_NOPASSWD=true \
bash <(curl -fsSL https://raw.githubusercontent.com/mottzz87/debian-setup/main/install.sh)
```

---

# ⚙️ 可用环境变量

| 变量 | 默认值 | 说明 |
|-------|--------|------|
| PROFILE | full | full / minimal |
| SSH_USER | admin | SSH 用户 |
| SSH_PORT | 6522 | SSH 端口 |
| SSH_PUBKEY | - | SSH 公钥 |
| SSH_PASSWORD | - | 用户密码 |
| ENABLE_NOPASSWD | false | 是否开启免密码 sudo |
| TIMEZONE | Asia/Tokyo | 系统时区 |

例如：

```bash
PROFILE=minimal \
SSH_USER=clark \
SSH_PORT=2222 \
TIMEZONE=Asia/Shanghai \
...
```

---

# 📦 Profile 对比

| 功能 | Minimal | Full |
|------|:-------:|:----:|
| SSH 初始化 | ✅ | ✅ |
| 基础工具 | ✅ | ✅ |
| Oh My Zsh | ✅ | ✅ |
| Node.js（fnm） | ✅ | ✅ |
| Docker | ❌ | ✅ |
| Docker Compose | ❌ | ✅ |
| Nginx | ❌ | ✅ |
| Fail2ban | ❌ | ✅ |
| Cloudflare Real IP | ❌ | ✅ |

---

# 🔐 安全设计

默认：

- 禁止 Root SSH 登录
- 公钥认证
- 禁用密码 SSH 登录
- 管理员用户登录
- UFW 防火墙

Full Profile 额外启用：

- Fail2ban
- Nginx 安全规则
- 默认 444 空站点
- 常见扫描器拦截

---

# 💻 Shell Alias

普通用户：

```bash
r      # sudo -i
a     # sudo -iu admin
```

Root：

```bash
a      # su - admin
```

以及：

```bash
ll
la
l
gs
gp
gd
bat
fd
py
```

---

# 🔄 重复执行

所有脚本均支持重复执行。

例如：

```bash
PROFILE=full bash install.sh
```

即可：

- 更新基础环境
- 更新 Docker 配置
- 更新 Nginx
- 更新 Fail2ban
- 更新 Shell 配置

---

# 🧩 后续规划

- Let's Encrypt 自动申请证书
- Docker Compose 模板
- Traefik
- Prometheus
- Grafana
- Loki
- Uptime Kuma
- 自动备份
- rsync
- S3 Backup

---

# 📄 License

MIT