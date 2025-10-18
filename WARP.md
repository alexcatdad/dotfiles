# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Essential Commands

### Installation Methods
```bash
# Complete bootstrap for new machines
./bootstrap.sh

# Safe installation for existing systems (preserves configs)
./install-safe.sh

# Modern dotbot installation
./install

# Install specific package categories
./scripts/install-packages-yaml.sh modern_cli typescript
./scripts/install-packages-yaml.sh --optional  # Include optional tools
```

### Testing and Validation
```bash
# Run comprehensive test suite
./test/test-dotfiles.sh

# Docker-based testing (recommended for validation)
./test-docker.sh fresh    # Test bootstrap installation
./test-docker.sh safe     # Test safe installation
./test-docker.sh clean    # Clean up containers

# Test individual components
just test                 # Uses justfile (if just is installed)
```

### Package Management
```bash
# Install by category (using justfile if available)
just install-packages modern_cli developer_tools
just install-optional-packages

# Or use script directly
./scripts/install-packages-yaml.sh modern_cli developer_tools

# Update everything
./scripts/sync-settings.sh  # Updates packages, Node.js, dotfiles
```

### Maintenance
```bash
# Create backup before changes
./scripts/backup-configs.sh
just backup

# Sync and update all tools
./scripts/sync-settings.sh
```

## Architecture Overview

### Multi-Tier Installation System
This dotfiles repository supports multiple installation approaches:
- **`bootstrap.sh`** - Complete environment setup from scratch
- **`install-safe.sh`** - Interactive installation preserving existing configurations
- **`install` (dotbot)** - Declarative configuration using `install.conf.yaml`
- **YAML Package Installer** - `scripts/install-packages-yaml.sh` for cross-platform package installation

### Configuration Layer Structure
```
shared/          # Cross-platform configurations (zsh, git, aliases)
macos/           # macOS-specific configs (Brewfile, platform aliases)
ubuntu/          # Ubuntu-specific configs and platform-specific tools
scripts/         # Automation and maintenance scripts
test/            # Comprehensive testing framework
.github/workflows/ # CI/CD automation (5 workflows)
```

### Package Management Architecture
The `packages.yaml` file defines cross-platform package installations using categories:
- `development` - Core dev tools (git, curl, jq, tree, htop)
- `typescript` - Node.js ecosystem tools
- `modern_cli` - Enhanced Unix tools (bat, exa, ripgrep, fd, fzf, zoxide)
- `developer_tools` - Advanced utilities (git-extras, gh, hyperfine, just, navi)
- `docker`, `productivity`, `optional` - Specialized tool sets

The `scripts/install-packages-yaml.sh` script processes this YAML to install packages using the appropriate package manager (brew/apt).

## Shell Configuration Loading Order

1. `shared/.zshrc` - Main configuration with Oh My Zsh
2. `shared/.env-detection` - Environment detection functions
3. `shared/.aliases` - Core development aliases and functions
4. `shared/.modern-aliases` - Modern CLI tool integrations
5. `shared/.dev-automations` - Advanced development functions
6. Platform-specific `.zshrc.local` (from macos/ or ubuntu/)

## Key Development Functions

### Project Creation
- `create-ts-project <name>` - Creates TypeScript project with proper setup
- `init-project <type> <name>` - Creates projects (typescript/react/nextjs/express)
- `smart-install <package>` - Auto-detects package manager (bun/pnpm/npm)

### Development Workflow
- `project-health` - Checks dependencies, security, TypeScript compilation
- `dev` - Intelligently starts development server
- `switch-node`/`use-node` - Uses .nvmrc or defaults to LTS
- `quick-commit <type> <message>` - Conventional commits

### Git Workflow
- `git-feature <name>` - Creates feature branch
- `git-hotfix <name>` - Creates hotfix branch
- `git-clean-branches` - Removes merged branches

## Testing Framework

The comprehensive test suite (`test/test-dotfiles.sh`) validates:
- Core file existence and symlink verification
- Tool availability (git, zsh, node, npm, bun)
- Shell function testing
- Git configuration validation
- Oh My Zsh plugin verification
- Performance testing (shell startup time < 2s)

Tests provide colored output with detailed failure reporting and counters.

## Cross-Platform Support

The codebase handles platform differences through:
- Conditional logic in dotbot configuration (OS detection)
- Platform-specific directories (`macos/` vs `ubuntu/`)
- Package name mapping in `packages.yaml`
- Environment detection functions in `shared/.env-detection`
- OS-specific aliases in `.zshrc.local` files

## GitHub Actions Automation

Five workflows provide continuous validation:
1. **`test-dotfiles.yml`** - Cross-platform testing with multiple installation methods
2. **`security-check.yml`** - Secret detection and shell validation
3. **`update-dependencies.yml`** - Monthly automated updates
4. **`update-docs.yml`** - Documentation consistency
5. **`validate-fresh-install.yml`** - Fresh environment testing

## TypeScript Development Focus

Specifically optimized for TypeScript developers with:
- Intelligent package manager detection (bun > pnpm > npm)
- Pre-configured development environments (Node.js LTS, TypeScript globals)
- Smart project templates with proper tooling setup
- Modern CLI tools enhancing development workflow
- Git workflow optimizations for feature development

## Important Files

### `install.conf.yaml` (Dotbot Configuration)
Declarative configuration defining symlinks, directory creation, and setup commands.

### `packages.yaml` (Package Definitions)
Structured cross-platform package definitions with metadata and optional flags.

### `justfile` (Command Runner)
Provides convenient commands for installation, testing, and maintenance tasks.