#!/bin/bash
set -e

SSH_USER=admin

echo "=== 💻 User Layer: Shell 环境 ==="

if [ "$EUID" -ne 0 ]; then
  echo "❌ 请用 root 运行"
  exit 1
fi

# ===== 安装 zsh =====
apt install -y zsh fzf

# ===== Oh My Zsh =====
if [ ! -d "/home/$SSH_USER/.oh-my-zsh" ]; then
  echo "📦 安装 Oh My Zsh..."
  su - $SSH_USER -c '
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  '
fi

# ===== 插件 =====
su - $SSH_USER -c '
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions

[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
git clone https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
'

# ===== zoxide =====
if ! command -v zoxide &>/dev/null; then
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# ===== fnm =====
if [ ! -d "/home/$SSH_USER/.local/share/fnm" ]; then
  su - $SSH_USER -c '
    curl -fsSL https://fnm.vercel.app/install | bash
  '
fi

# ===== 写入 zshrc（覆盖式，统一标准）=====
cat > /home/$SSH_USER/.zshrc <<'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# ===== alias =====
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias gs='git status'
alias gp='git pull'
alias gd='git diff'
alias gc='git commit'

alias dps='docker ps'
alias dcu='docker compose up -d'
alias dcd='docker compose down'

# 提权
alias r='sudo -i'

# zoxide
eval "$(zoxide init zsh --cmd z)"

# fzf
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh

# fnm
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi
EOF

chown $SSH_USER:$SSH_USER /home/$SSH_USER/.zshrc

# ===== 默认 shell =====
chsh -s $(which zsh) $SSH_USER

echo "=== ✅ User 环境完成 ==="
echo "👉 重新登录后生效"
