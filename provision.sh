#!/bin/bash
set -e

SSH_USER=admin

echo "=== 🚀 环境部署（可重复执行）==="

# ===== 基础更新 =====
apt update && apt upgrade -y

# ===== 安装软件（幂等）=====
apt install -y \
  curl wget git vim zsh \
  docker.io docker-compose \
  nginx fail2ban

# ===== 时区 =====
timedatectl set-timezone Asia/Tokyo

# ===== Docker =====
systemctl enable docker
systemctl start docker
usermod -aG docker $SSH_USER

# ===== Nginx =====
systemctl enable nginx
systemctl start nginx

# ===== Fail2ban（基础版）=====
if [ ! -f /etc/fail2ban/jail.local ]; then
cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = 6522
backend = systemd
maxretry = 6
findtime = 600
bantime = 604800
EOF
fi

systemctl enable fail2ban
systemctl restart fail2ban

# ===== Zsh（仅第一次安装）=====
if [ ! -d "/home/$SSH_USER/.oh-my-zsh" ]; then
  su - $SSH_USER -c '
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  '
fi

# ===== 插件（幂等）=====
su - $SSH_USER -c '
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions

[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
git clone https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
'

# ===== .zshrc（避免重复修改）=====
ZSHRC="/home/$SSH_USER/.zshrc"

if ! grep -q "zsh-autosuggestions" $ZSHRC; then
  sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' $ZSHRC
fi

chown $SSH_USER:$SSH_USER $ZSHRC

# ===== 默认 shell =====
chsh -s $(which zsh) $SSH_USER

echo "=== ✅ 环境部署完成 ==="
