#!/bin/bash
set -euo pipefail

echo "=== 👤 USER ENV SETUP ==="

if [ "$(whoami)" = "root" ]; then
  echo "❌ 不要用 root 执行 user.sh"
  exit 1
fi

# ==============================
# 依赖检查
# ==============================
if ! command -v zsh &>/dev/null; then
  echo "❌ 未安装 zsh，请先执行 provision.sh"
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
# npm 工具
# ==============================
echo "📦 安装 npm 工具"
npm install -g pm2 pnpm yarn

# ==============================
# Oh My Zsh
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
mkdir -p "$ZSH_CUSTOM/plugins"

[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions

[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
git clone https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# ==============================
# .zshrc 修改（幂等）
# ==============================
ZSHRC="$HOME/.zshrc"

# 插件
grep -q "zsh-autosuggestions" "$ZSHRC" || \
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"

# fnm
grep -q "fnm env" "$ZSHRC" || cat >> "$ZSHRC" <<'EOF'

# fnm
export FNM_PATH="$HOME/.local/share/fnm"
export PATH="$FNM_PATH:$PATH"
eval "$(fnm env --shell $(basename $SHELL))"
EOF

# zoxide
grep -q "zoxide init" "$ZSHRC" || cat >> "$ZSHRC" <<'EOF'

# zoxide
eval "$(zoxide init zsh --cmd z)"
EOF

# alias + prompt
grep -q "alias ll=" "$ZSHRC" || cat >> "$ZSHRC" <<'EOF'

# aliases
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

# prompt（区分 root / admin）
if [[ $EUID -eq 0 ]]; then
  PROMPT='%F{red}# %n@%m %1~ %# %f'
else
  PROMPT='%F{green}➜ %1~ %f'
fi
EOF

# ==============================
# 默认 shell
# ==============================
CURRENT_SHELL=$(getent passwd $(whoami) | cut -d: -f7)

if [ "$CURRENT_SHELL" != "$(which zsh)" ]; then
  echo "🔄 设置默认 shell 为 zsh"
  chsh -s $(which zsh)
  echo "⚠️ 请重新登录生效"
fi

echo "=== ✅ USER ENV READY ==="
