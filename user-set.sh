#!/bin/bash
set -e

echo "=== 👤 User Environment Setup ==="

# ===== 参数 =====
USER_NAME="admin"

# ===== 检查用户 =====
if ! id "$USER_NAME" &>/dev/null; then
  echo "❌ 用户不存在：$USER_NAME"
  exit 1
fi

# ===== 安装 zsh =====
apt update -y
apt install -y zsh git curl

# ===== 设置默认 shell =====
chsh -s /bin/zsh $USER_NAME || true

# root 也统一（可选）
chsh -s /bin/zsh root || true

# ===== 统一 zshrc（核心）=====
ZSHRC="/home/$USER_NAME/.zshrc"

cat > "$ZSHRC" <<'EOF'
# =========================
# Basic Prompt（核心：显示用户名）
# =========================
autoload -Uz colors && colors

setopt PROMPT_SUBST

PROMPT='%F{green}%n@%m%f %F{blue}%~%f %# '

# =========================
# history 优化
# =========================
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

# =========================
# 基础 alias
# =========================
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias gs='git status'
alias gp='git pull'
alias gc='git commit'
alias gd='git diff'

alias dps='docker ps'
alias dcu='docker compose up -d'
alias dcd='docker compose down'

# root 快速切换（你可以保留）
alias r='sudo -i'

# =========================
# zoxide（如果存在才加载）
# =========================
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh --cmd z)"
fi

# =========================
# fnm（Node版本管理）
# =========================
export FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi

# =========================
# Node / pnpm / npm 提示增强（可选）
# =========================
export EDITOR=vim
EOF

# ===== root 也写一份 =====
cat > /root/.zshrc <<'EOF'
autoload -Uz colors && colors
setopt PROMPT_SUBST
PROMPT='%F{red}%n@%m%f %F{blue}%~%f %# '

alias ll='ls -alF'
alias gs='git status'
alias r='sudo -i'
EOF

# ===== 修复权限 =====
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME

# ===== 安装 zoxide（可选但推荐）=====
if ! command -v zoxide >/dev/null 2>&1; then
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash || true
fi

echo "=== ✅ User environment ready ==="
echo "👉 重新登录 SSH 或执行: exec zsh"
