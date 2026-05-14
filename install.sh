```bash id="0vhg5p"
#!/bin/bash
set -euo pipefail

SSH_USER="admin"

echo "=================================="
echo "🚀 Debian Auto Setup"
echo "=================================="

if [ "$EUID" -ne 0 ]; then
  echo "❌ 请使用 root 执行"
  exit 1
fi

echo
echo "🔐 STEP 1: ssh-init"

bash ./ssh-init.sh

echo
echo "⚙️ STEP 2: provision"

bash ./provision.sh

echo
echo "👤 STEP 3: user-init"

sudo -u $SSH_USER bash <<EOF
cd $(pwd)
bash ./user-init.sh
EOF

echo
echo "=================================="
echo "✅ ALL DONE"
echo "=================================="

echo "👉 重新登录："
echo "ssh -p 6522 admin@YOUR_SERVER_IP"
```
