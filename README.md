# 🐱 paw

> Personal dotfiles manager - one command to rule them all

[![CI](https://github.com/alexcatdad/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/alexcatdad/dotfiles/actions/workflows/ci.yml)
[![Release](https://github.com/alexcatdad/dotfiles/actions/workflows/release.yml/badge.svg)](https://github.com/alexcatdad/dotfiles/releases)

A TypeScript/Bun-powered dotfiles automation system. Manages shell configuration, packages, and symlinks across macOS and Linux.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/alexcatdad/dotfiles/main/install.sh | bash
```

This will:
1. Clone the repo to `~/dotfiles`
2. Install the `paw` CLI to `~/.local/bin`
3. Install all packages via Homebrew
4. Symlink all config files
5. Set up your shell with Zinit, Starship, and modern CLI tools

### Install Options

```bash
# Check version without installing
curl -fsSL ... | bash -s -- --version

# Force reinstall even if up to date
curl -fsSL ... | bash -s -- --force

# Accept breaking changes on major upgrades
curl -fsSL ... | bash -s -- --upgrade

# Skip package installation
curl -fsSL ... | bash -s -- --skip-packages
```

## What You Get

### Modern Shell Setup

| Tool | Replaces | What it does |
|------|----------|--------------|
| [Starship](https://starship.rs) | bash prompt | Fast, customizable prompt (Gruvbox Dark Powerline) |
| [eza](https://eza.rocks) | `ls` | Icons, git status, tree view |
| [fd](https://github.com/sharkdp/fd) | `find` | Simpler syntax, faster |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | `grep` | Blazingly fast search |
| [fzf](https://github.com/junegunn/fzf) | - | Fuzzy finder for everything |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | `cd` | Learns your habits |
| [atuin](https://atuin.sh) | shell history | SQLite-backed, syncable history |
| [dust](https://github.com/bootandy/dust) | `du` | Intuitive disk usage |

### Shell Plugins (via Zinit)

- **fast-syntax-highlighting** - Command syntax colors
- **zsh-autosuggestions** - Fish-like suggestions
- **zsh-completions** - Enhanced tab completion
- **alias-tips** - Reminds you of aliases

### Packages Installed

```
starship  eza  fd  ripgrep  fzf  zoxide  jq  gh  tldr  dust  btop  direnv  fnm  atuin
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
~/dotfiles/
├── config/
│   ├── shell/
│   │   ├── zshrc              # Main shell config
│   │   ├── zshenv             # Environment variables & PATH
│   │   └── functions/         # Custom shell functions
│   │       ├── git.zsh        # Git helper functions
│   │       └── utils.zsh      # General utilities
│   ├── starship/
│   │   └── starship.toml      # Prompt theme (Gruvbox Dark Powerline)
│   ├── git/
│   │   ├── gitconfig          # Git settings & aliases
│   │   └── ignore             # Global gitignore
│   ├── claude/
│   │   ├── settings.json      # Claude Code settings
│   │   └── statusline.sh      # Claude Code Powerline statusline
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
~/.zshenv.local       # Local environment variables
~/.gitconfig.local    # Name, email, signing key
~/.ssh/config.local   # Work servers, personal hosts
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

### General Utilities

| Function | What it does |
|----------|--------------|
| `extract <file>` | Extract any archive format |
| `mkcd <dir>` | Create directory and cd into it |
| `serve [port]` | Quick HTTP server (default: 8000) |
| `myip` / `localip` | Show public/local IP |
| `zf` | Fuzzy cd with zoxide + fzf |
| `note [text]` | Quick timestamped notes |
| `weather [city]` | Weather in terminal |
| `cheat <cmd>` | Cheat sheet for commands |
| `calc <expr>` | Quick calculator |
| `killnamed <name>` | Find and kill process by name |
| `backup <file>` | Create timestamped backup |
| `duf [dir]` | Disk usage sorted by size |

### Git Functions

| Function | What it does |
|----------|--------------|
| `gcof` | Interactive branch checkout with fzf |
| `gshow` | Git log with fzf preview |
| `gadd` | Interactive staging with fzf |
| `gstash` | Interactive stash management |
| `glog` | Pretty git log graph |
| `gfind <text>` | Find commits by message |
| `gblame <file>` | Color-coded blame |
| `git-cleanup` | Delete merged branches (safe) |
| `git-amend` | Quick amend without editing |

## Aliases

```bash
# Modern replacements (eza)
ls          # eza with icons
ll          # eza -lag --git (detailed list)
la          # eza -a (show hidden)
lt          # eza -T (tree, 2 levels)
tree        # eza -T (full tree)

# Modern replacements (others)
grep        # ripgrep --smart-case
find        # fd

# Git shortcuts
g           # git
gs          # git status
gd          # git diff
gc          # git commit
gp          # git push
gl          # git log --oneline -10
gco         # git checkout

# Utilities
zsh-time    # Benchmark shell startup
zsh-trace   # Trace shell startup with timing
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
2. Common paths: `~/dotfiles`, `~/.dotfiles`, etc.

## Updates & Versioning

This project uses [Semantic Versioning](https://semver.org/):

| Update Type | Example | Requires `--upgrade` |
|-------------|---------|----------------------|
| Patch | 1.0.0 → 1.0.1 | No |
| Minor | 1.0.0 → 1.1.0 | No |
| Major | 1.0.0 → 2.0.0 | **Yes** |

### Safe Updates (automatic)

```bash
# Re-run install script - auto-updates if new version available
curl -fsSL https://raw.githubusercontent.com/alexcatdad/dotfiles/main/install.sh | bash
```

### Major Updates (breaking changes)

Major versions may include breaking changes. The install script will:
1. Detect the major version bump
2. Show what might break
3. Require explicit `--upgrade` flag

```bash
curl -fsSL ... | bash -s -- --upgrade
```

See [VERSIONING.md](VERSIONING.md) for full compatibility guarantees.

## License

MIT
