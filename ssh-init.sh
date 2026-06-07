#!/bin/bash
set -euo pipefail

SSH_PORT="${SSH_PORT:-6522}"
SSH_USER="${SSH_USER:-admin}"

echo "=================================="
echo "🔐 SSH INIT"
echo "=================================="

# ==============================
# root check
# ==============================
if [ "$EUID" -ne 0 ]; then
  echo "❌ 请用 root 执行"
  exit 1
fi

# ==============================
# install base packages
# ==============================
apt-get update

apt-get install -y \
  sudo \
  vim \
  curl \
  wget \
  ufw \
  chrony

# ==============================

# timezone & ntp

# ==============================

TIMEZONE="${TIMEZONE:-Asia/Tokyo}"

echo "⏰ Configuring timezone: $TIMEZONE"

timedatectl set-timezone "$TIMEZONE"

systemctl enable chrony

systemctl restart chrony

echo "⏳ Waiting for time sync..."

for i in {1..10}; do

  if timedatectl show -p NTPSynchronized --value 2>/dev/null | grep -q yes; then

    echo "✅ Time synchronized"

    break

  fi

  sleep 1

done

timedatectl

# ==============================
# SSH PUBKEY
# ==============================
PUBKEY="${SSH_PUBKEY:-}"

if [ -z "$PUBKEY" ]; then

  echo "👉 请输入 SSH 公钥："

  read -r PUBKEY

fi

if [[ ! "$PUBKEY" =~ ^ssh-(ed25519|rsa) ]]; then

  echo "❌ SSH 公钥格式不正确"

  exit 1

fi

# ==============================
# PASSWORD
# ==============================
PASS1="${SSH_PASSWORD:-}"

if [ -z "$PASS1" ]; then

  while true; do

    read -s -p "👉 设置 $SSH_USER 密码: " PASS1
    echo

    read -s -p "👉 再输入一次: " PASS2
    echo

    if [ "$PASS1" != "$PASS2" ]; then

      echo "❌ 两次密码不一致"

    elif [ -z "$PASS1" ]; then

      echo "❌ 密码不能为空"

    else

      break

    fi

  done

fi

# ==============================
# create user
# ==============================
if id "$SSH_USER" &>/dev/null; then

  echo "✅ 用户已存在"

else

  adduser \
    --disabled-password \
    --gecos "" \
    "$SSH_USER"

fi

# ==============================
# set password
# ==============================
echo "$SSH_USER:$PASS1" | chpasswd

# ==============================
# sudo
# ==============================
usermod -aG sudo "$SSH_USER"

# ==============================
# nopasswd sudo
# ==============================
ENABLE_NOPASSWD="${ENABLE_NOPASSWD:-}"

if [ -z "$ENABLE_NOPASSWD" ]; then

  read -p "👉 开启免密码 sudo？(y/N): " ENABLE_NOPASSWD

fi

if [[ "$ENABLE_NOPASSWD" =~ ^([Yy]|[Yy][Ee][Ss]|true|TRUE)$ ]]; then

  echo "$SSH_USER ALL=(ALL) NOPASSWD:ALL" \
    > /etc/sudoers.d/$SSH_USER

  chmod 440 /etc/sudoers.d/$SSH_USER

  echo "✅ 已开启免密码 sudo"

else

  rm -f /etc/sudoers.d/$SSH_USER || true

  echo "ℹ️ sudo 需要密码"

fi

# ==============================
# ssh dir
# ==============================
mkdir -p /home/$SSH_USER/.ssh

echo "$PUBKEY" \
  > /home/$SSH_USER/.ssh/authorized_keys

chown -R \
  $SSH_USER:$SSH_USER \
  /home/$SSH_USER/.ssh

chmod 700 /home/$SSH_USER/.ssh

chmod 600 \
  /home/$SSH_USER/.ssh/authorized_keys

# ==============================
# sshd config
# ==============================
SSHD_CONFIG="/etc/ssh/sshd_config"

cp "$SSHD_CONFIG" \
  "${SSHD_CONFIG}.bak.$(date +%s)"

cat > "$SSHD_CONFIG" <<EOF
Port $SSH_PORT

PermitRootLogin no
AllowUsers $SSH_USER

PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no

UsePAM yes

X11Forwarding yes

PrintMotd no

AcceptEnv LANG LC_*

Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# ==============================
# test sshd
# ==============================
sshd -t

# ==============================
# ufw
# ==============================
ufw allow $SSH_PORT/tcp

ufw allow 80/tcp

ufw allow 443/tcp

ufw --force enable

# ==============================
# restart ssh
# ==============================
systemctl restart ssh

echo
echo "=================================="
echo "✅ SSH INIT DONE"
echo "=================================="

echo "👉 ssh -p $SSH_PORT $SSH_USER@SERVER_IP"

echo "⚠️ 请确认 SSH 登录正常后再关闭 root"
