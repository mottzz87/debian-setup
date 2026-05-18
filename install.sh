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
apt-get update

apt-get install -y \
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

  echo "⚠️ local changes will be discarded"

  git reset --hard origin/main

fi

cd "$WORKDIR"

chmod +x \
  ssh-init.sh \
  provision.sh \
  root-init.sh \
  user-init.sh

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
# root-init
# ==============================
echo
echo "👑 STEP 3: root-init"

bash ./root-init.sh

# ==============================
# user check
# ==============================
if ! id "$SSH_USER" &>/dev/null; then
  echo "❌ user not found: $SSH_USER"
  exit 1
fi

# ==============================
# user-init
# ==============================
echo
echo "👤 STEP 4: user-init"

sudo -iu "$SSH_USER" bash -lc "$WORKDIR/user-init.sh"

echo
echo "=================================="
echo "✅ ALL DONE"
echo "=================================="

echo
echo "👉 reconnect:"
echo "ssh -p 6522 admin@SERVER_IP"

echo
echo "💡 recommended:"
echo "reboot"