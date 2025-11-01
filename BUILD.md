# Building the Dotfiles CLI

This project uses Bun to compile TypeScript into native executables for multiple platforms.

## Build Scripts

### Local Development
```bash
bun run build:local    # Build for current platform
bun run dev           # Run in development mode
```

### Production Builds

#### All Platforms
```bash
bun run build         # Build for all platforms (requires bun support for all)
```

#### Per Platform
```bash
bun run build:mac     # Build macOS executables (x64 + ARM64)
bun run build:ubuntu  # Build Linux executables (x64 + ARM64)
```

### Build Outputs

The build process generates 4 separate executables:

- `dist/mac/dotfiles` - macOS x64 (Intel)
- `dist/mac-arm/dotfiles` - macOS ARM64 (Apple Silicon)
- `dist/ubuntu/dotfiles` - Linux x64
- `dist/ubuntu-arm/dotfiles` - Linux ARM64

## Distribution

The compiled executables are self-contained and require NO runtime dependencies:
- No Bun runtime needed
- No Node.js needed
- No Python needed
- Works out of the box on the target platform

## GitHub Actions

Builds are automated via `.github/workflows/build-release.yml`:
- Triggers on version tags (`v*`)
- Builds all 4 executables
- Creates GitHub release with all artifacts

## Using the Executable

After building, users can simply download and run:

```bash
# Download appropriate executable for their platform
curl -L -o dotfiles https://github.com/user/dotfiles/releases/download/v2.0.0/dotfiles-macos-arm64

# Make executable
chmod +x dotfiles

# Run
./dotfiles --help
./dotfiles bootstrap
```

