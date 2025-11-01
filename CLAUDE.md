# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive dotfiles repository optimized for TypeScript developers, supporting both macOS and Ubuntu environments. The architecture is built around a modern TypeScript/Bun CLI compiled to self-contained executables.

## Core Architecture

### Modern TypeScript CLI System
The repository uses a unified TypeScript codebase compiled to native executables:

- **Main Entry**: `src/cli.ts` - CLI with commander.js
- **Configuration**: Single `config.json` validated with Zod
- **Commands**: Modular command system in `src/commands/`
- **Build Output**: Self-contained executables (no runtime dependencies)

### Project Structure
```
src/
├── cli.ts                    # Main CLI entry point
├── config/                   # Configuration system
│   ├── schema.ts            # Zod schemas for validation
│   ├── loader.ts            # Config loading & validation
│   └── types.ts             # TypeScript types
├── commands/                 # CLI commands
│   ├── bootstrap.ts         # Full environment setup
│   ├── install.ts           # Installation (safe mode)
│   ├── packages.ts          # Package management
│   ├── sync.ts              # Sync updates
│   ├── backup.ts            # Backup configs
│   └── test.ts              # Test suite
├── core/                     # Core functionality
│   ├── dependencies.ts      # Dependency checker
│   ├── package-manager.ts   # Package installation
│   ├── platform.ts          # OS detection
│   └── symlinks.ts          # Symlink management
└── utils/                    # Utilities
    ├── logger.ts            # Colored logging
    ├── spinner.ts           # Progress indicators
    └── prompt.ts            # Interactive prompts (inquirer)
```

### Configuration System

**Single `config.json`** consolidates all configuration:
- Package definitions (cross-platform mappings)
- Symlink configurations
- Installation categories and priorities
- Version constraints
- Post-install commands

Validated with Zod schemas in `src/config/schema.ts` for runtime type safety.

### Build System

**Development:**
```bash
bun install           # Install dependencies
bun run dev          # Run without compiling
bun run build:local  # Build for current platform
```

**Production:**
```bash
bun run build        # Build all platforms
```

**Build Outputs:**
- `dist/dotfiles` - macOS ARM64 (local)
- `dist/mac/dotfiles` - macOS Intel
- `dist/mac-arm/dotfiles` - macOS Apple Silicon
- `dist/ubuntu/dotfiles` - Linux x64
- `dist/ubuntu-arm/dotfiles` - Linux ARM64

### Smart Symlink Protection

The symlink management system prevents overwriting user/app configurations:

1. **Dotfiles-Managed Detection**: Only updates symlinks managed by dotfiles
2. **Recent File Protection**: Skips files modified in last hour
3. **Config Directory Protection**: Never overwrites `.config/` files
4. **Clear Warnings**: Logs why files are skipped

## Essential Development Commands

### Build & Test
```bash
bun run typecheck    # TypeScript validation
bun run build:local  # Build executable
bun run test         # Run test suite (placeholder)
```

### Run Commands
```bash
./dist/dotfiles bootstrap      # Full setup
./dist/dotfiles install --safe # Interactive install
./dist/dotfiles packages       # Install packages
./dist/dotfiles check-deps     # Verify dependencies
```

### Package Management
```bash
./dist/dotfiles packages modern_cli              # Install specific category
./dist/dotfiles packages --optional              # Include optional tools
./dist/dotfiles packages typescript docker       # Multiple categories
./dist/dotfiles packages --dry-run development   # Preview installation
```

### Maintenance
```bash
./dist/dotfiles sync                            # Update all tools
./dist/dotfiles backup                          # Create backup
./dist/dotfiles test                            # Run test suite
```

## Configuration Files

### `config.json` (Primary)
Consolidates all package and symlink configurations:
- Package definitions with cross-platform mappings
- Symlink configurations
- Installation categories and priorities
- Version constraints
- Post-install commands

### Validation
All configuration validated with Zod at runtime in `src/config/schema.ts`.

### Shell Configuration Architecture
The shell setup loads in this order:
1. `shared/.zshrc` - Main configuration
2. `shared/.env-detection` - Environment detection
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

The test suite in `src/commands/test.ts` validates:
- Core file existence and symlink verification
- Tool availability checks
- Shell function testing
- Git configuration validation
- Performance testing

## GitHub Actions Automation

**Build & Release Workflow** (`.github/workflows/build-release.yml`):
- Builds on every push to `main`
- Creates versioned releases automatically
- Builds all 4 platform executables
- Generates install script
- Releases format: `YYYY.MM.DD-commitSHA`

**Build Workflow** (`.github/workflows/build.yml`):
- CI builds on pull requests
- Type checking
- Build verification

## Cross-Platform Considerations

The codebase handles platform differences through:
- Conditional logic in configuration
- Platform-specific package names in config.json
- OS detection in `src/core/platform.ts`
- Environment detection functions
- OS-specific aliases in `.zshrc.local` files

## TypeScript Development Focus

Optimized for TypeScript developers with:
- Intelligent package manager detection
- Pre-configured development environments
- Smart project templates
- Modern CLI tools integration
- Git workflow optimizations

## Key Implementation Patterns

### Dependency Checking
```typescript
// Tiered dependency verification
checkTier1()  // Core system tools
checkTier2()  // Package managers
checkTier3()  // Language runtimes
```

### Symlink Management
```typescript
// Smart protection against overwrites
createSymlink(source, target, force)
  - Checks if managed by dotfiles
  - Skips recently modified files
  - Protects config directories
```

### Configuration Validation
```typescript
// Runtime validation with Zod
const config = configSchema.parse(rawConfig)
```

### Interactive Prompts
```typescript
// Inquirer.js for user interaction
const answer = await confirm("Proceed?")
const value = await input("Enter name:")
const selected = await select("Choose:", choices)
```

## Migration Notes

### Old System (Removed)
- bash scripts: `*.sh` files
- YAML configs: `packages.yaml`, `install.conf.yaml`
- Python dependencies for YAML parsing
- Dotbot submodule for symlinking

### New System
- Single TypeScript codebase
- Zod-validated JSON config
- Compiled self-contained executables
- Zero runtime dependencies
- Interactive CLI with inquirer

### Common Commands Translation

| Old | New |
|-----|-----|
| `./bootstrap.sh` | `./dist/dotfiles bootstrap` |
| `./install-safe.sh` | `./dist/dotfiles install --safe` |
| `./scripts/install-packages-yaml.sh packages` | `./dist/dotfiles packages packages` |
| `./scripts/sync-settings.sh` | `./dist/dotfiles sync` |
| `./test/test-dotfiles.sh` | `./dist/dotfiles test` |

## Troubleshooting

### Build Issues
```bash
bun run typecheck  # Check for TypeScript errors
rm -rf node_modules && bun install  # Clean reinstall
```

### Runtime Issues
```bash
./dist/dotfiles check-deps  # Verify dependencies
bun run dev                 # Run from source for debugging
```

### Configuration Issues
```bash
# Validate config.json
node -e "const z = require('zod'); const s = require('./src/config/schema.ts'); console.log('Valid!')"
```
