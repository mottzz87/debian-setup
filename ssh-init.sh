#!/bin/bash
set -e

SSH_PORT=6522
SSH_USER=admin

echo "=== 🔐 初始化（只执行一次）==="

# ===== root 检查 =====
if [ "$EUID" -ne 0 ]; then
  echo "❌ 请用 root 运行"
  exit 1
fi

# ===== 安装基础工具（必须最先）=====
echo "📦 安装基础工具..."
apt update
apt install -y sudo vim curl wget ufw

# ===== 输入公钥 =====
echo "👉 请输入你的 SSH 公钥（ssh-ed25519 或 ssh-rsa）："
read -r PUBKEY

if [[ ! "$PUBKEY" =~ ^ssh-(ed25519|rsa) ]]; then
  echo "❌ 公钥格式不正确"
  exit 1
fi

# ===== 输入密码（隐藏）=====
while true; do
  read -s -p "👉 设置 $SSH_USER 的 sudo 密码: " PASS1
  echo
  read -s -p "👉 再输入一次确认: " PASS2
  echo

  if [ "$PASS1" != "$PASS2" ]; then
    echo "❌ 两次密码不一致，请重新输入"
  elif [ -z "$PASS1" ]; then
    echo "❌ 密码不能为空"
  else
    break
  fi
done

# ===== 创建用户 =====
if id "$SSH_USER" &>/dev/null; then
  echo "✅ 用户已存在"
else
  adduser --disabled-password --gecos "" $SSH_USER
fi

# ===== 设置密码 =====
echo "$SSH_USER:$PASS1" | chpasswd

# ===== sudo 权限 =====
usermod -aG sudo $SSH_USER

# ===== SSH 目录 =====
mkdir -p /home/$SSH_USER/.ssh
echo "$PUBKEY" > /home/$SSH_USER/.ssh/authorized_keys

chown -R $SSH_USER:$SSH_USER /home/$SSH_USER/.ssh
chmod 700 /home/$SSH_USER/.ssh
chmod 600 /home/$SSH_USER/.ssh/authorized_keys

# ===== SSH 配置 =====
SSHD_CONFIG="/etc/ssh/sshd_config"
cp $SSHD_CONFIG ${SSHD_CONFIG}.bak.$(date +%s)

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

# ===== 检查配置 =====
sshd -t

# ===== 防火墙 =====
ufw allow $SSH_PORT/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# ===== 重启 SSH =====
systemctl restart ssh

echo "=== ✅ 初始化完成 ==="
echo "👉 登录方式：ssh -p $SSH_PORT $SSH_USER@服务器IP"
echo "👉 提权方式：sudo -i（输入刚设置的密码）"
echo "⚠️ 请务必先测试登录成功，再关闭 root！"
