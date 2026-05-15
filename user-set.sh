#!/bin/bash
set -euo pipefail

echo "=== 👤 USER INIT ==="

if [ "$(whoami)" = "root" ]; then
  echo "❌ 不要用 root 执行"
  exit 1
fi

# ==============================
# fnm
# ==============================
if [ ! -d "$HOME/.local/share/fnm" ]; then

  echo "🟢 安装 fnm"

  curl -fsSL https://fnm.vercel.app/install | bash

fi

export FNM_PATH="$HOME/.local/share/fnm"

export PATH="$FNM_PATH:$PATH"

eval "$($FNM_PATH/fnm env --shell bash)"

# ==============================
# node
# ==============================
echo "🟢 安装 Node LTS"

fnm install --lts

fnm default lts-latest

# ==============================
# npm tools
# ==============================
echo "📦 安装 npm tools"

npm install -g \
  pm2 \
  pnpm \
  yarn


# ==============================
# oh-my-zsh
# ==============================
if [ ! -d "$HOME/.oh-my-zsh" ]; then

  echo "⚡ 安装 Oh My Zsh"

  RUNZSH=no \
  CHSH=no \
  KEEP_ZSHRC=yes \
  sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"


fi

# ==============================
# plugins
# ==============================
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

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
# zshrc
# ==============================
cat > "$HOME/.zshrc" <<'EOF'
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

# fnm
export FNM_PATH="$HOME/.local/share/fnm"

if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi

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
alias gc='git commit'

alias dps='docker ps'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias zshc='nano ~/.zshrc'

alias python=/usr/bin/python3
alias py='python'

alias s='sudo'
alias r='sudo -i'
alias sa='sudo -iu admin'

# fastfetch
[[ -t 1 ]] && fastfetch

# prompt
if [[ $EUID -eq 0 ]]; then
  PROMPT='%F{red}# %n@%m %1~ %# %f'
else
  PROMPT='%F{green}➜ %1~ %f'
fi
EOF

# ==============================
# git config
# ==============================
echo "⚡ 配置 Git"

git config --global init.defaultBranch main

git config --global pull.rebase false

git config --global core.editor vim

# ==============================
# pm2
# ==============================
echo "⚡ 配置 PM2"

pm2 startup systemd -u $(whoami) --hp $HOME || true

pm2 save || true

echo "✅ USER INIT DONE"
