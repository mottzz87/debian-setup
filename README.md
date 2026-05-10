# 🚀 Debian Server Bootstrap & Provision System

一套用于快速初始化、加固与部署 Debian 服务器环境的脚本系统。

适用于：

- VPS / 云服务器初始化
- Node.js / Docker 项目部署
- Nginx 反向代理
- 个人生产环境
- 小型 SaaS / API 服务

支持：

- Debian 12 / 13
- Oracle Cloud
- AWS EC2
- Vultr / RackNerd 等 VPS

---

# ✨ 特性

## 🔐 安全优先

- 禁止 root SSH 登录
- SSH 端口修改
- Fail2ban 自动封禁
- Nginx 扫描拦截
- 默认空站点 444
- 常见扫描器 / 恶意请求拦截
- Cloudflare Real IP 支持

---

## 🧱 基础设施自动化

自动安装：

- Docker
- Docker Compose
- Nginx
- Node.js LTS
- PM2
- Fail2ban

---

## 💻 开发体验优化

可选用户层优化：

- Zsh
- Oh My Zsh
- zoxide
- fzf
- alias
- fnm

---

## 🔄 幂等设计（可重复执行）

支持：

- 新服务器初始化
- 老服务器同步配置
- 更新安全规则
- 更新 nginx 配置
- 更新 fail2ban 规则

不会重复安装已有组件。

---

# 🧠 架构设计

本项目采用分层结构：

| 层级 | 脚本 | 作用 |
|---|---|---|
| 🔐 安全层 | `init.sh` | SSH / 用户 / 防火墙初始化 |
| 🧱 基础设施层 | `provision.sh` | Docker / Nginx / Fail2ban / Node |
| 💻 用户层 | `user.sh` | Shell / Alias / 开发体验 |
| 🚀 应用层 | `deploy.sh` | 部署具体业务 |

---

# 📁 项目结构

```bash
debian-setup/
├── init.sh
├── provision.sh
├── user.sh
│
├── nginx/
│   ├── nginx.conf
│   └── security/
│       ├── http/
│       │   ├── bad_bot.conf
│       │   ├── cloudflare_real_ip.conf
│       │   ├── rate_limit.conf
│       │   └── security.conf
│       │
│       └── server/
│           └── block_ip_access.conf
│
├── fail2ban/
│   ├── jail.local
│   └── filter.d/
│       ├── nginx-444.conf
│       ├── nginx-aggressive.conf
│       ├── nginx-api-auth.conf
│       └── nginx-scanner.conf
│
└── deploy.sh
```

---

# 🚀 快速开始

## 1️⃣ 初始化服务器（仅一次）

```bash
bash init.sh
```

完成后：

```bash
ssh -p <port> admin@your-server-ip
```

---

## 2️⃣ 安装基础设施

```bash
sudo bash provision.sh
```

---

## 3️⃣ 配置用户环境（可选）

```bash
sudo bash user.sh
```

---

## 4️⃣ 重新登录

```bash
exit
ssh -p <port> admin@your-server-ip
```

---

# 🔄 更新服务器配置

后续如果：

- 更新 nginx 规则
- 更新 fail2ban 规则
- 更新 provision.sh
- 更新安全策略

只需要重新执行：

```bash
curl -fsSL https://raw.githubusercontent.com/mottzz87/debian-setup/refs/heads/main/provision.sh -o provision.sh \
&& chmod +x provision.sh \
&& sudo bash provision.sh
```

即可自动同步最新配置。

---

# 🧱 provision.sh 做了什么？

## 📦 基础工具

安装：

- git
- curl
- wget
- vim
- htop
- zsh
- unzip
- net-tools

---

## 🐳 Docker

自动安装：

- docker.io
- docker-compose

并：

- enable 开机启动
- admin 加入 docker 组

---

## 🌐 Nginx

自动：

- 安装 nginx
- 覆盖 nginx.conf
- 同步 security 规则
- 删除 Debian 默认站点
- 启动 nginx

---

## 🛡️ Fail2ban

自动：

- 安装 fail2ban
- 同步 jail.local
- 同步 filter.d
- 启动防暴力破解规则

---

## 🟢 Node.js

自动安装：

- Node.js 20 LTS

---

## 📦 PM2

自动安装：

```bash
npm install -g pm2
```

---

# 🔐 Nginx 安全规则

## 🌐 默认空站点拦截

```nginx
server {
    listen 80 default_server;
    return 444;
}
```

作用：

- 没有绑定域名时直接断开连接
- 避免暴露默认页面
- 拦截 IP 直接访问

---

## 🤖 Bad Bot 拦截

自动拦截：

- sqlmap
- nikto
- nmap
- masscan
- zgrab
- dirbuster

---

## 🚫 敏感文件保护

自动拦截：

- .env
- .git
- .sql
- .yml
- docker-compose.yml
- package.json
- node_modules

---

## 🔥 扫描路径拦截

自动拦截：

- wp-admin
- phpmyadmin
- xmlrpc.php
- vendor
- storage

---

## ☁️ Cloudflare Real IP

支持：

```nginx
real_ip_header CF-Connecting-IP;
```

自动恢复真实用户 IP。

---

# 🛡️ Fail2ban 规则

默认启用：

| Jail | 作用 |
|---|---|
| sshd | SSH 防爆破 |
| nginx-scanner | 扫描器封禁 |
| nginx-api-auth | API 爆破 |
| nginx-aggressive | 高频恶意请求 |
| recidive | 累犯永久封禁 |

---

# 🧪 测试安全规则

## 测试 nginx 444

```bash
curl http://your-ip/.env
```

预期：

```bash
curl: (52) Empty reply from server
```

说明：

- nginx 返回 444
- 连接被直接断开

---

## 测试 Fail2ban

查看状态：

```bash
fail2ban-client status
```

查看具体 jail：

```bash
fail2ban-client status nginx-scanner
```

查看日志：

```bash
tail -f /var/log/fail2ban.log
```

---

# 🔑 权限模型

遵循标准 Linux 安全模型：

- ❌ root 直接登录
- ✅ admin 用户登录
- ✅ sudo 提权

示例：

```bash
sudo systemctl restart nginx
```

进入 root：

```bash
sudo -i
```

---

# ⚠️ 注意事项

## init.sh 仅执行一次

因为会修改：

- SSH 配置
- root 登录
- 防火墙

---

## provision.sh 可重复执行

安全：

- 可同步最新配置
- 可更新规则
- 可修复环境

---

## nginx.conf 会被覆盖

因此：

自定义配置应放到：

```bash
/etc/nginx/conf.d/
```

不要直接修改：

```bash
/etc/nginx/nginx.conf
```

---

# 🚀 后续扩展建议

可以继续扩展：

- Let's Encrypt 自动 HTTPS
- Docker Compose 模板
- CI/CD 自动部署
- Prometheus
- Grafana
- Loki
- Uptime Kuma
- 自动备份
- rsync
- S3 Backup

---

# 🧠 设计目标

这个项目的目标不是：

> “一次性脚本”

而是：

- 可维护
- 可扩展
- 可重复执行
- 可版本化
- 可长期运营

---

# 📄 License

MIT