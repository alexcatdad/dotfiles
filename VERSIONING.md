# Versioning & Breaking Changes

This project follows [Semantic Versioning](https://semver.org/) (SemVer):

```
MAJOR.MINOR.PATCH
  │     │     └── Bug fixes, no breaking changes
  │     └──────── New features, backwards compatible
  └────────────── Breaking changes
```

## Version Guarantees

### Within a MAJOR version (e.g., 1.x.x → 1.y.y)

**Safe to upgrade without `--upgrade` flag:**

| Component | Guarantee |
|-----------|-----------|
| CLI commands | Names and basic behavior preserved |
| Config format | `dotfiles.config.ts` schema unchanged |
| Symlink paths | Existing symlink targets unchanged |
| Template files | `.local` files not overwritten |

**May change:**
- New optional config fields
- New CLI commands or flags
- Additional symlinks (won't conflict)
- Improved error messages

### MAJOR version upgrades (e.g., 1.x → 2.x)

**Requires `--upgrade` flag.** May include:

- Renamed or removed commands
- Changed config schema (with migration guide)
- New required dependencies
- Changed symlink paths
- Removed deprecated features

## Upgrade Process

### Minor/Patch Updates (automatic)

```bash
# Just run the install script - it handles everything
curl -fsSL https://raw.githubusercontent.com/alexcatdad/dotfiles/main/install.sh | bash
```

### Major Updates (requires confirmation)

```bash
# Check what's new first
curl -fsSL ... | bash -s -- --version

# Review changelog
open https://github.com/alexcatdad/dotfiles/releases

# Accept breaking changes
curl -fsSL ... | bash -s -- --upgrade
```

## Migration Guides

When a major version is released, migration guides will be published:

- In the [GitHub Release notes](https://github.com/alexcatdad/dotfiles/releases)
- In `docs/migrations/v1-to-v2.md` (when applicable)

## Deprecation Policy

Features are deprecated before removal:

1. **Deprecation notice**: Feature marked deprecated in release notes
2. **Warning period**: At least 1 minor version with console warnings
3. **Removal**: Feature removed in next major version

## Config Compatibility

### Current Schema (v1.x)

```typescript
interface DotfilesConfig {
  symlinks: Record<string, string>;      // source → target
  packages: {
    common: string[];
    darwin?: string[];
    linux?: string[];
  };
  templates: Record<string, string>;     // template → target
  hooks?: {
    preInstall?: (ctx) => Promise<void>;
    postInstall?: (ctx) => Promise<void>;
    preLink?: (ctx) => Promise<void>;
    postLink?: (ctx) => Promise<void>;
  };
}
```

### Backwards Compatibility Promises

1. **Symlinks**: Once a symlink path is in a release, it won't be renamed without a major version bump
2. **Templates**: `.local` files are never overwritten by `paw install`
3. **Backups**: Backup format (`*.backup.<timestamp>`) is stable
4. **Hooks**: Hook API signature won't change within major version

## Contributing

When making changes:

1. **Adding features**: Add to MINOR version, ensure backwards compatibility
2. **Fixing bugs**: Add to PATCH version
3. **Breaking changes**: Document in PR, requires MAJOR version bump
4. **Deprecations**: Add console warning, document timeline

### Checklist for Breaking Changes

- [ ] Document in PR description
- [ ] Update VERSIONING.md with migration guide
- [ ] Add to release notes
- [ ] Consider if migration can be automated in `install.sh`
- [ ] Update version number in `src/index.ts`

## Version History

| Version | Date | Notes |
|---------|------|-------|
| 1.0.0 | 2024-01 | Initial release with SSH migration, doctor command |

## Questions?

Open an issue: https://github.com/alexcatdad/dotfiles/issues
