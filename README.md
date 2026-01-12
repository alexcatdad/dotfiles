# 🐱 paw

> Personal dotfiles manager - one command to rule them all

[![CI](https://github.com/alexalexandrescu/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/alexalexandrescu/dotfiles/actions/workflows/ci.yml)
[![Release](https://github.com/alexalexandrescu/dotfiles/actions/workflows/release.yml/badge.svg)](https://github.com/alexalexandrescu/dotfiles/releases)

A TypeScript/Bun-powered dotfiles automation system. Manages shell configuration, packages, and symlinks across macOS and Linux.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/alexalexandrescu/dotfiles/main/install.sh | bash
```

This will:
1. Clone the repo to `~/Projects/dotfiles`
2. Install the `paw` CLI to `~/.local/bin`
3. Install all packages via Homebrew
4. Symlink all config files
5. Set up your shell with Zinit, Starship, and modern CLI tools

## What You Get

### Modern Shell Setup

| Tool | Replaces | What it does |
|------|----------|--------------|
| [Starship](https://starship.rs) | bash prompt | Fast, customizable prompt (Gruvbox theme) |
| [eza](https://eza.rocks) | `ls` | Icons, git status, tree view |
| [fd](https://github.com/sharkdp/fd) | `find` | Simpler syntax, faster |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | `grep` | Blazingly fast search |
| [fzf](https://github.com/junegunn/fzf) | - | Fuzzy finder for everything |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | `cd` | Learns your habits |
| [bat](https://github.com/sharkdp/bat) | `cat` | Syntax highlighting |

### Shell Plugins (via Zinit)

- **fast-syntax-highlighting** - Command syntax colors
- **zsh-autosuggestions** - Fish-like suggestions
- **zsh-completions** - Enhanced tab completion
- **alias-tips** - Reminds you of aliases

### Packages Installed

```
starship  eza  fd  ripgrep  fzf  zoxide  jq  gh  tldr  ncdu  btop  direnv  fnm
```

Plus on macOS: `ghostty` (terminal) and `FiraCode Nerd Font`

## Commands

```bash
paw install          # Full setup: packages + symlinks
paw link             # Symlinks only
paw unlink           # Remove symlinks
paw status           # Show current state
paw doctor           # Health check & diagnostics
paw rollback         # Undo last install
paw backup list      # List backups
```

### Options

```bash
paw install --dry-run      # Preview without changes
paw install --force        # Overwrite existing (backs up first)
paw install --skip-packages # Skip Homebrew
paw doctor --verbose       # Detailed health check
```

## Config Structure

```
~/Projects/dotfiles/
├── config/
│   ├── shell/
│   │   ├── zshrc              # Main shell config
│   │   ├── zshenv             # Environment variables & PATH
│   │   └── functions/         # Custom shell functions
│   ├── starship/
│   │   └── starship.toml      # Prompt theme (Gruvbox Dark)
│   ├── git/
│   │   ├── gitconfig          # Git settings & aliases
│   │   └── ignore             # Global gitignore
│   ├── ssh/
│   │   └── config             # SSH settings (Include local)
│   ├── homebrew/
│   │   └── Brewfile           # Declarative packages
│   └── terminal/
│       └── ghostty/config     # Terminal emulator
├── dotfiles.config.ts         # Main configuration
└── install.sh                 # Bootstrap script
```

## Customization

### Machine-Specific Config

Files ending in `.local` are gitignored - perfect for machine-specific settings:

```bash
~/.zshrc.local        # Local shell additions
~/.gitconfig.local    # Name, email, signing key
~/.ssh/config.local   # Work servers, personal hosts
~/.zshenv.local       # Local environment variables
```

### Adding Packages

Edit `dotfiles.config.ts`:

```typescript
packages: {
  common: [
    "starship",
    "eza",
    // Add your packages here
    "lazygit",
    "httpie",
  ],
  darwin: [
    "font-fira-code-nerd-font",
    // macOS-only apps
    "raycast",
  ],
}
```

Or use the Brewfile directly:

```bash
# Add to ~/.config/homebrew/Brewfile
brew "lazygit"
cask "raycast"

# Then run
brew bundle --file=~/.config/homebrew/Brewfile
```

### Adding Symlinks

```typescript
symlinks: {
  "shell/zshrc": ".zshrc",
  // Add your own
  "nvim/init.lua": ".config/nvim/init.lua",
}
```

## Shell Functions

Custom functions loaded via Zinit (in `config/shell/functions/`):

| Function | What it does |
|----------|--------------|
| `extract <file>` | Extract any archive format |
| `mkcd <dir>` | Create directory and cd into it |
| `serve [port]` | Quick HTTP server |
| `myip` | Show public IP |
| `zf` | Fuzzy cd with zoxide + fzf |
| `gcof` | Interactive git branch checkout |
| `gshow` | Git log with fzf preview |
| `git-cleanup` | Delete merged branches |

## Aliases

```bash
# Modern replacements
ll          # eza -lag --git
ls          # eza with icons
tree        # eza tree view

# Git shortcuts
gs          # git status
gd          # git diff
gc          # git commit
gp          # git push
gl          # git log --oneline

# Utilities
zsh-time    # Benchmark shell startup
```

## Development

### Prerequisites

- [Bun](https://bun.sh) runtime

### Commands

```bash
bun install              # Install dependencies
bun run dev              # Run from source
bun run typecheck        # Type check
bun run build            # Build all platforms
```

### Building

```bash
# Single platform
bun build src/index.ts --compile --outfile=dist/paw

# All platforms
bun run build:all
```

## How It Works

1. **Bootstrap** (`install.sh`) - Clones repo, installs `paw` binary
2. **Config** (`dotfiles.config.ts`) - Defines symlinks, packages, templates
3. **Symlinks** - Creates links from `config/*` to `~/*`
4. **Packages** - Installs via Homebrew/Linuxbrew
5. **Templates** - Generates `.local` files for customization

The `paw` binary finds your repo by checking:
1. `$PAW_REPO` or `$DOTFILES_DIR` environment variable
2. Common paths: `~/Projects/dotfiles`, `~/.dotfiles`, etc.

## License

MIT
