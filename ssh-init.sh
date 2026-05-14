```bash id="ncbxy6"
#!/bin/bash
set -euo pipefail

SSH_PORT=6522
SSH_USER=admin

echo "=== 🔐 SSH INIT ==="

if [ "$EUID" -ne 0 ]; then
  echo "❌ 请用 root 运行"
  exit 1
fi

# ==============================
# 基础工具
# ==============================
apt update

apt install -y \
  sudo \
  vim \
  curl \
  wget \
  ufw

# ==============================
# 输入 SSH 公钥
# ==============================
echo "👉 请输入 SSH 公钥："

read -r PUBKEY

if [[ ! "$PUBKEY" =~ ^ssh-(ed25519|rsa) ]]; then
  echo "❌ SSH 公钥格式错误"
  exit 1
fi

# ==============================
# 输入密码
# ==============================
while true; do

  read -s -p "👉 设置 ${SSH_USER} 密码: " PASS1
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

# ==============================
# 创建用户
# ==============================
if id "$SSH_USER" &>/dev/null; then

  echo "✅ 用户已存在"

else

  adduser --disabled-password --gecos "" $SSH_USER

fi

echo "$SSH_USER:$PASS1" | chpasswd

usermod -aG sudo $SSH_USER

# ==============================
# sudo
# ==============================
read -p "👉 开启免密码 sudo？(y/N): " ENABLE_NOPASSWD

if [[ "$ENABLE_NOPASSWD" =~ ^[Yy]$ ]]; then

  echo "$SSH_USER ALL=(ALL) NOPASSWD:ALL" \
    > /etc/sudoers.d/$SSH_USER

  chmod 440 /etc/sudoers.d/$SSH_USER

fi

# ==============================
# SSH key
# ==============================
mkdir -p /home/$SSH_USER/.ssh

echo "$PUBKEY" \
  > /home/$SSH_USER/.ssh/authorized_keys

chown -R $SSH_USER:$SSH_USER /home/$SSH_USER/.ssh

chmod 700 /home/$SSH_USER/.ssh

chmod 600 /home/$SSH_USER/.ssh/authorized_keys

# ==============================
# SSHD
# ==============================
SSHD_CONFIG="/etc/ssh/sshd_config"

cp $SSHD_CONFIG \
  ${SSHD_CONFIG}.bak.$(date +%s)

cat > $SSHD_CONFIG <<EOF
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

sshd -t

# ==============================
# Firewall
# ==============================
ufw allow $SSH_PORT/tcp

ufw allow 80/tcp

ufw allow 443/tcp

ufw --force enable

# ==============================
# Restart SSH
# ==============================
systemctl restart ssh

echo
echo "=== ✅ SSH INIT DONE ==="

echo "👉 ssh -p $SSH_PORT ${SSH_USER}@SERVER_IP"

echo "⚠️ 请确认 SSH 登录正常后再关闭 root"
```
