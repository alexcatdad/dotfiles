# CLAUDE.md - Project Context

## Overview
`alexcatdad/dotfiles` holds only dotfiles content and `paw.toml` config.

## Quick Commands

```bash
paw install
paw link --force
paw status
paw sync
paw push "message"
paw doctor
```

## Structure

```text
dotfiles/
├── home/        # files mirrored to $HOME
├── templates/   # machine-specific templates
├── extras/      # optional reference files not auto-linked
├── paw.toml     # native config
└── install.sh
```

## Key Files

- `paw.toml`: packages, hooks, ignore paths, backup policy, template mapping
- `home/`: auto-linked by paw in hybrid mode
- `templates/*.template`: copied to local dotfiles if absent

## Local Files (gitignored)

- `~/.zshrc.local`
- `~/.zshenv.local`
- `~/.gitconfig.local`
- `~/.ssh/config.local`

## Validation

```bash
paw install --dry-run
paw status
paw doctor --verbose
```
