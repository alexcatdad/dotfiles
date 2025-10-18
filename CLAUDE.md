# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive dotfiles repository optimized for TypeScript developers, supporting both macOS and Ubuntu environments. The architecture is built around declarative configuration management using dotbot, cross-platform package definitions, and extensive automation.

## Core Architecture

### Multi-Tier Installation System
The repository supports multiple installation approaches for different use cases:

- **`bootstrap.sh`** - Complete environment setup for new machines
- **`install` (dotbot)** - Modern declarative configuration using `install.conf.yaml`
- **`install-safe.sh`** - Interactive installation that preserves existing configurations
- **Legacy platform-specific installers** - Removed in favor of YAML-based system

### Configuration Layer Structure
```
shared/          # Cross-platform configurations (zsh, git, aliases, etc.)
macos/           # macOS-specific configs (Brewfile, platform aliases)
ubuntu/          # Ubuntu-specific configs (platform aliases)
scripts/         # Automation and maintenance scripts
test/            # Comprehensive testing framework
.github/workflows/ # CI/CD automation (5 workflows)
```

### Package Management Architecture
The `packages.yaml` file defines cross-platform package installations using categories:
- `development` - Core dev tools
- `typescript` - Node.js ecosystem
- `modern_cli` - Enhanced Unix tools (bat, exa, ripgrep, etc.)
- `developer_tools` - Advanced utilities (git-extras, gh, hyperfine)
- `docker` / `productivity` / `optional` - Specialized tool sets

The `scripts/install-packages-yaml.sh` script processes this YAML to install packages using the appropriate package manager (brew/apt) and handles global npm packages.

## Essential Development Commands

### Testing and Validation
```bash
./test/test-dotfiles.sh              # Run comprehensive test suite
./scripts/install-packages-yaml.sh --help # Show package installation options
```

### Package Management
```bash
./scripts/install-packages-yaml.sh modern_cli              # Install specific category
./scripts/install-packages-yaml.sh --optional              # Include optional tools
./scripts/install-packages-yaml.sh typescript docker      # Multiple categories
```

### Maintenance
```bash
./scripts/sync-settings.sh          # Update all tools and sync dotfiles
./scripts/backup-configs.sh         # Create timestamped backup
```

### Installation Testing
```bash
# Test different installation methods
./install                           # Test dotbot installation
echo "y\ny\ny\ny\nn" | ./install-safe.sh  # Test safe installation
```

## Key Configuration Files

### `install.conf.yaml` (Dotbot Configuration)
Declarative configuration that defines:
- Symlinks from `shared/` and platform-specific directories to home directory
- Conditional linking based on OS detection
- Directory creation (e.g., `~/.config/micro`)
- Shell commands for setup (git config, Oh My Zsh installation)

### `packages.yaml` (Package Definitions)
Structured package definitions with:
- Cross-platform package mappings (`macos` vs `ubuntu` package names)
- Global npm package specifications (`global_npm`)
- Optional package flags
- Descriptive metadata for documentation generation

### Shell Configuration Architecture
The shell setup loads in this order:
1. `shared/.zshrc` - Main configuration with Oh My Zsh
2. `shared/.env-detection` - Environment detection functions
3. `shared/.aliases` - Core development aliases and functions
4. `shared/.modern-aliases` - Modern CLI tool integrations
5. `shared/.dev-automations` - Advanced development functions
6. Platform-specific `.zshrc.local` (macos/ or ubuntu/)

## Development Functions and Aliases

### Project Creation Functions
- `create-ts-project <name>` - Creates TypeScript project with proper setup
- `init-project <type> <name>` - Creates projects (typescript/react/nextjs/express)
- `smart-install <package>` - Auto-detects package manager (bun/pnpm/npm)

### Development Workflow
- `project-health` - Checks dependencies, security, TypeScript compilation
- `quick-commit <type> <message>` - Conventional commits
- `switch-node` - Uses .nvmrc or defaults to LTS
- `bench-cmd <command>` - Benchmarks command execution

## Testing Framework

The `test/test-dotfiles.sh` script provides comprehensive validation:
- Core file existence and symlink verification
- Tool availability checks (git, zsh, node, etc.)
- Shell function testing
- Git configuration validation
- Oh My Zsh plugin verification
- Performance testing (shell startup time)

Tests use a colored output system with counters and provide detailed failure reporting.

## GitHub Actions Automation

Five workflows provide continuous validation:
1. **`test-dotfiles.yml`** - Cross-platform testing (Ubuntu/macOS) with multiple installation methods
2. **`security-check.yml`** - Secret detection, shell validation, dangerous command checking
3. **`update-dependencies.yml`** - Monthly automated updates for Oh My Zsh, NVM, etc.
4. **`update-docs.yml`** - Documentation consistency and package count updates
5. **`validate-fresh-install.yml`** - Fresh environment testing and performance benchmarking

## Cross-Platform Considerations

The codebase handles platform differences through:
- Conditional logic in dotbot configuration (`if` statements)
- Platform-specific directories (`macos/` vs `ubuntu/`)
- Package name mapping in `packages.yaml`
- Environment detection functions in `shared/.env-detection`
- OS-specific aliases and tools in `.zshrc.local` files

## TypeScript Development Focus

The configuration is specifically optimized for TypeScript developers with:
- Intelligent package manager detection (bun > pnpm > npm)
- Pre-configured development environments (Node.js LTS, TypeScript globals)
- Smart project templates with proper tooling setup
- Modern CLI tools that enhance development workflow
- Git workflow optimizations for feature development