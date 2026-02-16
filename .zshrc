# === ZSH Config (Local) ===

# --- oh-my-zsh ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # disabled, using starship

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  fzf
  zoxide
  command-not-found
)

source "$ZSH/oh-my-zsh.sh"

# --- Prompt (Starship) ---
command -v starship &>/dev/null && eval "$(starship init zsh)"

# --- fzf ---
if command -v fdfind &>/dev/null; then
  FD_CMD="fdfind"
elif command -v fd &>/dev/null; then
  FD_CMD="fd"
fi
if [ -n "$FD_CMD" ]; then
  export FZF_DEFAULT_COMMAND="$FD_CMD --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$FD_CMD --type f --hidden --follow --exclude .git"
  export FZF_ALT_C_COMMAND="$FD_CMD --type d --hidden --follow --exclude .git"
fi
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# --- Aliases ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# --- Clipboard (OSC 52) ---
clip() {
  local data=$(cat "$@" | base64 | tr -d '\n')
  printf "\033]52;c;%s\a" "$data"
}

# --- Machine-specific config ---
[ -s "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
