#!/bin/bash
set -e

SSH_USER=admin
SSH_PORT=6522

echo "=== 🚀 Provision: 系统基础设施 ==="

if [ "$EUID" -ne 0 ]; then
  echo "❌ 请用 root 运行"
  exit 1
fi

# ===== 更新 =====
apt update -y
apt upgrade -y

# ===== 基础工具 =====
apt install -y \
  sudo curl wget git vim unzip \
  build-essential ca-certificates gnupg lsb-release \
  htop tree ncdu jq

# ===== 核心服务 =====
apt install -y docker.io docker-compose nginx fail2ban

# ===== 时区 =====
timedatectl set-timezone Asia/Tokyo

# ===== Docker =====
systemctl enable docker
systemctl start docker
usermod -aG docker $SSH_USER

# ===== Nginx =====
systemctl enable nginx
systemctl restart nginx

# ===== Fail2ban（精简+安全版）=====
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1
bantime.increment = true
bantime.factor = 2
bantime.max = 2592000

[sshd]
enabled = true
port = $SSH_PORT
backend = systemd
maxretry = 6
findtime = 600
bantime = 604800

[recidive]
enabled = true
logpath = /var/log/fail2ban.log
bantime = 2592000
findtime = 86400
maxretry = 3
EOF

systemctl enable fail2ban
systemctl restart fail2ban

# ===== Node.js（LTS）=====
if ! command -v node &>/dev/null; then
  echo "🟢 安装 Node.js LTS..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
  apt install -y nodejs
fi

# ===== PM2 =====
if ! command -v pm2 &>/dev/null; then
  npm install -g pm2
fi

pm2 startup systemd -u $SSH_USER --hp /home/$SSH_USER || true

echo "=== ✅ Provision 完成 ==="
