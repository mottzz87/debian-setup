#!/bin/bash
set -euo pipefail

SSH_USER="admin"

WORKDIR="/opt/debian-setup"

LOG_FILE="/var/log/provision.log"

export DEBIAN_FRONTEND=noninteractive

log() {
  echo -e "\033[1;32m[INFO]\033[0m $1"

  echo "[INFO] $1" >> "$LOG_FILE"
}

if [ "$EUID" -ne 0 ]; then
  echo "❌ 请用 root 执行"
  exit 1
fi

log "🚀 START PROVISION"

# ==============================
# update
# ==============================
apt update -y

# ==============================
# locale
# ==============================
log "🌏 locale"

apt install -y locales

sed -i \
's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' \
/etc/locale.gen

locale-gen

update-locale LANG=en_US.UTF-8

grep -q "LANG=en_US.UTF-8" /etc/environment || \
cat >> /etc/environment <<EOF
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
EOF

# ==============================
# packages
# ==============================
log "📦 packages"

apt install -y \
  sudo \
  curl \
  wget \
  git \
  vim \
  unzip \
  htop \
  btop \
  ncdu \
  ripgrep \
  fd-find \
  eza \
  bat \
  fastfetch \
  needrestart \
  unattended-upgrades \
  net-tools \
  ca-certificates \
  gnupg \
  lsb-release \
  software-properties-common \
  apt-transport-https \
  zoxide \
  zsh \
  fzf \
  fail2ban \
  nginx \
  docker.io \
  docker-compose-plugin

# ==============================
# timezone
# ==============================
log "🕒 timezone"

timedatectl set-timezone Asia/Tokyo

# ==============================
# unattended-upgrades
# ==============================
log "🔒 unattended-upgrades"

dpkg-reconfigure -f noninteractive unattended-upgrades

# ==============================
# docker
# ==============================
log "🐳 docker"

systemctl enable docker

systemctl restart docker

if id "$SSH_USER" &>/dev/null; then

  usermod -aG docker "$SSH_USER"

  chsh -s /usr/bin/zsh "$SSH_USER" || true

fi

# ==============================
# nginx
# ==============================
log "🌐 nginx"

mkdir -p /etc/nginx/security/http

mkdir -p /etc/nginx/security/server

mkdir -p /var/cache/nginx

chown -R www-data:www-data /var/cache/nginx

if [ -f "$WORKDIR/nginx/nginx.conf" ]; then

  cp -f \
    "$WORKDIR/nginx/nginx.conf" \
    /etc/nginx/nginx.conf

fi

if [ -d "$WORKDIR/nginx/security/http" ]; then

  cp -rf \
    "$WORKDIR/nginx/security/http/"* \
    /etc/nginx/security/http/

fi

if [ -d "$WORKDIR/nginx/security/server" ]; then

  cp -rf \
    "$WORKDIR/nginx/security/server/"* \
    /etc/nginx/security/server/

fi

rm -f /etc/nginx/sites-enabled/default || true

nginx -t

systemctl enable nginx

systemctl reload nginx || systemctl restart nginx

# ==============================
# fail2ban
# ==============================
log "🛡️ fail2ban"

mkdir -p /etc/fail2ban/filter.d

if [ -f "$WORKDIR/fail2ban/jail.local" ]; then

  cp -f \
    "$WORKDIR/fail2ban/jail.local" \
    /etc/fail2ban/jail.local

fi

if [ -d "$WORKDIR/fail2ban/filter.d" ]; then

  cp -rf \
    "$WORKDIR/fail2ban/filter.d/"* \
    /etc/fail2ban/filter.d/

fi

fail2ban-client -d >/dev/null

systemctl enable fail2ban

systemctl restart fail2ban

# ==============================
# nodejs
# ==============================
if ! command -v node &>/dev/null; then

  log "🟢 nodejs"

  curl -fsSL \
    https://deb.nodesource.com/setup_20.x | bash -

  apt install -y nodejs

fi

# ==============================
# clean
# ==============================
log "🧹 clean"

apt autoremove -y

apt clean

log "✅ PROVISION DONE"
