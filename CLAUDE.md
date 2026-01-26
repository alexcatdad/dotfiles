# CLAUDE.md - Project Context for Claude Code

## Project Overview
**alexcatdad/dotfiles** 🐱 - Personal dotfiles configuration. Contains shell configs, packages, and symlink mappings managed by the [paw CLI](https://github.com/alexcatdad/paw).

## Quick Commands
```bash
# Using paw CLI
paw install          # Full setup: packages + symlinks
paw link --force     # Symlinks only
paw status           # Check current state
paw sync             # Pull changes and refresh links
paw push "message"   # Commit and push changes
paw doctor           # Health check
```

## Repo Structure
```
dotfiles/
├── config/              # All dotfiles to be symlinked
│   ├── shell/           # Shell configuration
│   ├── starship/        # Prompt theme
│   ├── git/             # Git configuration
│   ├── claude/          # Claude Code settings
│   ├── homebrew/        # Brewfile
│   └── terminal/        # Terminal configs
├── dotfiles.config.ts   # Symlink/package definitions
├── install.sh           # Bootstrap script
└── CLAUDE.md            # This file
```

## Configuration (`dotfiles.config.ts`)
Defines:
- `symlinks`: Map of source (config/) to target (~/)
- `packages`: Common + platform-specific packages
- `templates`: .local file templates
- `hooks`: Pre/post install callbacks

## Config Files (`config/`)
- `shell/zshrc` - Main shell config with Zinit plugins
- `shell/functions/` - Custom shell functions
- `starship/starship.toml` - Gruvbox Dark prompt
- `git/gitconfig` - Git configuration
- `ssh/config` - SSH config with local override pattern
- `homebrew/Brewfile` - Declarative package management
- `terminal/ghostty/config` - Ghostty terminal

## Shell Stack
- **Plugin Manager**: Zinit (turbo mode)
- **Plugins**: fast-syntax-highlighting, zsh-autosuggestions, zsh-completions, alias-tips
- **Prompt**: Starship (Gruvbox Dark)
- **Node**: fnm
- **Navigation**: zoxide
- **Fuzzy Finder**: fzf
- **History**: atuin

## Machine-Specific Config
Files ending in `.local` are gitignored and machine-specific:
- `~/.zshrc.local` - Local shell additions
- `~/.gitconfig.local` - Local git config (name, email)
- `~/.ssh/config.local` - Local SSH hosts

## Testing Changes
```bash
zsh -n ~/.zshrc         # Syntax check
paw install --dry-run   # Preview install
paw link --force        # Force update symlinks
paw doctor --verbose    # Health check
zsh-time                # Benchmark shell startup
```

## Cross-Machine Sync
```bash
# On machine A (making changes)
paw push "update zsh config"

# On machine B
paw sync
```

## Related
- [paw](https://github.com/alexcatdad/paw) - The CLI that manages this repo
