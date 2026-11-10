# Repo instructions

This repository is public. It holds configs (`home/`), an app list (`Brewfile`)
and the scripts that apply them. `home/.codex/AGENTS.md` is the separate
device-wide instruction file; do not treat this file as global guidance.

## Keep it public-safe

- Never commit secrets, private keys, hostnames, addresses, network names,
  account identifiers, or anything about customers or employers.
- Machine-only and sensitive settings go in untracked `*.local` files.
- Read every added line before committing. `gitleaks` only catches
  token-shaped strings.

## Keep it plain

- Files, symlinks and POSIX `sh`. No configuration manager, no custom tooling,
  no background job that changes the machine.
- Nothing downloads, installs or updates during shell startup.
- Scripts never delete: move replaced files to a backup.
- Preserve Starship, Ghostty, Zsh alias, Zoxide, Atuin and direnv behaviour
  unless the owner asks for a change.

## Before committing

- `sh scripts/test.sh` passes.
- Installing, removing or upgrading packages, running `bootstrap.sh` or
  `scripts/link.sh` against the real home, and pushing all need the owner's
  go-ahead.
