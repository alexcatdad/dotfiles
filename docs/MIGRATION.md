# Migration Guide

This guide helps you migrate to these dotfiles from other setups while preserving your important configurations and customizations.

## Pre-Migration Checklist

### 1. Backup Your Current Configuration

**Always backup before migrating!** Our backup script can help:

```bash
# Clone the dotfiles first
git clone https://github.com/alexalexandrescu/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run the backup script
./scripts/backup-configs.sh
```

This creates a timestamped backup in `~/.dotfiles-backup-YYYYMMDD-HHMMSS/`

### 2. Document Your Current Setup

Before migrating, document what you currently have:

```bash
# List your current shell
echo $SHELL

# Check current aliases and functions
alias | head -20
typeset -f | head -20

# Check your PATH
echo $PATH | tr ':' '\n'

# List your current Homebrew packages (macOS)
brew list > ~/current-brew-packages.txt 2>/dev/null

# List your current npm global packages
npm list -g --depth=0 > ~/current-npm-globals.txt 2>/dev/null

# Check your current Git config
git config --global --list > ~/current-git-config.txt
```

## Migration Strategies

### Strategy 1: Clean Install (Recommended for New Machines)

Best for: Fresh installs, VMs, or when you want a complete reset.

```bash
# Full bootstrap installation
git clone https://github.com/alexalexandrescu/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

### Strategy 2: Safe Migration (Recommended for Existing Systems)

Best for: Existing development machines with important configurations.

```bash
# Safe installation with prompts
git clone https://github.com/alexalexandrescu/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install-safe.sh
```

This will:
- ✅ Prompt before overwriting existing files
- ✅ Create backups automatically
- ✅ Allow you to review changes
- ✅ Skip files you want to keep

### Strategy 3: Gradual Migration

Best for: When you want to migrate slowly and test changes.

1. **Start with package installation only:**
   ```bash
   cd ~/dotfiles
   ./scripts/install-packages-yaml.sh modern_cli
   ```

2. **Add shell enhancements gradually:**
   ```bash
   # Test modern aliases without overwriting your shell config
   source shared/.modern-aliases
   ```

3. **Migrate configurations one by one:**
   ```bash
   # Just link Git configuration
   ln -sf ~/dotfiles/shared/.gitconfig ~/.gitconfig
   ```

## Migrating from Specific Setups

### From Oh My Zsh

If you're already using Oh My Zsh:

1. **Check your current plugins:**
   ```bash
   echo $plugins  # In your current .zshrc
   ```

2. **Compare with our plugins:**
   We use: `git`, `z`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions`

3. **Migrate custom plugins:**
   ```bash
   # Copy your custom plugins to the new setup
   cp -r ~/.oh-my-zsh/custom/plugins/* ~/.oh-my-zsh/custom/plugins/
   ```

4. **Merge your customizations:**
   ```bash
   # Create a local override file (see Customization section)
   touch ~/dotfiles/shared/.zshrc.local
   # Add your custom configurations there
   ```

### From Bash

If you're coming from Bash:

1. **Export your bash aliases and functions:**
   ```bash
   # Save your current bash config
   cp ~/.bashrc ~/.bashrc.backup
   cp ~/.bash_profile ~/.bash_profile.backup

   # Extract aliases and functions
   grep "^alias " ~/.bashrc > ~/bash_aliases.txt
   grep "^function\|^[a-zA-Z_][a-zA-Z0-9_]*\s*()" ~/.bashrc > ~/bash_functions.txt
   ```

2. **Convert to Zsh format:**
   Most bash aliases and functions work in Zsh, but check our `.aliases` file for examples.

3. **Add to local overrides:**
   ```bash
   # Add your converted aliases to local overrides
   echo "# Converted from bash" >> ~/dotfiles/shared/.zshrc.local
   cat ~/bash_aliases.txt >> ~/dotfiles/shared/.zshrc.local
   ```

### From Fish Shell

If you're coming from Fish:

1. **Export Fish configuration:**
   ```bash
   # Backup Fish config
   cp -r ~/.config/fish ~/fish_backup
   ```

2. **Convert Fish functions:**
   Fish functions need to be rewritten for Zsh. Check our function examples in `.aliases` and `.dev-automations`.

3. **Migrate abbreviations:**
   Fish abbreviations can become Zsh aliases. Add them to your local overrides.

### From Vim to Modern Editors

If you want to transition from Vim to modern editors:

1. **Our setup includes configurations for:**
   - VSCode (in `shared/.vscode/settings.json`)
   - Cursor AI (in `shared/.cursor/settings.json`)
   - Micro terminal editor (lightweight alternative)

2. **Keep Vim as backup:**
   ```bash
   # The setup doesn't overwrite your .vimrc
   # You can still use vim when needed
   ```

## Preserving Your Customizations

### Git Configuration

If you have specific Git settings:

```bash
# Before migration, save your current config
git config --global --list > ~/my-git-config.txt

# After migration, re-apply specific settings
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Or edit ~/.gitconfig directly
```

### SSH Keys and Credentials

**These are never touched by the dotfiles installation:**
- SSH keys (`~/.ssh/`)
- AWS credentials (`~/.aws/`)
- Docker credentials
- API keys and tokens

### Project-Specific Settings

**Preserve project configurations:**
- `.env` files
- Project-specific `.vscode/` folders
- `package.json` and lock files
- `.gitignore` files in projects

## Post-Migration Tasks

### 1. Verify Installation

```bash
# Run the test suite
./test/test-dotfiles.sh

# Check that your shell functions work
source ~/.zshrc
create-ts-project test-project
```

### 2. Restore Custom Packages

```bash
# Reinstall your custom Homebrew packages
diff current-brew-packages.txt <(brew list) | grep "^<" | cut -c3- | xargs brew install

# Reinstall custom npm packages
diff current-npm-globals.txt <(npm list -g --depth=0) | grep "^<" | cut -c3- | xargs npm install -g
```

### 3. Update Your Workflow

Learn the new commands and shortcuts:
- `init-project` - Create new projects
- `dev` - Smart development server start
- `search` - Enhanced search with ripgrep
- `fo` - Fuzzy find and open files
- `fcd` - Fuzzy change directory

## Rollback Instructions

If something goes wrong, you can rollback:

### Quick Rollback

```bash
# Restore from automatic backup
BACKUP_DIR=$(ls -t ~/.dotfiles-backup-* | head -1)
echo "Restoring from: $BACKUP_DIR"

# Restore key files
cp "$BACKUP_DIR/.zshrc" ~/
cp "$BACKUP_DIR/.gitconfig" ~/
cp "$BACKUP_DIR/.vimrc" ~/ 2>/dev/null || true

# Reload shell
exec zsh
```

### Complete Rollback

```bash
# Remove dotfiles symlinks
find ~ -maxdepth 1 -type l -exec ls -la {} \; | grep dotfiles | cut -d' ' -f9 | xargs rm

# Restore all backed up files
cp -r "$BACKUP_DIR/"* ~/

# Remove the dotfiles directory
rm -rf ~/dotfiles

# Reload shell
exec $SHELL
```

## Customization After Migration

Once migrated, see [CUSTOMIZATION.md](./CUSTOMIZATION.md) for:
- Adding local overrides
- Customizing package selections
- Adding your own functions
- Project-specific configurations

## Common Migration Issues

### Issue: Shell Startup is Slow

**Solution:**
```bash
# Check what's slowing down startup
time zsh -i -c exit

# Disable heavy plugins temporarily
# Edit ~/.zshrc and comment out plugins you don't need
```

### Issue: Some Commands Not Found

**Solution:**
```bash
# Ensure packages are installed
./scripts/install-packages-yaml.sh --help

# Check if command is aliased differently
which <command>
alias | grep <command>
```

### Issue: Git Credentials Lost

**Solution:**
```bash
# Re-configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Re-authenticate with GitHub
gh auth login
```

### Issue: Node.js/npm Issues

**Solution:**
```bash
# Ensure NVM is properly loaded
source ~/.zshrc

# Reinstall Node.js
nvm install --lts
nvm alias default lts/*
nvm use default
```

## Getting Help

If you encounter issues during migration:

1. **Check the logs:**
   ```bash
   tail -f ~/.dotfiles/.install.log
   ```

2. **Run diagnostics:**
   ```bash
   ./test/test-dotfiles.sh
   ```

3. **Create an issue:**
   Include your OS, shell version, and the specific error message.

4. **Join the discussion:**
   Check existing issues and discussions in the repository.

Remember: Migration is a process, not a single event. Take your time and migrate components gradually if needed.