# Gemini Added Memories

## Project Overview

This project contains a comprehensive set of personal dotfiles meticulously crafted for TypeScript development environments, targeting both macOS and Ubuntu operating systems. The primary goal is to provide a highly optimized and efficient development setup.

**Key Features:**
*   **Modern CLI Tools:** Integration of enhanced command-line utilities (e.g., `bat`, `exa`, `fzf`, `ripgrep`, `fd`, `zoxide`, `starship`, `direnv`, `tldr`) to boost productivity and improve the terminal experience.
*   **Development Tools:** Essential tools for TypeScript development, including Node.js (managed by NVM), Bun, global npm packages, Git enhancements (`git-extras`, GitHub CLI), and utility runners (`just`, `hyperfine`, `navi`).
*   **Smart Aliases & Functions:** A collection of custom aliases and shell functions for streamlined project management, development shortcuts, Git workflow, and Docker management.
*   **Project Automation:** Scripts for intelligent project creation (`init-project`), health monitoring (`project-health`), and smart package management (`smart-install`).
*   **Git Workflow:** Tools and conventions for a structured Git workflow, including conventional commits and branch management utilities.
*   **Dotfile Management:** Utilizes Dotbot for declarative and idempotent management of symlinks and configurations.

## Building and Running

This dotfiles repository offers several installation methods to suit different scenarios, from fresh system bootstraps to safe, interactive installations on existing machines.

### Installation Options

*   **Complete Bootstrap (New Machines):**
    ```bash
    curl -fsSL https://raw.githubusercontent.com/alexalexandrescu/dotfiles/main/bootstrap.sh | bash
    ```
    This script performs a full setup, including system dependencies, Dotbot, Zsh plugins, NVM, Node.js, Bun, and global npm packages.

*   **Safe Installation (Existing Systems):**
    ```bash
    git clone https://github.com/alexalexandrescu/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    ./install-safe.sh  # Interactive, preserves existing configs
    ```
    This interactive script allows selective installation of components and backs up existing configurations before linking new ones.

*   **Manual Installation (Dotbot):**
    ```bash
    git clone https://github.com/alexalexandrescu/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    ./install  # Uses dotbot for modern installation
    ```
    This method directly invokes Dotbot to symlink the configurations defined in `install.conf.yaml`.

*   **Package-Only Installation:**
    ```bash
    ./scripts/install-packages-yaml.sh modern_cli developer_tools
    ```
    This script allows installing specific categories of CLI tools and development packages without modifying dotfiles.

### Testing and Validation

*   **Docker Testing:** The `test-docker.sh` script provides a safe, containerized environment to test various installation scenarios (fresh, safe, macOS-like) without affecting the host system.
    ```bash
    ./test-docker.sh fresh       # Test fresh installation
    ./test-docker.sh safe        # Test safe installation
    ./test-docker.sh dev         # Start interactive development container
    ./test-docker.sh macos       # Test macOS-like environment
    ./test-docker.sh clean       # Clean up test containers
    ```
*   **Local Validation:** The `test/test-dotfiles.sh` script can be run locally to verify the correct setup of core files, symlinks, tool availability, and shell functions.
    ```bash
    ./test/test-dotfiles.sh
    ```

## Development Conventions

*   **Dotfile Management:** Configurations are managed declaratively using **Dotbot**, with `install.conf.yaml` defining the symlinking strategy and conditional installations.
*   **Shell Environment:** The default shell is **Zsh**, enhanced with **Oh My Zsh**, **Powerlevel10k** theme, and popular plugins like `zsh-autosuggestions` and `zsh-syntax-highlighting`.
*   **Tooling Philosophy:** Strong emphasis on using modern, performant CLI tools as replacements for traditional Unix commands.
*   **TypeScript Focus:** The environment is optimized for TypeScript development, including Node.js (via NVM), Bun, and global TypeScript-related npm packages.
*   **Git Workflow:** Encourages **Conventional Commits** and provides helper functions for branch management and repository analysis.
*   **Code Style:** While not explicitly defined in a linter config, the project implies a focus on clean, maintainable code through the use of tools like `prettier` (installed globally) and `eslint`.
*   **Backup Strategy:** Includes scripts for manual and automated backups of configurations.
