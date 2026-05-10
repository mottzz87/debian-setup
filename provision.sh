#!/bin/bash
set -euo pipefail

# ==============================
# 基础变量
# ==============================
SSH_USER="admin"
SSH_PORT=6522
LOG_FILE="/var/log/provision.log"

# GitHub 仓库（建议后续改成 tag/version）
REPO_BASE_URL="https://raw.githubusercontent.com/mottzz87/debian-setup/main"

export DEBIAN_FRONTEND=noninteractive

# ==============================
# 日志函数
# ==============================
log() {
  echo -e "\033[1;32m[INFO]\033[0m $1"
  echo "[INFO] $1" >> "$LOG_FILE"
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
# 基础工具
# ==============================
log "🔧 安装基础工具"

apt install -y \
  sudo \
  curl \
  wget \
  git \
  vim \
  unzip \
  htop \
  net-tools \
  ca-certificates \
  gnupg \
  lsb-release \
  zoxide \
  zsh

# ==============================
# 时区
# ==============================
log "🕒 设置时区"

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

# 用户存在才加入 docker 组
if id "$SSH_USER" &>/dev/null; then
  usermod -aG docker "$SSH_USER"
fi

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

# 创建目录
mkdir -p /etc/fail2ban/filter.d

# ==============================
# 下载 jail.local
# ==============================
log "📥 下载 jail.local"

curl -fsSL \
  "$REPO_BASE_URL/fail2ban/jail.local" \
  -o /etc/fail2ban/jail.local

# ==============================
# 下载 filter.d
# ==============================
log "📥 下载 Fail2ban filters"

FILTERS=(
  nginx-444.conf
  nginx-aggressive.conf
  nginx-api-auth.conf
  nginx-scanner.conf
)

for file in "${FILTERS[@]}"; do
  log "⬇️ 下载 $file"

  curl -fsSL \
    "$REPO_BASE_URL/fail2ban/filter.d/$file" \
    -o "/etc/fail2ban/filter.d/$file"
done

# ==============================
# Fail2ban 配置检查
# ==============================
log "🧪 检查 Fail2ban 配置"

fail2ban-client -d >/dev/null

# ==============================
# 启动 Fail2ban
# ==============================
systemctl enable fail2ban
systemctl restart fail2ban

# ==============================
# Node.js
# ==============================
if ! command -v node &>/dev/null; then
  log "🟢 安装 Node.js"

  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -

  apt install -y nodejs
fi

# ==============================
# PM2
# ==============================
log "📦 安装 PM2"

npm install -g pm2

# ==============================
# 清理系统
# ==============================
log "🧹 清理系统"

apt autoremove -y
apt clean

# ==============================
# 完成
# ==============================
log "✅ provision（系统层）完成"