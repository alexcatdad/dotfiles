FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set up basic environment
ENV USER=testuser
ENV HOME=/home/$USER
ENV SHELL=/bin/zsh

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    sudo \
    zsh \
    python3 \
    python3-pip \
    python3-yaml \
    && rm -rf /var/lib/apt/lists/*

# Create test user with sudo privileges
RUN useradd -m -s /bin/zsh $USER && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chsh -s /bin/zsh $USER # Set zsh as default shell for testuser

# Switch to test user
USER $USER
WORKDIR $HOME

# Install Oh My Zsh (required for our dotfiles)
RUN git clone https://github.com/ohmyzsh/ohmyzsh.git $HOME/.oh-my-zsh && \
    cp $HOME/.oh-my-zsh/templates/zshrc.zsh-template $HOME/.zshrc

# Copy dotfiles to container
COPY --chown=$USER:$USER . $HOME/dotfiles

# Set working directory to dotfiles
WORKDIR $HOME/dotfiles

# Make scripts executable
RUN chmod +x bootstrap.sh install-safe.sh scripts/*.sh test/*.sh

# Default command for interactive testing
CMD ["/bin/zsh"]
