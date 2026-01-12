# CLAUDE.md - Project Context for Claude Code

## Project Overview
**paw** 🐱 - Personal dotfiles automation system using TypeScript/Bun. Manages shell configuration, packages, and symlinks across macOS and Linux machines.

## Quick Commands
```bash
# Using paw CLI (after install)
paw install          # Full setup: packages + symlinks
paw link --force     # Symlinks only
paw status           # Check current state
paw doctor           # Health check
paw rollback         # Undo last install

# Development (from source)
bun run src/index.ts install --dry-run
bun run typecheck
bun run build
```

## Architecture

### CLI (`src/index.ts`)
Commands: `install`, `link`, `unlink`, `status`, `rollback`, `backup`, `doctor`

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
- `shell/functions/` - Custom shell functions (loaded via Zinit)
- `starship/starship.toml` - Gruvbox Dark prompt
- `claude/statusline.sh` - Claude Code Powerline statusline
- `git/gitconfig` - Git configuration
- `ssh/config` - SSH config with local override pattern
- `terminal/ghostty/config` - Ghostty terminal
- `homebrew/Brewfile` - Declarative package management

## Shell Stack
- **Plugin Manager**: Zinit (turbo mode for async loading)
- **Plugins**: fast-syntax-highlighting, zsh-autosuggestions, zsh-completions, alias-tips
- **Prompt**: Starship (Gruvbox Dark)
- **Node**: fnm (Fast Node Manager)
- **Navigation**: zoxide
- **Fuzzy Finder**: fzf
- **History**: atuin (SQLite-backed, syncable)

## Packages Installed
`starship`, `eza`, `fd`, `ripgrep`, `fzf`, `zoxide`, `jq`, `gh`, `tldr`, `ncdu`, `btop`, `direnv`, `fnm`, `dust`, `atuin`

## Key Aliases
```bash
ll         # eza -lag --git (list with git status)
gs         # git status
z          # zoxide (smart cd)
zsh-time   # Benchmark shell startup time
zsh-trace  # Trace shell startup with timing
```

## Shell Functions (`config/shell/functions/`)
Custom functions loaded via Zinit in turbo mode:
- `extract` - Extract any archive format
- `mkcd` - Create directory and cd into it
- `serve` - Quick HTTP server
- `myip/localip` - Get public/local IP
- `note` - Quick timestamped notes
- `zf` - Fuzzy cd with zoxide + fzf
- `gcof` - Interactive git branch checkout with fzf
- `gshow` - Git log with fzf preview
- `git-cleanup` - Delete merged branches
- `gadd` - Interactive git staging

## Machine-Specific Config
Files ending in `.local` are gitignored and machine-specific:
- `~/.zshrc.local` - Local shell additions
- `~/.gitconfig.local` - Local git config (name, email)
- `~/.ssh/config.local` - Local SSH hosts

Templates in `config/templates/` provide starting points.

## Brewfile
Alternative package management using Homebrew's bundle:
```bash
# Install packages from Brewfile
brew bundle --file=~/.config/homebrew/Brewfile

# Dump current packages to Brewfile
brew bundle dump --file=~/.config/homebrew/Brewfile --force
```

## Testing Changes
```bash
# Syntax check
zsh -n ~/.zshrc

# Dry run install
paw install --dry-run

# Force update symlinks
paw link --force

# Health check
paw doctor --verbose

# Benchmark shell startup
zsh-time
```

## CI/CD
- `.github/workflows/ci.yml` - Lint, type check, test on macOS + Linux, build binaries
- `.github/workflows/release.yml` - Creates stable release on version tags (v*)

**Automation:**
- Push to `main` → runs CI, builds all binaries, updates `latest` pre-release
- Push tag `v*` → creates stable release with binaries
- PRs → runs lint, security scan, tests

## Building
```bash
# Build for current platform
bun build src/index.ts --compile --outfile=dist/paw

# Build all platforms
bun run build:all

# Install locally
cp dist/paw-darwin-arm64 ~/.local/bin/paw
```
