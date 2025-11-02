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

### Delete Old Files (All Completed)
```bash
# Already removed:
# - bootstrap.sh
# - install-safe.sh
# - install
# - scripts/install-packages-yaml.sh
# - scripts/sync-settings.sh
# - scripts/backup-configs.sh
# - test/test-dotfiles.sh
# - test-docker.sh (Docker testing removed - using pipeline tests now)
# - install.conf.yaml
# - dotbot/ (submodule)
# - docker-compose.yml
# - Dockerfile
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
