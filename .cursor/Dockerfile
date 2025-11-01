FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set up user and working directory
ENV USER=ubuntu
ENV HOME=/home/$USER
ENV SHELL=/bin/bash

# Install system dependencies and development tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    sudo \
    ca-certificates \
    gnupg \
    lsb-release \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (LTS) and update npm
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest \
    && rm -rf /var/lib/apt/lists/*

# Create user with sudo privileges
RUN useradd -m -s /bin/bash $USER && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to user and set working directory to home
USER $USER
WORKDIR $HOME

# Add Bun to PATH before installation (installer may need it)
ENV PATH="$HOME/.bun/bin:$PATH"

# Install Bun as the user (installs to ~/.bun/bin)
RUN curl -fsSL https://bun.sh/install | bash

# Install TypeScript globally as the user
RUN npm install -g typescript@latest

# Verify installations
RUN node --version && \
    npm --version && \
    bun --version && \
    tsc --version && \
    git --version && \
    jq --version

