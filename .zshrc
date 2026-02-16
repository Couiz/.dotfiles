# === Shadow's ZSH Config ===

# --- History ---
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY

# --- Navigation ---
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# --- Completion ---
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
setopt COMPLETE_ALIASES

# --- Plugins ---
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- fzf ---
source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null
source /usr/share/doc/fzf/examples/completion.zsh 2>/dev/null
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7,fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff,info:#7aa2f7,prompt:#7dcfff,pointer:#ff007c,marker:#9ece6a,spinner:#9ece6a'
export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fdfind --type d --hidden --follow --exclude .git'

# --- zoxide (smart cd) ---
eval "$(zoxide init zsh)"

# --- Prompt (Starship) ---
eval "$(starship init zsh)"

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Copy to local clipboard over SSH (OSC 52)
clip() {
  local data=$(cat "$@" | base64 | tr -d '\n')
  printf "\033]52;c;%s\a" "$data"
}

# --- NVM ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# --- PATH ---
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.local/share/solana/install/active_release/bin:$HOME/openclaw:/usr/local/go/bin:$HOME/go/bin:$PATH"


# --- Auto-attach tmux on SSH ---
# if [[ -n "$SSH_CONNECTION" && -z "$TMUX" ]]; then
#   tmux attach 2>/dev/null || tmux new -s main
# fi
