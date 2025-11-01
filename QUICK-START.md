# Quick Start - New Computer Setup

## No Git Required!

On a fresh machine, you don't need git configured. Just download and run.

## Step 1: Download Install Script

```bash
# macOS or Linux
curl -L <https://github.com/alexalexandrescu/dotfiles/releases/latest/download/install.sh> -o install.sh
chmod +x install.sh
./install.sh
```

Or one-liner:
```bash
curl -L <https://github.com/alexalexandrescu/dotfiles/releases/latest/download/install.sh> | bash
```

## Step 2: Bootstrap Your Machine

```bash
./dotfiles bootstrap
```

This will:
- ✅ Check and install dependencies (git, curl, brew/apt, etc.)
- ✅ Set up development tools
- ✅ Install your dotfiles
- ✅ Configure Git (will prompt for name/email)
- ✅ Set up shell environment
- ✅ Install Oh My Zsh plugins
- ✅ Install Node.js via NVM

## Step 3: Restart Terminal

```bash
# Close and reopen terminal, or:
source ~/.zshrc
```

## Alternative: Manual Download

If the install script doesn't work, download manually:

### 1. Go to Releases
<https://github.com/alexalexandrescu/dotfiles/releases/latest>

### 2. Download for Your Platform

**macOS Apple Silicon (M1/M2):**
```bash
curl -L -o dotfiles.zip <https://github.com/alexalexandrescu/dotfiles/releases/latest/download/dotfiles-macos-arm64.zip>
unzip dotfiles.zip
chmod +x dotfiles
./dotfiles bootstrap
```

**macOS Intel:**
```bash
curl -L -o dotfiles.zip <https://github.com/alexalexandrescu/dotfiles/releases/latest/download/dotfiles-macos-x64.zip>
unzip dotfiles.zip
chmod +x dotfiles
./dotfiles bootstrap
```

**Linux x64:**
```bash
curl -L -o dotfiles.tar.gz <https://github.com/alexalexandrescu/dotfiles/releases/latest/download/dotfiles-linux-x64.tar.gz>
tar -xzf dotfiles.tar.gz
chmod +x dotfiles
./dotfiles bootstrap
```

**Linux ARM64:**
```bash
curl -L -o dotfiles.tar.gz <https://github.com/alexalexandrescu/dotfiles/releases/latest/download/dotfiles-linux-arm64.tar.gz>
tar -xzf dotfiles.tar.gz
chmod +x dotfiles
./dotfiles bootstrap
```

## What Happens During Bootstrap?

1. **Dependency Check** - Verifies git, curl, package managers
2. **Package Installation** - Installs core dev tools
3. **Node.js Setup** - Installs NVM and latest LTS Node.js
4. **Zsh Setup** - Installs Oh My Zsh plugins and Powerlevel10k
5. **Dotfiles Installation** - Links all your config files
6. **Git Configuration** - Sets up git user name/email

## Troubleshooting

### "Permission denied"
```bash
chmod +x dotfiles
```

### "Command not found: curl"
Install curl first (varies by OS), or use wget:
```bash
wget <https://github.com/alexalexandrescu/dotfiles/releases/latest/download/install.sh>
chmod +x install.sh
./install.sh
```

### Wrong Architecture
Check your system:
```bash
# macOS
uname -m  # Should show arm64 or x86_64

# Linux
uname -m  # Should show aarch64 (ARM) or x86_64
```

Then download the matching archive.

## Next Steps

After bootstrap:
1. Configure Powerlevel10k: `p10k configure`
2. Test your setup: `./dotfiles test`
3. Install more packages: `./dotfiles packages modern_cli`
4. Sync updates: `./dotfiles sync`

Enjoy your new development environment! 🚀

