# CLAUDE.md - Project Context for Claude Code

## Project Overview
Personal dotfiles automation system using TypeScript/Bun. Manages shell configuration, packages, and symlinks across macOS and Linux machines.

## Quick Commands
```bash
# Install everything (packages + symlinks)
bun run src/index.ts install

# Symlinks only
bun run src/index.ts link --force

# Check status
bun run src/index.ts status

# Rollback changes
bun run src/index.ts rollback
```

## Architecture

### CLI (`src/index.ts`)
Commands: `install`, `link`, `unlink`, `status`, `rollback`, `backup`

### Core Modules (`src/core/`)
- `config.ts` - Loads `dotfiles.config.ts`
- `packages.ts` - Homebrew/Linuxbrew package installation
- `symlinks.ts` - Symlink management with backup
- `templates.ts` - Generates `.local` files from templates
- `backup.ts` - Backup/restore/rollback functionality
- `os.ts` - Platform detection (darwin/linux)
- `logger.ts` - Colored console output

### Configuration (`dotfiles.config.ts`)
Defines:
- `symlinks`: Map of source (config/) to target (~/)
- `packages`: Common + platform-specific packages
- `templates`: .local file templates
- `hooks`: Pre/post install callbacks

### Config Files (`config/`)
- `shell/zshrc` - Main shell config with Zinit plugins
- `starship/starship.toml` - Gruvbox Dark prompt
- `claude/statusline.sh` - Claude Code Powerline statusline
- `git/gitconfig` - Git configuration
- `terminal/ghostty/config` - Ghostty terminal

## Shell Stack
- **Plugin Manager**: Zinit (turbo mode for async loading)
- **Plugins**: fast-syntax-highlighting, zsh-autosuggestions, zsh-completions, alias-tips
- **Prompt**: Starship (Gruvbox Dark)
- **Node**: fnm (Fast Node Manager)
- **Navigation**: zoxide
- **Fuzzy Finder**: fzf

## Packages Installed
`starship`, `eza`, `fd`, `ripgrep`, `fzf`, `zoxide`, `jq`, `gh`, `tldr`, `ncdu`, `btop`, `direnv`, `fnm`

## Key Aliases
```bash
ll    # eza -lag --git (list with git status)
gs    # git status
z     # zoxide (smart cd)
```

## Machine-Specific Config
Files ending in `.local` are gitignored and machine-specific:
- `~/.zshrc.local` - Local shell additions
- `~/.gitconfig.local` - Local git config (name, email)

Templates in `config/templates/` provide starting points.

## Testing Changes
```bash
# Syntax check
zsh -n ~/.zshrc

# Dry run install
bun run src/index.ts install --dry-run

# Force update symlinks
bun run src/index.ts link --force
```

## CI/CD
- `.github/workflows/test.yml` - Tests on macOS + Linux
- `.github/workflows/release.yml` - Builds standalone binaries on tag
