# .dotfiles

Personal dotfiles for ZSH, tmux, Neovim, and Git. Designed for Ubuntu
servers accessed over SSH from any terminal (Windows Terminal, iTerm2,
Linux).

## What's included

| File | Description |
|------|-------------|
| `.zshrc` | ZSH config for local/desktop (oh-my-zsh, powerlevel10k, fzf, zoxide) |
| `.zshrc.server` | ZSH config for servers (minimal, no framework, zero dependencies) |
| `.tmux.conf` | tmux config (Ctrl+A prefix, vim-style nav, Campbell theme) |
| `.config/nvim/init.lua` | Neovim config (lazy.nvim, LSP, treesitter, telescope) |
| `.gitconfig` | Git config (delta pager, LFS, GitHub CLI credentials) |

Clipboard works over SSH from any terminal via OSC 52 -- no xclip or
X11 required.

## Install

```sh
git clone https://github.com/Couiz/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

**Local machine** (WSL2/desktop -- installs oh-my-zsh, powerlevel10k, plugins):

```sh
./install.sh local
```

**Remote server** (minimal config, no framework):

```sh
./install.sh server
```

Then open a new shell. In tmux, press `Ctrl+A, I` to install tmux
plugins.

### Machine-specific config

For PATH entries, NVM, or custom aliases, create `~/.zshrc.local`:

```sh
cp ~/.dotfiles/.zshrc.local.example ~/.zshrc.local
# edit to taste
```

This file is sourced at the end of both `.zshrc` and `.zshrc.server`
and is not tracked in git.

## Reload after changes

**ZSH:** source the config or open a new shell:

```sh
source ~/.zshrc
```

**tmux:** press `Ctrl+A, r` or run:

```sh
tmux source-file ~/.tmux.conf
```

## Uninstall

Remove the symlinks and cloned dependencies:

```sh
# Remove symlinks
rm -f ~/.zshrc ~/.tmux.conf ~/.config/nvim/init.lua ~/.gitconfig

# Remove cloned dependencies (optional)
rm -rf ~/.oh-my-zsh           # oh-my-zsh (local mode only)
rm -rf ~/.tmux/plugins         # tmux plugins (TPM)

# Remove the repo
rm -rf ~/.dotfiles
```

Backed-up files (created during install as `*.bak`) can be restored:

```sh
# Example: restore original .zshrc
mv ~/.zshrc.bak ~/.zshrc
```

## Key bindings

### tmux (prefix: Ctrl+A)

| Key | Action |
|-----|--------|
| `prefix + h/j/k/l` | Navigate panes |
| `prefix + H/J/K/L` | Resize panes |
| `prefix + v` | Enter copy mode |
| `v` (in copy mode) | Begin selection |
| `y` (in copy mode) | Yank to clipboard (OSC 52) |
| `prefix + r` | Reload config |
| `prefix + s` | Session switcher |
| `prefix + I` | Install TPM plugins |

### Neovim (leader: Space)

| Key | Action |
|-----|--------|
| `Space f` | Find files |
| `Space /` | Live grep |
| `Space b` | Buffers |
| `Space e` | File tree |
| `Space w` | Save |
| `Space q` | Quit |
| `gd` | Go to definition |
| `gr` | References |
| `K` | Hover docs |
| `Space ca` | Code action |
| `Space rn` | Rename |

## Requirements

- **zsh** (default shell)
- **git**, **curl** (for install script)
- **tmux** 3.2+ (for `allow-passthrough`)
- **neovim** 0.10+ (for OSC 52 clipboard)

Optional (auto-detected, not required):

- [eza](https://github.com/eza-community/eza) -- modern ls replacement (aliased if installed)
- [fzf](https://github.com/junegunn/fzf) -- fuzzy finder
- [fd](https://github.com/sharkdp/fd) -- file finder (fzf backend)
- [zoxide](https://github.com/ajeetdsouza/zoxide) -- smart cd
- [delta](https://github.com/dandavison/delta) -- git pager
