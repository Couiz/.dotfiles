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

# --- Key bindings ---
bindkey -e
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

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

# --- Aliases ---
alias ll='eza -lah --icons --git'
alias la='eza -a --icons'
alias l='eza --icons'
alias lt='eza -T --icons -L 2'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias g='git'
alias gs='git status -sb'
alias gl='git log --oneline -20'
alias gd='git diff'
alias lg='lazygit'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'
alias cat='batcat --paging=never'
alias catp='batcat'

# Copy to local clipboard over SSH (OSC 52)
clip() {
  local data=$(cat "$@" | base64 | tr -d '\n')
  printf "\033]52;c;%s\a" "$data"
}
# Pipe version: echo foo | yy
alias yy='clip'
alias grep='rg'
alias df='df -h'
alias du='du -sh'
alias free='free -h'
alias ports='ss -tlnp'
alias myip='curl -s ifconfig.me'
alias t='tmux'
alias ta='tmux attach'
alias tl='tmux ls'
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dlogs='docker compose logs -f --tail 50'
alias dprune='docker system prune -af'
alias disk='df -h / | awk "NR==2{print \$3, \"/\", \$2, \"(\" \$5 \")\"}"'
alias mem='free -h | awk "/Mem/{print \$3, \"/\", \$2}"'

# --- NVM ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# --- PATH ---
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.local/share/solana/install/active_release/bin:$HOME/openclaw:/usr/local/go/bin:$HOME/go/bin:$PATH"

# --- Misc ---
export EDITOR=nvim
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# --- Colors ---
export LS_COLORS='di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43'

# --- Auto-attach tmux on SSH ---
if [[ -n "$SSH_CONNECTION" && -z "$TMUX" ]]; then
  tmux attach 2>/dev/null || tmux new -s main
fi
