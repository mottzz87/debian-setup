#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/mottzz87/debian-setup.git"

WORKDIR="/opt/debian-setup"

SSH_USER="admin"

echo "=================================="
echo "🚀 Debian Auto Setup"
echo "=================================="

# ==============================
# root check
# ==============================
if [ "$EUID" -ne 0 ]; then
  echo "❌ 请使用 root 执行"
  exit 1
fi

# ==============================
# install base packages
# ==============================
apt update

apt install -y \
  git \
  curl \
  wget

# ==============================
# clone repo
# ==============================
if [ ! -d "$WORKDIR/.git" ]; then

  echo "📥 clone repository"

  rm -rf "$WORKDIR"

  git clone "$REPO_URL" "$WORKDIR"

else

  echo "📥 update repository"

  cd "$WORKDIR"

  git fetch origin

  git reset --hard origin/main

fi

cd "$WORKDIR"

chmod +x *.sh

# ==============================
# ssh-init
# ==============================
echo
echo "🔐 STEP 1: ssh-init"

bash ./ssh-init.sh

# ==============================
# provision
# ==============================
echo
echo "⚙️ STEP 2: provision"

bash ./provision.sh

# ==============================
# user-init
# ==============================
echo
echo "👤 STEP 3: user-init"

sudo -u $SSH_USER bash <<EOF
cd $WORKDIR
bash ./user-init.sh
EOF

echo
echo "=================================="
echo "✅ ALL DONE"
echo "=================================="

echo "👉 reconnect:"
echo "ssh -p 6522 admin@SERVER_IP"