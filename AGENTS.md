# AGENTS.md — Dotfiles Repository

## Repository Overview

Personal dotfiles for a multi-machine Linux environment (WSL2 + Ubuntu
servers). Manages configuration for ZSH, tmux, Neovim, and Git.
Designed to be deployed via `install.sh` and work immediately regardless
of which client (Windows Terminal, iTerm2, Linux) connects over SSH.

## File Structure

```
.zshrc                  — ZSH config for local/desktop (oh-my-zsh)
.zshrc.server           — ZSH config for servers (minimal, no framework)
.zshrc.local.example    — template for machine-specific PATH/tools
.tmux.conf              — tmux config (server-focused, OSC 52 clipboard)
.tmux/scripts/status.sh — POSIX shell script for tmux status bar
.config/nvim/init.lua   — Neovim config (Lua, lazy.nvim plugin manager)
.gitconfig              — Git config (delta pager, LFS, credential helpers)
install.sh              — symlink + setup script (takes local|server arg)
```

## Installation

```sh
git clone <repo> ~/.dotfiles && cd ~/.dotfiles
./install.sh local    # WSL2/desktop: oh-my-zsh + plugins
./install.sh server   # remote server: minimal .zshrc, no framework
```

The script symlinks configs to `$HOME`, clones oh-my-zsh + custom
plugins (local mode), and clones TPM for tmux. After running, open a
new shell and press `prefix + I` in tmux to install tmux plugins.

Machine-specific config (NVM, PATH, aliases) goes in `~/.zshrc.local`
(not tracked in git). See `.zshrc.local.example` for a template.

## Build / Lint / Test Commands

There is no build system, CI, or test harness.

### Validation (manual)

```sh
shellcheck .tmux/scripts/status.sh        # lint POSIX shell script
zsh -n .zshrc                              # syntax-check local zsh config
zsh -n .zshrc.server                       # syntax-check server zsh config
luacheck .config/nvim/init.lua             # lint Lua (if luacheck installed)
```

### Applying Changes

- **ZSH:** `source ~/.zshrc` or open a new shell
- **tmux:** `prefix + r` (bound to reload) or `tmux source-file ~/.tmux.conf`
- **Neovim:** Restart nvim (lazy.nvim auto-syncs plugins)
- **Git:** Changes apply immediately

## Architecture Decisions

### Clipboard: OSC 52 everywhere

All clipboard operations use OSC 52 escape sequences, which pass through
SSH transparently. Supported by Windows Terminal, iTerm2, and modern
Linux terminals. No `xclip` or X11 required.

- **tmux:** `set-clipboard on` + `allow-passthrough on`
- **Neovim:** `vim.ui.clipboard.osc52` (0.10+) with `pcall` guard
- **Shell:** `clip()` function for piping text to clipboard

### Two .zshrc files (not conditionals)

Local (`.zshrc`) uses oh-my-zsh for plugin management convenience.
Server (`.zshrc.server`) is self-contained with zero dependencies —
every tool is guarded with `command -v` or `[ -s file ]`.
`install.sh` symlinks the right one as `~/.zshrc`.

### Portability rules

- Guard optional tools: `command -v tool &>/dev/null && ...`
- Guard optional sources: `[ -s "$file" ] && source "$file"`
- Auto-detect fd binary: check `fdfind` then `fd` (Debian vs others)
- No hardcoded usernames or absolute paths — use `$HOME`
- No platform-specific commands in shared configs (no `cmd.exe`, no `xclip`)

## Code Style Guidelines

### Shell Scripts (.zshrc, .zshrc.server, status.sh)

- `status.sh` uses `#!/bin/sh` (POSIX sh) — no bashisms.
- `.zshrc*` files are ZSH — zsh-specific features expected.
- Top-level header: `# === Title ===`. Subsections: `# --- Name ---`.
- Inline comments: lowercase, brief.
- Always double-quote variable expansions: `"$HOME"`, `"$var"`.
- Use `$()` for command substitution, not backticks.
- Functions: `name() {` syntax, `local` for scoped variables.
- No trailing whitespace. One blank line between sections.
- PATH entries go in `~/.zshrc.local`, not the tracked config.

### Lua (Neovim init.lua)

- Single-file config. Order: bootstrap -> leader -> options -> keymaps -> plugins.
- Sections delimited with `-- === Section Name ===`.
- 2-space indentation (spaces, no tabs). Double quotes for strings.
- Alias APIs: `local opt = vim.opt`, `local map = vim.keymap.set`.
- All keymaps include `desc` for which-key discoverability.
- Use `pcall()` for operations that may fail. No `assert` or `error()`.
- Plugin specs: `config = true` for defaults, `config = function() ... end` for custom setup.
- Prefer lazy-loading: `keys`, `cmd`, `event` fields.

### tmux Config (.tmux.conf)

- Section headers: `# --- Section Name ---`.
- One setting per line. Related settings grouped.
- Hex colors: `#RRGGBB`. Campbell palette (do not mix Tokyo Night).
- Vim-style `h/j/k/l` nav. Uppercase `H/J/K/L` with `-r` for resize.
- Plugin block grouped together. TPM `if-shell` guard at bottom.

### Git Config (.gitconfig)

- Tab indentation. Noreply email for privacy.
- Delta pager with line numbers and `diff3` merge conflict style.

## Commit Message Conventions

- Lowercase, imperative mood: `add tmux status.sh script`
- Prefix with `init:` for initial multi-file commits.
- Short (under 72 chars), no trailing period.
- Descriptive of *what changed*, not why.

## Environment Notes

- **Platforms:** WSL2 (Ubuntu 24.04), Ubuntu servers, Mac (SSH client only)
- **Terminals:** Windows Terminal, iTerm2, Linux terminals
- **Shell tools:** zoxide, fzf (fdfind/fd), powerlevel10k prompt, eza
- **Neovim LSPs:** pyright, ts_ls, rust_analyzer, lua_ls (via mason)
- **Git tooling:** GitHub CLI, Git LFS, delta pager

## Known Issues / Pending Work

### .gitconfig portability (not yet addressed)

The `.gitconfig` has three issues on servers where tools are missing:

1. **`!/usr/bin/gh`** (lines 6, 9) -- hardcoded absolute path. If `gh` is
   missing or installed elsewhere, all GitHub HTTPS operations fail.
   Fix: use `!gh auth git-credential` (resolve via PATH) or conditional include.
2. **`pager = delta`** (line 16) -- if delta is not installed, `git diff`,
   `git log`, `git show` all fail. Fix: use `[include] path = ~/.gitconfig.local`
   for delta config, keep `less` as default pager in base.
3. **LFS `required = true`** (line 13) -- blocks `git clone`/`checkout` on
   LFS repos if `git-lfs` is not installed. Fix: remove `required = true`.

The owner deferred this work intentionally. The pattern should match
`.zshrc.local` — a base `.gitconfig` that works everywhere, with
`~/.gitconfig.local` for machine-specific overrides (delta, gh).

### OSC 11 response leak in tmux (upstream bug)

When attaching to a tmux session over SSH from Windows Terminal, escape
sequence responses leak as visible text on the prompt:

```
❯ 11;rgb:0c0c/0c0c/0c0c
```

**Root cause:** tmux bug ([tmux/tmux#4634]). On client attach, tmux
queries the outer terminal for device attributes (DA/DA2) and colors
(OSC 10/11). The outer terminal responds, but tmux fails to consume the
response — it gets forwarded to the pane as visible text. The reporter
identified a likely code defect: `tty->term->flags` vs `tty->flags` in
`tty.c`, causing duplicate queries whose responses leak.

**Affected config:** `allow-passthrough on` (current `.tmux.conf`).
Tested with `escape-time 0` and `escape-time 10` — both leak. The
bug is in tmux's response handling, not timing.

**Status:** Upstream bug. No fix available in tmux 3.4. Only real fix
is a patched tmux release. Cosmetic only — does not affect functionality.

[tmux/tmux#4634]: https://github.com/tmux/tmux/issues/4634
