#!/bin/bash
set -euo pipefail

USER="admin"

echo "=== 👤 USER ENV SETUP ==="

if [ "$(whoami)" = "root" ]; then
  echo "❌ 不要用 root 执行 user.sh"
  exit 1
fi

# ==============================
# fnm（Node 管理器）
# ==============================
if [ ! -d "$HOME/.local/share/fnm" ]; then
  echo "🟢 安装 fnm"
  curl -fsSL https://fnm.vercel.app/install | bash
fi

export FNM_PATH="$HOME/.local/share/fnm"
export PATH="$FNM_PATH:$PATH"
eval "$(fnm env --shell $(basename $SHELL))"

# ==============================
# Node LTS
# ==============================
echo "🟢 安装 Node LTS"
fnm install --lts
fnm default lts-latest

# ==============================
# 全局 npm 工具
# ==============================
echo "📦 安装 npm 工具"
npm install -g pm2 pnpm yarn

# ==============================
# ZSH + Oh My Zsh
# ==============================
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "⚡ 安装 Oh My Zsh"
  RUNZSH=no CHSH=no sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# ==============================
# 插件
# ==============================
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

mkdir -p $ZSH_CUSTOM/plugins

[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions

[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
git clone https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# ==============================
# .zshrc 优化
# ==============================
ZSHRC="$HOME/.zshrc"

if ! grep -q "zsh-autosuggestions" "$ZSHRC"; then
  sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' $ZSHRC
fi

# ==============================
# fnm 自动加载
# ==============================
if ! grep -q "fnm env" "$ZSHRC"; then
cat >> "$ZSHRC" <<'EOF'

# fnm
export FNM_PATH="$HOME/.local/share/fnm"
export PATH="$FNM_PATH:$PATH"
eval "$(fnm env --shell $(basename $SHELL))"
EOF
fi

# ==============================
# 体验优化
# ==============================
if ! grep -q "alias ll=" "$ZSHRC"; then
cat >> "$ZSHRC" <<'EOF'

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias gs='git status'
alias gp='git pull'
alias gc='git commit'

alias dps='docker ps'
alias dcu='docker compose up -d'
alias dcd='docker compose down'

alias r='sudo -i'
EOF
fi

# ==============================
# 默认 shell 切换（只执行一次）
# ==============================
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "🔄 切换默认 shell 为 zsh"
  chsh -s $(which zsh)
  echo "⚠️ 请重新登录以生效"
fi

echo "=== ✅ USER ENV READY ==="
