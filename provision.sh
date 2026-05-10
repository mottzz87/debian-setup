#!/bin/bash
set -euo pipefail

# ==============================
# 基础变量
# ==============================
SSH_USER="admin"
SSH_PORT=6522

LOG_FILE="/var/log/provision.log"

PROVISION_VERSION="1.3.0"

REPO_URL="https://github.com/mottzz87/debian-setup.git"

WORKDIR="/opt/debian-setup"

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

log "🚀 开始 provision（系统层） v${PROVISION_VERSION}"

# ==============================
# 更新软件源
# ==============================
log "📦 更新软件源"

apt update -y

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
# 设置时区
# ==============================
log "🕒 设置时区"

timedatectl set-timezone Asia/Tokyo

# ==============================
# 同步仓库
# ==============================
log "📥 同步 debian-setup 仓库"

if [ ! -d "$WORKDIR/.git" ]; then

  rm -rf "$WORKDIR"

  git clone "$REPO_URL" "$WORKDIR"

else

  cd "$WORKDIR"

  git fetch origin

  git reset --hard origin/main

fi

# ==============================
# Docker
# ==============================
if ! command -v docker &>/dev/null; then
  log "🐳 安装 Docker"

  apt install -y docker.io docker-compose
fi

systemctl enable docker
systemctl restart docker

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

# 创建目录
mkdir -p /etc/nginx/security/http
mkdir -p /etc/nginx/security/server
mkdir -p /var/cache/nginx

# cache 权限
chown -R www-data:www-data /var/cache/nginx

# ==============================
# 备份 nginx.conf
# ==============================
if [ -f /etc/nginx/nginx.conf ]; then
  BACKUP_FILE="/etc/nginx/nginx.conf.bak.$(date +%F-%H%M%S)"

  log "💾 备份 nginx.conf -> $BACKUP_FILE"

  cp /etc/nginx/nginx.conf "$BACKUP_FILE"
fi

# 删除 Debian 默认站点
if [ -e /etc/nginx/sites-enabled/default ]; then
  log "🗑️ 删除默认 nginx site"

  unlink /etc/nginx/sites-enabled/default || true
  rm -f /etc/nginx/sites-enabled/default || true
fi

# ==============================
# 同步 nginx.conf
# ==============================
log "📥 同步 nginx.conf"

cp -f \
  "$WORKDIR/nginx/nginx.conf" \
  /etc/nginx/nginx.conf

# ==============================
# 同步 nginx/security/http
# ==============================
if [ -d "$WORKDIR/nginx/security/http" ]; then
  log "📥 同步 nginx security/http"

  cp -rf \
    "$WORKDIR/nginx/security/http/"* \
    /etc/nginx/security/http/
fi

# ==============================
# 同步 nginx/security/server
# ==============================
if [ -d "$WORKDIR/nginx/security/server" ]; then
  log "📥 同步 nginx security/server"

  cp -rf \
    "$WORKDIR/nginx/security/server/"* \
    /etc/nginx/security/server/
fi

# ==============================
# 检查 Nginx 配置
# ==============================
log "🧪 检查 Nginx 配置"

nginx -t

# ==============================
# 启动 Nginx
# ==============================
systemctl enable nginx
systemctl reload nginx || systemctl restart nginx

# ==============================
# Fail2ban
# ==============================
log "🛡️ 配置 Fail2ban"

apt install -y fail2ban

mkdir -p /etc/fail2ban/filter.d

# ==============================
# 同步 jail.local
# ==============================
log "📥 同步 jail.local"

cp -f \
  "$WORKDIR/fail2ban/jail.local" \
  /etc/fail2ban/jail.local

# ==============================
# 同步 filter.d
# ==============================
log "📥 同步 Fail2ban filters"

if [ -d "$WORKDIR/fail2ban/filter.d" ]; then
  cp -rf \
    "$WORKDIR/fail2ban/filter.d/"* \
    /etc/fail2ban/filter.d/
fi

# ==============================
# 检查 Fail2ban 配置
# ==============================
log "🧪 检查 Fail2ban 配置"

fail2ban-client -d >/dev/null

# ==============================
# 启动 Fail2ban
# ==============================
systemctl enable fail2ban
systemctl reload fail2ban || systemctl restart fail2ban

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
if ! command -v pm2 &>/dev/null; then
  log "📦 安装 PM2"

  npm install -g pm2
fi

# ==============================
# 清理系统
# ==============================
log "🧹 清理系统"

apt autoremove -y
apt clean

# ==============================
# 完成
# ==============================
log "✅ provision（系统层）完成 v${PROVISION_VERSION}"