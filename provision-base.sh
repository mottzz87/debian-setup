#!/usr/bin/env bash
set -euo pipefail

echo "=================================="
echo "🧰 PROVISION BASE"
echo "=================================="

export DEBIAN_FRONTEND=noninteractive

apt-get update

apt-get install -y \
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
  zoxide \
  zsh \
  fzf \
  fail2ban

systemctl enable fail2ban
systemctl restart fail2ban

echo
echo "✅ BASE PROVISION DONE"