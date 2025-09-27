# 🚀 Ultimate TypeScript Developer Dotfiles

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Ubuntu-blue)](https://github.com/alexalexandrescu/dotfiles)

**⚠️ DISCLAIMER: This is a public repository. Use at your own risk. Always review code before running on your system. Backup your existing configurations before installation.**

My personal dotfiles configuration optimized for TypeScript development across macOS and Ubuntu environments, enhanced with the best tools from the awesome developer community.

## 📋 Table of Contents

- [Quick Installation](#-quick-installation)
- [What's Included](#%EF%B8%8F-whats-included)
- [Modern CLI Tools](#-modern-cli-tools)
- [Development Tools](#-development-tools)
- [Smart Aliases & Functions](#-smart-aliases--functions)
- [Project Automation](#-project-automation)
- [Git Workflow](#-git-workflow)
- [Installation Options](#-installation-options)
- [Tool Usage Guide](#-tool-usage-guide)
- [Maintenance](#-maintenance)
- [Troubleshooting](#-troubleshooting)

## 🚀 Quick Installation

### 🛡️ Safe Installation (Recommended for Existing Systems)
Perfect for your local machine with existing setup:
```bash
git clone https://github.com/alexalexandrescu/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install-safe.sh  # Interactive, preserves existing configs
```

### 🔥 Complete Bootstrap (New Machines)
Sets up everything from scratch:
```bash
curl -fsSL https://raw.githubusercontent.com/alexalexandrescu/dotfiles/main/bootstrap.sh | bash
```

### 🛠️ Manual Installation (Dotbot)
```bash
git clone https://github.com/alexalexandrescu/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install  # Uses dotbot for modern installation
```

### 📦 Package-Only Installation
Just install the modern CLI tools without configs:
```bash
./scripts/install-packages.sh modern_cli developer_tools
```

### 🐳 Docker Testing (Recommended for Testing)
Test the installation safely in a containerized environment:
```bash
# Test fresh installation (bootstrap)
./test-docker.sh fresh

# Test safe installation (existing system simulation)
./test-docker.sh safe

# Interactive development container
./test-docker.sh dev

# Test macOS-like installation
./test-docker.sh macos

# Get shell access to running container
./test-docker.sh shell dev

# Clean up all test containers
./test-docker.sh clean
```

**Docker commands available:**
- `fresh` - Test bootstrap.sh installation from scratch
- `safe` - Test install-safe.sh with simulated existing configs
- `dev` - Start interactive container for manual testing
- `macos` - Test macOS-like environment simulation
- `build` - Build the Docker image only
- `shell [container]` - Get shell access to running container
- `logs` - Show recent container logs
- `clean` - Remove all test containers and images

## 🛠️ What's Included

This setup is tailored for TypeScript developers using:
- **Editor**: Cursor (primary), Micro (terminal)
- **Runtime**: Node.js LTS + Bun
- **Package Manager**: Homebrew (macOS), APT (Ubuntu)
- **Shell**: Zsh with Oh My Zsh + Powerlevel10k
- **Tools**: Docker, Git, NVM, Claude Code, Scaleway CLI

## ⚡ Modern CLI Tools

Enhanced replacements for classic Unix tools with links and usage:

### 🔍 **Search & Navigation**

#### **zoxide** - Smart Directory Navigation
- **Link**: https://github.com/ajeetdsouza/zoxide
- **Usage**:
  ```bash
  z projects        # Jump to ~/Projects (learns frequently used dirs)
  zi               # Interactive directory picker
  z -             # Go back to previous directory
  ```

#### **fzf** - Fuzzy Finder
- **Link**: https://github.com/junegunn/fzf
- **Usage**:
  ```bash
  <Ctrl-T>        # Fuzzy find files
  <Ctrl-R>        # Fuzzy find command history
  <Alt-C>         # Fuzzy find directories
  fzf             # Start interactive finder
  ```

#### **ripgrep (rg)** - Ultra-Fast Text Search
- **Link**: https://github.com/BurntSushi/ripgrep
- **Usage**:
  ```bash
  rg "pattern"           # Search in current directory
  rg -i "pattern"        # Case insensitive search
  rg --files-with-matches "pattern"  # Just show filenames
  rg "pattern" --type js # Search only JavaScript files
  ```

#### **fd** - Modern Find Replacement
- **Link**: https://github.com/sharkdp/fd
- **Usage**:
  ```bash
  fd filename           # Find files by name
  fd -t f "pattern"     # Find files only
  fd -t d "pattern"     # Find directories only
  fd -e js             # Find JavaScript files
  ```

### 🎨 **File Operations**

#### **bat** - Cat with Syntax Highlighting
- **Link**: https://github.com/sharkdp/bat
- **Usage**:
  ```bash
  bat file.js          # View with syntax highlighting
  bat --style=plain    # Plain output without decorations
  bat -n file.js       # Show line numbers
  ```

#### **exa** - Modern ls Replacement
- **Link**: https://github.com/ogham/exa
- **Usage**:
  ```bash
  exa                  # Basic listing with colors
  exa -la --icons      # Long format with icons
  exa --tree           # Tree view
  exa -la --git        # Show git status
  ```

### 🎯 **Productivity Tools**

#### **starship** - Cross-Shell Prompt
- **Link**: https://github.com/starship/starship
- **Features**: Shows git status, Node version, battery, execution time
- **Usage**: Automatically activates, configure with `~/.config/starship.toml`

#### **direnv** - Environment Switcher
- **Link**: https://github.com/direnv/direnv
- **Usage**:
  ```bash
  echo "export API_KEY=dev123" > .envrc
  direnv allow         # Enable for current directory
  cd project          # Automatically loads environment
  ```

#### **tldr** - Simplified Man Pages
- **Link**: https://github.com/tldr-pages/tldr
- **Usage**:
  ```bash
  tldr tar            # Get examples for tar command
  tldr git            # Quick git examples
  tldr -u             # Update database
  ```

## 🛠️ Development Tools

### 🔧 **Git Enhancements**

#### **git-extras** - Advanced Git Utilities
- **Link**: https://github.com/tj/git-extras
- **Usage**:
  ```bash
  git summary         # Repository summary
  git effort          # File effort analysis
  git line-summary    # Line count summary
  git info            # Repository information
  ```

#### **GitHub CLI (gh)** - GitHub Integration
- **Link**: https://github.com/cli/cli
- **Usage**:
  ```bash
  gh pr create        # Create pull request
  gh pr list          # List pull requests
  gh repo view        # View repository
  gh issue create     # Create issue
  ```

### ⚡ **Performance & Testing**

#### **hyperfine** - Command Benchmarking
- **Link**: https://github.com/sharkdp/hyperfine
- **Usage**:
  ```bash
  hyperfine 'npm test'              # Benchmark npm test
  hyperfine --warmup 3 'command'    # Warm up before measuring
  hyperfine 'cmd1' 'cmd2'          # Compare two commands
  ```

#### **just** - Command Runner
- **Link**: https://github.com/casey/just
- **Usage**:
  ```bash
  just --list         # List available commands
  just build          # Run build command
  just test           # Run test command
  ```

### 📚 **Learning & Help**

#### **navi** - Interactive Cheatsheets
- **Link**: https://github.com/denisidoro/navi
- **Usage**:
  ```bash
  navi                # Browse cheatsheets
  navi --query git    # Search for git commands
  <Ctrl-G>           # Trigger from command line
  ```

### 🖥️ **System Monitoring**

#### **glances** - System Monitor
- **Link**: https://github.com/nicolargo/glances
- **Usage**:
  ```bash
  glances             # System overview
  glances -w          # Web interface
  glances -t 5        # Update every 5 seconds
  ```

### 📝 **Text Editing**

#### **micro** - Modern Terminal Editor
- **Link**: https://github.com/zyedidia/micro
- **Usage**:
  ```bash
  micro file.js       # Edit file
  <Ctrl-S>           # Save
  <Ctrl-Q>           # Quit
  <Ctrl-F>           # Find
  <Ctrl-H>           # Find and replace
  ```
- **Why not vim?**: Micro has familiar keybindings (Ctrl+S, Ctrl+C, etc.) and is much easier to learn

## ⚡ Smart Aliases & Functions

### 🎯 **Project Management**
```bash
# TypeScript project creation
init-project typescript my-api      # Create TS project
init-project react my-app          # Create React app
init-project nextjs my-site        # Create Next.js app
init-project express my-server     # Create Express API

# Smart package management (auto-detects bun/pnpm/npm)
smart-install express              # Install package
smart-install @types/node --dev    # Install dev dependency
```

### 🚀 **Development Shortcuts**
```bash
# Quick development commands
dev                    # Intelligently start dev server
project-health        # Check dependencies, security, TypeScript
switch-node           # Use Node version from .nvmrc or LTS
bench-cmd "npm test"  # Benchmark command execution
```

### 🔧 **Git Workflow**
```bash
# Conventional commits
quick-commit feat "add user auth"           # Standard commit
quick-commit fix "resolve memory leak" api  # With scope

# Git extras shortcuts (when installed)
gsum              # Repository summary
geff              # File effort analysis
gline             # Line summary

# GitHub CLI shortcuts (when installed)
ghpr              # Create pull request
ghprs             # PR status
ghprl             # List PRs
```

### 🐳 **Docker Management**
```bash
# Docker shortcuts
d                 # docker
dc                # docker-compose
dps               # docker ps
dstop             # Stop all containers
dclean            # Clean up Docker system
docker-dev        # Run docker-compose up --build
docker-logs       # Follow logs
```

### 🔍 **Navigation & Files**
```bash
# Enhanced navigation (when modern tools installed)
ls                # exa with icons
ll                # exa long format with git status
tree              # exa tree view
cat               # bat with syntax highlighting
grep              # ripgrep (faster)
find              # fd (modern find)

# Quick navigation
..                # cd ..
...               # cd ../..
....              # cd ../../..
```

## 🤖 Project Automation

### 📁 **Smart Project Creation**

The `init-project` function creates different types of projects with best practices:

```bash
# TypeScript Node.js project
init-project typescript my-api
# Creates: src/, tests/, tsconfig.json, package.json with scripts

# React TypeScript project
init-project react my-app
# Uses create-react-app with TypeScript template

# Next.js project
init-project nextjs my-site
# Creates Next.js app with TypeScript and Tailwind

# Express TypeScript API
init-project express my-server
# Creates Express app with TypeScript, CORS, Helmet
```

### 🔍 **Project Health Monitoring**

```bash
project-health
# Checks:
# - Outdated dependencies (npm outdated)
# - Security vulnerabilities (npm audit)
# - TypeScript compilation (tsc --noEmit)
# - Common issues (.gitignore, README.md)
```

### 📦 **Intelligent Package Management**

```bash
smart-install express
# Automatically detects and uses:
# - bun (if bun.lockb exists)
# - pnpm (if pnpm-lock.yaml exists)
# - npm (fallback)
```

## 🔀 Git Workflow

### 📝 **Conventional Commits**
```bash
quick-commit feat "implement user authentication"
quick-commit fix "resolve memory leak in cache"
quick-commit docs "update API documentation"
quick-commit refactor "simplify user service" auth
```

### 🌿 **Branch Management**
```bash
git-feature user-auth        # Creates feature/user-auth branch
git-hotfix critical-bug      # Creates hotfix/critical-bug branch
git-clean-branches           # Remove merged branches
```

### 📊 **Repository Analysis** (with git-extras)
```bash
gsum                # Repository summary with contributor stats
geff                # Show effort per file (who worked on what)
gline               # Line count summary
ginfo               # Repository information
```

## 📦 Installation Options

### 🎯 **Package Categories**

Your dotfiles include these package categories:

#### **development** - Core Development Tools
- git, curl, wget, jq, tree, htop

#### **typescript** - Node.js & TypeScript
- node, typescript, ts-node, nodemon

#### **modern_cli** - Modern CLI Replacements
- ripgrep, fd, bat, exa, fzf, zoxide, starship, direnv, tldr

#### **developer_tools** - Advanced Utilities
- git-extras, gh (GitHub CLI), just, navi, hyperfine

#### **docker** - Container Development
- docker, docker-compose

#### **productivity** - Terminal & Editors
- tmux, nano, micro

#### **optional** - Nice-to-Have Tools
- lazygit, httpie, glances, bandwhich

### 🛠️ **Selective Installation**
```bash
# Install specific categories
./scripts/install-packages.sh modern_cli
./scripts/install-packages.sh typescript developer_tools
./scripts/install-packages.sh --optional    # Include optional tools

# Install everything
./scripts/install-packages.sh
```

## 🧪 Testing & Validation

### 🔍 **Test Your Setup**
```bash
./test/test-dotfiles.sh
# Tests:
# - Core files exist and are symlinked correctly
# - Required tools are available
# - Shell functions work
# - Git configuration is valid
# - Node.js/TypeScript setup
# - Oh My Zsh and plugins
# - Performance (shell startup time)
```

## 🔄 Maintenance

### 📊 **Keep Everything Updated**
```bash
# Sync dotfiles and update all tools
./scripts/sync-settings.sh
# - Pulls latest dotfiles changes
# - Updates Homebrew packages (macOS)
# - Updates APT packages (Ubuntu)
# - Updates Node.js to latest LTS
# - Updates global npm packages
# - Updates Bun
```

### 🗂️ **Backup Management**
```bash
# Create manual backup
./scripts/backup-configs.sh
# Creates timestamped backup in ~/.dotfiles-backup-YYYYMMDD-HHMMSS

# Automated backups (add to crontab)
crontab -e
# Add: 0 0 * * 0 ~/dotfiles/scripts/backup-configs.sh
```

## 🐛 Troubleshooting

### 🔧 **Common Issues**

#### **Shell Not Loading New Config**
```bash
source ~/.zshrc                    # Reload configuration
# or restart terminal
```

#### **Oh My Zsh Plugins Not Working**
```bash
# Reinstall Oh My Zsh plugins
cd ~/.oh-my-zsh/custom/plugins
git clone https://github.com/zsh-users/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting
```

#### **Modern CLI Tools Not Working**
```bash
# Check if tools are installed
which bat exa fd rg fzf zoxide

# Install missing tools
./scripts/install-packages.sh modern_cli
```

#### **Git Configuration Issues**
```bash
# Set up git credentials
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Verify global gitignore
git config --global core.excludesfile ~/.gitignore_global
```

#### **Node.js/NVM Issues**
```bash
# Reload NVM
source ~/.zshrc

# Install latest LTS
nvm install --lts
nvm use --lts
nvm alias default lts/*
```

### 🧪 **Performance Issues**

#### **Slow Shell Startup**
```bash
# Benchmark startup time
time zsh -i -c exit

# Profile startup (advanced)
zsh -xvs 2>&1 | ts -i "%.s" > /tmp/zsh-startup.log
```

#### **Test Individual Components**
```bash
# Test specific functions
source ~/.aliases && typeset -f create-ts-project
source ~/.modern-aliases && which bat
```

## 📚 Additional Resources

### 🔗 **Curated Lists Used**
- [awesome-dotfiles](https://github.com/webpro/awesome-dotfiles) - Dotfile management best practices
- [awesome-devenv](https://github.com/jondot/awesome-devenv) - Development environment tools
- [awesome-shell](https://github.com/alebcay/awesome-shell) - Command line tools and shell enhancements
- [awesome-zsh-plugins](https://github.com/unixorn/awesome-zsh-plugins) - Zsh frameworks and plugins

### 🛠️ **Tool Documentation**
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) - Zsh framework
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Zsh theme
- [Homebrew](https://brew.sh/) - Package manager for macOS
- [dotbot](https://github.com/anishathalye/dotbot) - Dotfile management tool

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Final Warning

**This repository contains personal configurations. Review all scripts and configurations before using them on your system. Always backup your existing configurations first.**

## 🤝 Contributing

Feel free to:
- Fork this repository for your own use
- Submit issues for bugs or suggestions
- Contribute improvements via pull requests

**Remember**: This is primarily a personal dotfiles repository, so changes will be evaluated based on my workflow needs.