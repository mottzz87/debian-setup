#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/mottzz87/debian-setup.git"
WORKDIR="/opt/debian-setup"

SSH_USER="${SSH_USER:-admin}"
PROFILE="${PROFILE:-full}"

echo "=================================="
echo "🚀 Debian Auto Setup"
echo "=================================="

echo "Profile : $PROFILE"
echo "User    : $SSH_USER"

########################################
# Root Check
########################################

if [[ $EUID -ne 0 ]]; then
    echo "❌ 请使用 root 执行"
    exit 1
fi

########################################
# Base Packages
########################################

apt-get update

apt-get install -y \
    git \
    curl \
    wget

########################################
# Clone / Update Repo
########################################

if [[ ! -d "$WORKDIR/.git" ]]; then

    echo
    echo "📥 Cloning repository..."

    rm -rf "$WORKDIR"

    git clone "$REPO_URL" "$WORKDIR"

else

    echo
    echo "📥 Updating repository..."

    cd "$WORKDIR"

    git fetch origin

    echo "⚠️ Discarding local changes..."

    git reset --hard origin/main

fi

cd "$WORKDIR"

chmod +x \
    install.sh \
    ssh-init.sh \
    provision-base.sh \
    provision-service.sh \
    root-init.sh \
    user-init.sh

########################################
# STEP 1
########################################

echo
echo "🔐 STEP 1 / 5"
echo "SSH INIT"

bash ./ssh-init.sh

########################################
# STEP 2
########################################

echo
echo "🧰 STEP 2 / 5"
echo "BASE PROVISION"

bash ./provision-base.sh

########################################
# STEP 3
########################################

if [[ "$PROFILE" == "full" ]]; then

    echo
    echo "🚀 STEP 3 / 5"
    echo "SERVICE PROVISION"

    bash ./provision-service.sh

else

    echo
    echo "⏭️ Skip service provision (PROFILE=$PROFILE)"

fi

########################################
# STEP 4
########################################

echo
echo "👑 STEP 4 / 5"
echo "ROOT INIT"

bash ./root-init.sh

########################################
# STEP 5
########################################

if ! id "$SSH_USER" &>/dev/null; then
    echo "❌ User not found: $SSH_USER"
    exit 1
fi

echo
echo "👤 STEP 5 / 5"
echo "USER INIT"

sudo -iu "$SSH_USER" bash -lc "$WORKDIR/user-init.sh"

########################################
# DONE
########################################

echo
echo "=================================="
echo "🎉 INSTALL COMPLETED"
echo "=================================="

echo
echo "SSH User : $SSH_USER"
echo "Profile  : $PROFILE"

echo
echo "Reconnect with:"
echo
echo "ssh -p 6522 ${SSH_USER}@SERVER_IP"

echo
echo "Recommended:"
echo
echo "reboot"