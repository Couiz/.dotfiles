#!/bin/sh
# install.sh — symlink dotfiles to $HOME
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-}"

if [ "$MODE" != "local" ] && [ "$MODE" != "server" ]; then
  echo "Usage: ./install.sh <local|server>"
  echo "  local   — oh-my-zsh + full config (WSL2/desktop)"
  echo "  server  — minimal config (remote servers)"
  exit 1
fi

link() {
  mkdir -p "$(dirname "$2")"
  [ -e "$2" ] && [ ! -L "$2" ] && mv "$2" "$2.bak" && echo "  backup $2"
  ln -sf "$1" "$2"
  echo "  link   $2"
}

echo "Installing dotfiles ($MODE)..."

# --- ZSH ---
if [ "$MODE" = "local" ]; then
  # Install oh-my-zsh first (it creates its own .zshrc)
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "  Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi
  # Symlink our .zshrc (overwrites oh-my-zsh default)
  link "$DOTFILES/.zshrc" "$HOME/.zshrc"
  # Clone custom plugins
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || \
    git clone -q https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || \
    git clone -q https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  # Clone powerlevel10k theme
  [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ] || \
    git clone -q --depth=1 https://github.com/romkatv/powerlevel10k "$ZSH_CUSTOM/themes/powerlevel10k"
elif [ "$MODE" = "server" ]; then
  link "$DOTFILES/.zshrc.server" "$HOME/.zshrc"
fi

# --- tmux ---
link "$DOTFILES/.tmux.conf" "$HOME/.tmux.conf"
link "$DOTFILES/.tmux/scripts/status.sh" "$HOME/.tmux/scripts/status.sh"
[ -d "$HOME/.tmux/plugins/tpm" ] || \
  git clone -q https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

# --- Git ---
# .gitconfig is NOT symlinked intentionally — it has portability issues:
#   - hardcoded /usr/bin/gh path (fails if gh is missing or elsewhere)
#   - delta pager (breaks git diff/log/show if delta is not installed)
#   - LFS required=true (blocks clone/checkout without git-lfs)
# Plan: split into base .gitconfig + ~/.gitconfig.local (like .zshrc.local)

# --- Neovim ---
link "$DOTFILES/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua"

echo ""
echo "Done. Open a new shell, then run 'prefix + I' in tmux to install plugins."
