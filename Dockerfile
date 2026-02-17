# Dockerfile — manual testing environment for dotfiles
# Usage: docker compose run dotfiles
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Core tools + fzf/zoxide (oh-my-zsh plugins warn if these are missing)
# Optional tools like eza, fd, delta, starship are left out — install ad-hoc to test guards
# The base image excludes /usr/share/doc/* via dpkg config, but fzf's zsh
# integration lives there — remove the exclusion before installing fzf
RUN rm -f /etc/dpkg/dpkg.cfg.d/excludes \
    && apt-get update && apt-get install -y \
    zsh \
    tmux \
    git \
    curl \
    ca-certificates \
    locales \
    sudo \
    fzf \
    zoxide \
    && rm -rf /var/lib/apt/lists/*

# Locale (required for zsh/tmux to behave correctly)
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8

# Neovim 0.10+ (Ubuntu 24.04 repos only ship 0.9.x, config needs 0.10+ for OSC 52)
RUN curl -LO https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz \
    && tar xzf nvim-linux-x86_64.tar.gz -C /opt \
    && ln -s /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim \
    && rm nvim-linux-x86_64.tar.gz

# Non-root user (UID 1000 to match typical host, passwordless sudo for ad-hoc installs)
# Ubuntu 24.04 ships a default 'ubuntu' user at UID 1000 — remove it first
RUN userdel -r ubuntu 2>/dev/null; \
    useradd -m -s /bin/zsh -u 1000 testuser \
    && echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER testuser
WORKDIR /home/testuser

# Stub .zshrc to suppress zsh-newuser-install wizard (install.sh will replace it)
RUN echo "# placeholder — run ~/.dotfiles/install.sh to configure" > ~/.zshrc

CMD ["/bin/zsh"]
