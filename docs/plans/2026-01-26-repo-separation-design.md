# Paw Repo Separation Design

**Date:** 2026-01-26
**Status:** Approved

## Overview

Separate the paw CLI tool from the dotfiles repository to make paw a standalone, general-purpose dotfiles manager.

## Repositories

### `alexcatdad/paw` (new)

Standalone dotfiles manager CLI.

```
paw/
├── src/
│   ├── index.ts
│   ├── core/
│   │   ├── config.ts
│   │   ├── init.ts        # NEW
│   │   ├── push.ts        # NEW
│   │   ├── symlinks.ts
│   │   ├── packages.ts
│   │   ├── sync.ts
│   │   ├── update.ts
│   │   └── ...
│   └── types/
├── package.json
├── tsconfig.json
├── install.sh             # Installs paw binary only
├── release-please-config.json
├── .release-please-manifest.json
└── .github/workflows/
    ├── ci.yml
    └── release-please.yml
```

### `alexcatdad/dotfiles` (simplified)

Personal dotfiles configuration only.

```
dotfiles/
├── config/
│   ├── shell/
│   ├── git/
│   ├── starship/
│   ├── terminal/
│   └── ...
├── dotfiles.config.ts
├── install.sh             # Thin wrapper
├── CLAUDE.md
└── README.md
```

## CLI Commands

### New Commands

```bash
paw init <repo-url>       # Clone dotfiles repo + configure paw
paw push [message]        # Stage all, commit, push dotfiles changes
```

### Existing Commands (unchanged)

```bash
paw install               # Full setup: packages + symlinks
paw link                  # Symlinks only
paw sync                  # Pull repo + refresh links
paw update                # Update paw binary
paw status                # Show current state
paw doctor                # Health check
```

## Configuration

Paw stores its configuration in `~/.config/paw/config.json`:

```json
{
  "dotfilesRepo": "~/dotfiles",
  "repoUrl": "https://github.com/alexcatdad/dotfiles"
}
```

Dotfiles configuration remains in `dotfiles.config.ts` (TypeScript, loaded at runtime via bundled Bun).

## Bootstrap Flow

### New Machine Setup

**Option 1: Direct paw install**
```bash
curl -fsSL https://raw.githubusercontent.com/alexcatdad/paw/main/install.sh | bash
paw init https://github.com/alexcatdad/dotfiles
```

**Option 2: Via dotfiles repo (one-liner)**
```bash
curl -fsSL https://raw.githubusercontent.com/alexcatdad/dotfiles/main/install.sh | bash
```

The dotfiles `install.sh` becomes a thin wrapper:
```bash
#!/bin/bash
command -v paw &>/dev/null || curl -fsSL https://raw.githubusercontent.com/alexcatdad/paw/main/install.sh | bash
paw init https://github.com/alexcatdad/dotfiles
```

## Cross-Machine Sync Workflow

### MAC A (making changes)
```bash
# Edit config files...
paw push "update zsh aliases"
# Stages, commits, pushes
```

### MAC B (receiving changes)
On shell startup, `paw-sync-bg` runs and shows:
```
✓ Dotfiles synced (3 files updated)
```

If symlinks were refreshed:
```
✓ Dotfiles synced (3 files updated, symlinks refreshed)
```

## Migration Plan

### Phase 1: Create paw repo
1. Create `alexcatdad/paw` on GitHub
2. Copy: `src/`, `package.json`, `tsconfig.json`, release-please configs
3. Rewrite `install.sh` for paw-only installation
4. Set up CI/CD workflows
5. Push and verify release creates binaries

### Phase 2: Simplify dotfiles repo
1. Remove: `src/`, `package.json`, `tsconfig.json`, `bun.lockb`
2. Remove build-related CI workflows
3. Update `install.sh` to fetch paw first
4. Keep: `config/`, `dotfiles.config.ts`, docs

### Phase 3: Add new paw features
1. `paw init` command
2. `paw push` command
3. Update `paw-sync-bg` notifications
4. Config storage in `~/.config/paw/config.json`

## Future Enhancements

- **Multi-repo support** (Issue #18): Manage multiple dotfiles repos (work + personal)

## Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Config format | TypeScript | Enables hooks, full programming power |
| Runtime | Bun (bundled) | Required for TS config execution |
| Binary size | ~50MB | Acceptable trade-off for flexibility |
| Config location | `~/.config/paw/` | XDG-compliant |
| Single vs multi-repo | Single (for now) | Simpler, covers 90% of use cases |
