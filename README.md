# 🐱 alexcatdad/dotfiles

> Personal dotfiles configuration - shell, packages, and config files

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/alexcatdad/dotfiles/main/install.sh | bash
```

This will:
1. Install the [paw](https://github.com/alexcatdad/paw) CLI
2. Clone this repo and run `paw install`

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

### Shell Plugins (via Zinit)

- **fast-syntax-highlighting** - Command syntax colors
- **zsh-autosuggestions** - Fish-like suggestions
- **zsh-completions** - Enhanced tab completion
- **alias-tips** - Reminds you of aliases

## Commands

```bash
paw install          # Full setup: packages + symlinks
paw link             # Symlinks only
paw status           # Show current state
paw sync             # Pull dotfiles and refresh links
paw push [message]   # Commit and push changes
paw doctor           # Health check & diagnostics
```

### Options

```bash
paw install --dry-run      # Preview without changes
paw install --force        # Overwrite existing (backs up first)
paw sync --quiet           # Silent sync (for shell startup)
```

## Config Structure

```
~/dotfiles/
├── config/
│   ├── shell/
│   │   ├── zshrc              # Main shell config
│   │   ├── zshenv             # Environment variables & PATH
│   │   └── functions/         # Custom shell functions
│   ├── starship/
│   │   └── starship.toml      # Prompt theme
│   ├── git/
│   │   ├── gitconfig          # Git settings & aliases
│   │   └── ignore             # Global gitignore
│   ├── claude/
│   │   └── settings.json      # Claude Code settings
│   ├── homebrew/
│   │   └── Brewfile           # Declarative packages
│   └── terminal/
│       └── ghostty/config     # Terminal emulator
├── dotfiles.config.ts         # Symlink/package configuration
└── install.sh                 # Bootstrap script
```

## Customization

### Machine-Specific Config

Files ending in `.local` are gitignored - perfect for machine-specific settings:

```bash
~/.zshrc.local        # Local shell additions
~/.gitconfig.local    # Name, email, signing key
~/.ssh/config.local   # Work servers, personal hosts
```

### Adding Packages

Edit `dotfiles.config.ts`:

```typescript
packages: {
  common: ["starship", "eza", "your-package"],
  darwin: ["font-fira-code-nerd-font"],
}
```

### Adding Symlinks

```typescript
symlinks: {
  "shell/zshrc": ".zshrc",
  "nvim/init.lua": ".config/nvim/init.lua",
}
```

## Cross-Machine Sync

On machine A (making changes):
```bash
paw push "update zsh config"
```

On machine B (shell startup auto-syncs or manually):
```bash
paw sync
```

## Updates

```bash
paw update    # Update paw binary
paw sync      # Pull dotfiles changes
```

## Related

- [paw](https://github.com/alexcatdad/paw) - The dotfiles manager CLI

## License

MIT
