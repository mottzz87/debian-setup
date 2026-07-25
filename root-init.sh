#!/bin/bash
set -euo pipefail

echo "=== 👑 ROOT INIT ==="

if [ "$(whoami)" != "root" ]; then
  echo "❌ 请使用 root 执行"
  exit 1
fi

SSH_USER="${SSH_USER:-admin}"

# ==============================
# oh-my-zsh
# ==============================
if [ ! -d "/root/.oh-my-zsh" ]; then

  echo "⚡ 安装 Oh My Zsh"

  RUNZSH=no \
  CHSH=no \
  KEEP_ZSHRC=yes \
  sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

fi

# ==============================
# zsh plugins
# ==============================
ZSH_CUSTOM="/root/.oh-my-zsh/custom"

mkdir -p "$ZSH_CUSTOM/plugins"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then

  git clone \
    https://github.com/zsh-users/zsh-autosuggestions \
    $ZSH_CUSTOM/plugins/zsh-autosuggestions

fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then

  git clone \
    https://github.com/zsh-users/zsh-syntax-highlighting \
    $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

fi

# ==============================
# root zshrc
# ==============================
cat > /root/.zshrc <<'EOF'
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# zoxide
eval "$(zoxide init zsh --cmd z)"

source $ZSH/oh-my-zsh.sh

# history
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history

setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# completion
autoload -Uz compinit
compinit

zstyle ':completion:*' menu select

# fzf
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && \
source /usr/share/doc/fzf/examples/key-bindings.zsh

# aliases
alias bat='batcat'

alias ls='eza --icons'
alias ll='eza -lah --icons'
alias la='eza -a --icons'
alias l='eza --icons'

alias fd='fdfind'

alias gs='git status'
alias gp='git pull'
alias gd='git diff'

alias dps='docker ps'
alias dcu='docker compose up -d'
alias dcd='docker compose down'

alias py='python3'

alias c='clear'

alias a='su - __SSH_USER__'

# fastfetch
[[ -t 1 ]] && fastfetch

# prompt
PROMPT='%F{red}# %n@%m %1~ %# %f'
EOF

sed -i "s/__SSH_USER__/$SSH_USER/g" /root/.zshrc

# ==============================
# default shell
# ==============================
chsh -s /usr/bin/zsh root || true

echo "✅ ROOT INIT DONE"