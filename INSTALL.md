# Installation Guide

## Quick Install (Recommended)

For new machines where git might not be configured:

```bash
# Download and run install script
curl -L <https://github.com/alexalexandrescu/dotfiles/releases/latest/download/install.sh> | bash
```

This will:
1. Detect your platform (macOS/Linux, Intel/ARM)
2. Download the appropriate executable
3. Extract and make it executable
4. Place `dotfiles` in current directory

## Manual Installation

### 1. Download the archive for your platform

**macOS:**
- Intel: `dotfiles-macos-x64.zip`
- Apple Silicon (M1/M2): `dotfiles-macos-arm64.zip`

**Linux:**
- x64: `dotfiles-linux-x64.tar.gz`
- ARM64: `dotfiles-linux-arm64.tar.gz`

### 2. Extract the archive

**macOS (zip):**
```bash
unzip dotfiles-macos-arm64.zip
```

**Linux (tar.gz):**
```bash
tar -xzf dotfiles-linux-x64.tar.gz
```

### 3. Make executable and run

```bash
chmod +x dotfiles
./dotfiles --help
```

## Usage

### Bootstrap New Machine

```bash
./dotfiles bootstrap
```

This will:
- Check and install dependencies
- Set up development tools
- Install dotfiles
- Configure Git
- Set up shell environment

### Install on Existing Machine

```bash
./dotfiles install --safe
```

Interactive mode that:
- Preserves existing configurations
- Backs up current files
- Lets you choose what to install

### Install Packages

```bash
./dotfiles packages typescript modern_cli
```

Install specific package categories.

### Check Dependencies

```bash
./dotfiles check-deps
```

Verify all required dependencies are installed.

## No Git Required!

The downloaded executable is completely self-contained:
- No Bun needed
- No Node.js needed
- No Python needed
- No Git needed
- Just download and run!

## Version Information

Check the latest release:
- GitHub Releases: <https://github.com/alexalexandrescu/dotfiles/releases>
- Each push to `main` creates a new release automatically
- Version format: `YYYY.MM.DD-commitSHA`

## Troubleshooting

### Permission Denied
```bash
chmod +x dotfiles
```

### Wrong Architecture
Make sure you downloaded the correct version for your platform:
- macOS ARM: `dotfiles-macos-arm64.zip`
- macOS Intel: `dotfiles-macos-x64.zip`
- Linux ARM: `dotfiles-linux-arm64.tar.gz`
- Linux x64: `dotfiles-linux-x64.tar.gz`

### Download Failed
Try downloading directly from:
<https://github.com/alexalexandrescu/dotfiles/releases/latest>

