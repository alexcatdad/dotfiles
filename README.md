# 🚀 Ultimate TypeScript Developer Dotfiles

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Ubuntu-blue)](https://github.com/alexalexandrescu/dotfiles)

**⚠️ DISCLAIMER: This is a public repository. Use at your own risk. Always review code before running on your system. Backup your existing configurations before installation.**

My personal dotfiles configuration optimized for TypeScript development across macOS and Ubuntu environments, enhanced with the best tools from the awesome developer community.

**✨ NEW: Built with TypeScript + Bun** - A single, self-contained executable with no runtime dependencies!

## 📋 Table of Contents

- [Quick Installation](#-quick-installation)
- [Zero-Config Setup](#-zero-config-setup)
- [Architecture](#-architecture)
- [What's Included](#%EF%B8%8F-whats-included)
- [CLI Commands](#-cli-commands)
- [Installation Options](#-installation-options)
- [Tool Usage Guide](#-tool-usage-guide)
- [Maintenance](#-maintenance)
- [Troubleshooting](#-troubleshooting)

## 🚀 Quick Installation

### 🌟 Zero-Config Setup (New Machine)

**No Git required!** Just download and run:

```bash
curl -L https://github.com/alexalexandrescu/dotfiles/releases/latest/download/install.sh | bash
./dotfiles bootstrap
```

This will:
- Detect your platform (macOS/Linux, Intel/ARM)
- Download the correct executable
- Set up your complete development environment

See [INSTALL.md](INSTALL.md) for detailed installation instructions.

### 🛠️ Development Setup

For development or if you have Git configured:

```bash
git clone https://github.com/alexalexandrescu/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Install dependencies
bun install

# Build executable
bun run build:local

# Run commands
./dist/dotfiles bootstrap
```

## 🏗️ Architecture

This project has been completely refactored from bash to TypeScript:

### Technology Stack
- **TypeScript** - Full type safety
- **Bun** - Fast runtime and build tool
- **Zod** - Runtime validation
- **Commander** - CLI framework
- **Inquirer** - Interactive prompts
- **Chalk** - Colored output

### Project Structure

```
src/
├── cli.ts                 # Main entry point
├── config/                # Configuration system
│   ├── schema.ts         # Zod schemas
│   ├── loader.ts         # Config loading
│   └── types.ts          # TypeScript types
├── commands/              # All CLI commands
│   ├── bootstrap.ts      # Full environment setup
│   ├── install.ts        # Installation
│   ├── packages.ts       # Package management
│   ├── sync.ts           # Sync updates
│   ├── backup.ts         # Backup configs
│   └── test.ts           # Test suite
├── core/                  # Core functionality
│   ├── dependencies.ts   # Dependency checking
│   ├── package-manager.ts # Package installation
│   ├── platform.ts       # OS detection
│   └── symlinks.ts       # Symlink management
└── utils/                 # Utilities
    ├── logger.ts         # Logging
    ├── spinner.ts        # Progress
    └── prompt.ts         # Prompts

config.json               # Consolidated configuration (validated with Zod)
```

### Key Features

#### 1. Smart Symlink Management
- Won't overwrite application-managed configs
- Skips recently modified files
- Protects `.config/` directories
- Clear warnings for skipped files

#### 2. Dependency Checking
- Tiered dependency verification
- Auto-installation with confirmation
- Works without Git configured
- Zero runtime dependencies

#### 3. Multi-Platform Builds
- macOS Intel (x64) + Apple Silicon (ARM64)
- Linux Intel (x64) + ARM64
- Self-contained executables

## 📋 CLI Commands

```bash
# Full environment setup (new machines)
dotfiles bootstrap

# Install dotfiles (existing systems)
dotfiles install [--safe]

# Install packages from categories
dotfiles packages [categories]

# Update all tools
dotfiles sync

# Backup existing configs
dotfiles backup

# Run test suite
dotfiles test

# Check dependencies
dotfiles check-deps

# Show help
dotfiles --help
```

## 📦 What's Included

### Core Development Tools
- **Git** - Version control
- **Node.js** - JavaScript runtime (via NVM)
- **Bun** - Fast JavaScript runtime
- **TypeScript** - Type-safe JavaScript

### Modern CLI Tools
- **ripgrep** - Fast text search
- **fd** - Modern find replacement
- **bat** - Syntax-highlighted cat
- **eza** - Modern ls replacement
- **fzf** - Fuzzy finder
- **zoxide** - Smart cd
- **starship** - Cross-shell prompt
- **direnv** - Environment switcher

### Developer Utilities
- **git-extras** - Advanced Git tools
- **gh** - GitHub CLI
- **just** - Command runner
- **hyperfine** - Benchmarking
- **tmux** - Terminal multiplexer
- **micro** - Terminal editor

### Development Functions

#### Project Creation
```bash
create-ts-project my-app      # TypeScript project with proper setup
init-project react my-app      # Create React/Next.js/Express projects
smart-install express          # Auto-detect package manager
```

#### Workflow
```bash
project-health                 # Check dependencies, TypeScript compilation
quick-commit feat "message"    # Conventional commits
switch-node                    # Use .nvmrc or LTS
bench-cmd "ls -la"            # Benchmark command execution
```

## 🛠️ Installation Options

### Complete Bootstrap
Sets up everything from scratch:
```bash
./dotfiles bootstrap
```

### Safe Installation
Interactive mode preserving existing configs:
```bash
./dotfiles install --safe
```

### Package-Only Installation
Install modern CLI tools without configs:
```bash
./dotfiles packages modern_cli developer_tools
```

### Preview Installation
See what would be installed:
```bash
./dotfiles packages --dry-run modern_cli
```

## 🔧 Maintenance

### Update Dotfiles
```bash
./dotfiles sync
```

### Backup Configurations
```bash
./dotfiles backup
```

### Run Tests
```bash
./dotfiles test
```

### Check Dependencies
```bash
./dotfiles check-deps
```

## 🚨 Troubleshooting

### "Permission denied"
```bash
chmod +x dotfiles
```

### "Config not found"
Make sure you're in the directory containing `config.json`.

### "Wrong architecture"
Download the correct executable for your platform from [Releases](https://github.com/alexalexandrescu/dotfiles/releases/latest).

### Dependency Issues
```bash
./dotfiles check-deps          # Check what's missing
./dotfiles check-deps --auto-install  # Auto-install missing deps
```

## 📚 Additional Resources

- [INSTALL.md](INSTALL.md) - Detailed installation guide
- [QUICK-START.md](QUICK-START.md) - Quick start for new computers
- [BUILD.md](BUILD.md) - Build instructions
- [REFACTOR-SUMMARY.md](REFACTOR-SUMMARY.md) - Architecture details

## 🔧 Building from Source

```bash
# Install dependencies
bun install

# Build for local platform
bun run build:local

# Build for all platforms
bun run build

# Run in development
bun run dev

# Type check
bun run typecheck
```

## 📝 License

MIT License - See LICENSE file for details

## 🙏 Acknowledgments

Built with inspiration from:
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [dotbot](https://github.com/anishathalye/dotbot)
- The amazing developer tool community
