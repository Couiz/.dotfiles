# Dockerfile — manual testing environment for dotfiles
# Usage: docker compose run dotfiles
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Core tools only (no optional tools — install ad-hoc to test guards)
RUN apt-get update && apt-get install -y \
    zsh \
    tmux \
    git \
    curl \
    ca-certificates \
    locales \
    sudo \
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

CMD ["/bin/zsh"]
