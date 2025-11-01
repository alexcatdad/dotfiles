# Migration TODO

## Before Deleting Old Scripts

### 1. Install Dependencies
```bash
bun install
```

### 2. Test Build
```bash
bun run build:local
```

### 3. Test CLI
```bash
./dist/dotfiles --help
./dist/dotfiles check-deps
```

### 4. Test Installation (Dry Run)
```bash
./dist/dotfiles install --help
./dist/dotfiles packages --dry-run
```

### 5. Verify Symlink Protection
Create a test scenario:
```bash
# Create a symlink NOT managed by dotfiles
ln -s /some/other/path ~/.testrc

# Run dotfiles install
./dist/dotfiles install

# Verify it was NOT overwritten
ls -la ~/.testrc
```

### 6. Compare Old vs New
```bash
# Old way
./bootstrap.sh

# New way
./dist/dotfiles bootstrap

# Compare results
```

## After Verification

### Delete Old Files
```bash
rm bootstrap.sh
rm install-safe.sh
rm install
rm scripts/install-packages-yaml.sh
rm scripts/sync-settings.sh
rm scripts/backup-configs.sh
rm test/test-dotfiles.sh
rm test-docker.sh
rm packages.yaml
rm install.conf.yaml
```

### Update Documentation
- Update README.md with new commands
- Update CLAUDE.md with new architecture
- Remove references to old bash scripts

### Commit Changes
```bash
git add .
git commit -m "refactor: complete migration from bash to TypeScript/Bun"
```
