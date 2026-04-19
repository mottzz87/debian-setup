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

# ===== 输入公钥 =====
echo "👉 请粘贴你的 SSH 公钥（ssh-ed25519 / ssh-rsa），然后按回车："
read -r PUBKEY

# 简单校验
if [[ ! "$PUBKEY" =~ ^ssh-(ed25519|rsa) ]]; then
  echo "❌ 公钥格式不正确"
  exit 1
fi

# ===== 创建用户 =====
if id "$SSH_USER" &>/dev/null; then
  echo "✅ 用户已存在"
else
  adduser --disabled-password --gecos "" $SSH_USER
fi

# ===== SSH 目录修复 =====
mkdir -p /home/$SSH_USER/.ssh
touch /home/$SSH_USER/.ssh/authorized_keys

chown -R $SSH_USER:$SSH_USER /home/$SSH_USER
chmod 700 /home/$SSH_USER/.ssh
chmod 600 /home/$SSH_USER/.ssh/authorized_keys

# ===== 写入公钥（幂等）=====
if grep -q "$PUBKEY" /home/$SSH_USER/.ssh/authorized_keys; then
  echo "✅ 公钥已存在"
else
  echo "$PUBKEY" >> /home/$SSH_USER/.ssh/authorized_keys
  echo "✅ 公钥已写入"
fi

# ===== SSH 配置 =====
SSHD_CONFIG="/etc/ssh/sshd_config"
cp $SSHD_CONFIG ${SSHD_CONFIG}.bak.$(date +%s)

cat > $SSHD_CONFIG <<EOF
Port $SSH_PORT
LoginGraceTime 20
PermitRootLogin no
MaxAuthTries 6
AllowUsers $SSH_USER

PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no

UsePAM yes
X11Forwarding yes
PrintMotd no

AcceptEnv LANG LC_* COLORTERM NO_COLOR

Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# ===== 检查配置 =====
sshd -t

# ===== 重启 SSH =====
systemctl restart ssh

# ===== 安装 & 配置防火墙 =====
apt update
apt install -y ufw

ufw allow $SSH_PORT/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "=== ✅ 初始化完成 ==="
echo ""
echo "👉 下一步非常重要："
echo "1️⃣ 打开新终端测试登录："
echo "   ssh -p $SSH_PORT $SSH_USER@服务器IP"
echo ""
echo "2️⃣ 登录成功后，再关闭当前 root 会话"
echo ""
echo "⚠️ 如果登录失败，不要退出当前 root，否则会锁死！"
