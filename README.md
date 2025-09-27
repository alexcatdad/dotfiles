# Dotfiles

My personal dotfiles configuration for macOS development machines and Ubuntu VMs.

## Quick Installation

### macOS
```bash
git clone https://github.com/alexalexandrescu/dotfiles.git
cd dotfiles
./install-macos.sh
```

### Ubuntu
```bash
git clone https://github.com/alexalexandrescu/dotfiles.git
cd dotfiles
./install-ubuntu.sh
```

## Structure

- `shared/` - Configuration files that work across both macOS and Ubuntu
- `macos/` - macOS-specific configurations (e.g., Homebrew, macOS-specific aliases)
- `ubuntu/` - Ubuntu-specific configurations (e.g., apt packages, Linux-specific settings)

## Contents

### Shared Configurations
- Shell configurations (bash, zsh)
- Git configuration
- Vim/Neovim configuration
- Tmux configuration

### macOS Specific
- Homebrew package management
- macOS system preferences
- macOS-specific aliases and functions

### Ubuntu Specific
- APT package installations
- Linux-specific aliases and functions
- Ubuntu system configurations

## Adding New Dotfiles

1. Place shared configs in `shared/`
2. Place platform-specific configs in `macos/` or `ubuntu/`
3. Run the appropriate install script to symlink new files

## Manual Installation

If you prefer manual installation, symlink files individually:

```bash
ln -sf ~/dotfiles/shared/.bashrc ~/.bashrc
ln -sf ~/dotfiles/macos/.zshrc ~/.zshrc  # macOS
ln -sf ~/dotfiles/ubuntu/.profile ~/.profile  # Ubuntu
```