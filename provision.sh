#!/bin/bash
set -euo pipefail

# ==============================
# 基础变量
# ==============================
SSH_USER="admin"
SSH_PORT=6522
LOG_FILE="/var/log/provision.log"

export DEBIAN_FRONTEND=noninteractive

log() {
  echo -e "\033[1;32m[INFO]\033[0m $1"
  echo "[INFO] $1" >> $LOG_FILE
}

# ==============================
# root 检查
# ==============================
if [ "$EUID" -ne 0 ]; then
  echo "❌ 请用 root 执行"
  exit 1
fi

log "🚀 开始 provision（系统层）"

# ==============================
# 系统更新
# ==============================
log "📦 更新系统"
apt update -y
apt upgrade -y -o Dpkg::Options::="--force-confnew"

# ==============================
# 基础工具（只保留必要）
# ==============================
log "🔧 安装基础工具"
apt install -y \
  sudo curl wget git vim unzip htop net-tools \
  ca-certificates gnupg lsb-release zsh

# ==============================
# 时区
# ==============================
timedatectl set-timezone Asia/Tokyo

# ==============================
# Docker
# ==============================
if ! command -v docker &>/dev/null; then
  log "🐳 安装 Docker"
  apt install -y docker.io docker-compose
fi

systemctl enable docker
systemctl restart docker
usermod -aG docker $SSH_USER

# ==============================
# Nginx
# ==============================
if ! command -v nginx &>/dev/null; then
  log "🌐 安装 Nginx"
  apt install -y nginx
fi

systemctl enable nginx
systemctl restart nginx

# ==============================
# Fail2ban
# ==============================
log "🛡️ 配置 Fail2ban"

apt install -y fail2ban

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

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/*access.log
maxretry = 5

[nginx-botsearch]
enabled = true
port = http,https
logpath = /var/log/nginx/*access.log
maxretry = 5

[recidive]
enabled = true
logpath = /var/log/fail2ban.log
bantime = 2592000
findtime = 86400
maxretry = 3
EOF

systemctl enable fail2ban
systemctl restart fail2ban

# ==============================
# Node + PM2（可选基础设施）
# ==============================
if ! command -v node &>/dev/null; then
  log "🟢 安装 Node.js"
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt install -y nodejs
fi

npm install -g pm2

# ==============================
# 清理
# ==============================
apt autoremove -y
apt clean

log "✅ provision（系统层）完成"
