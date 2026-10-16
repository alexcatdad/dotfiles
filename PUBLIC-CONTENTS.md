# Exact public source inventory

This revision contains 92 explicitly listed source files. Review is scoped to the portability/lifecycle PR requested by the user. Existing published source and upstream decisions are preserved; no live configurations, deployment backups, histories, credentials, account connections, or generated binaries are included.

The inventory below is an allowlist, not permission to publish arbitrary future files under a directory. Source text and obvious secret-pattern/symlink checks supplement review; they do not prove absence of all private material. The historical publication/deployment record is retained in `docs/BASELINE.md`.

## Files

- `.dockerignore`
- `.gitattributes`
- `.github/workflows/ci.yml`
- `.gitignore`
- `ACTIVATION.md`
- `AGENTS.md`
- `CHANGELOG.md`
- `PUBLIC-CONTENTS.md`
- `README.md`
- `RUNBOOK.md`
- `SKILL-SOURCES.md`
- `cmd/dotfiles/main.go`
- `decisions.jsonl`
- `docs/ACCEPTANCE.md`
- `docs/BASELINE.md`
- `docs/CHECKLIST.md`
- `docs/COMPATIBILITY.md`
- `docs/LIFECYCLE.md`
- `docs/MAINTENANCE.md`
- `docs/PACKAGES.md`
- `docs/SETUP.md`
- `examples/.gitconfig.local.example`
- `examples/.zshenv.local.example`
- `examples/.zshrc.local.example`
- `go.mod`
- `home/.agents/skills/personal-ledger/SKILL.md`
- `home/.agents/skills/personal-ledger/agents/openai.yaml`
- `home/.agents/skills/personal-ledger/references/evidence.md`
- `home/.agents/skills/personal-ledger/references/statements.md`
- `home/.agents/skills/scratchpad-memory/SKILL.md`
- `home/.bash_profile`
- `home/.bashrc`
- `home/.codex/AGENTS.md`
- `home/.config/alacritty/alacritty.toml`
- `home/.config/atuin/config.toml`
- `home/.config/fish/conf.d/dotfiles.fish`
- `home/.config/ghostty/config`
- `home/.config/ghostty/platforms/macos.conf`
- `home/.config/git/ignore`
- `home/.config/git/lfs.gitconfig`
- `home/.config/kitty/kitty.conf`
- `home/.config/powershell/profile.ps1`
- `home/.config/ripgrep/config`
- `home/.config/shell/alias-tips.zsh`
- `home/.config/shell/aliases.zsh`
- `home/.config/shell/capabilities.sh`
- `home/.config/shell/env.sh`
- `home/.config/shell/functions.zsh`
- `home/.config/shell/interactive.bash`
- `home/.config/shell/path.zsh`
- `home/.config/shell/plugins.zsh`
- `home/.config/starship.toml`
- `home/.config/starship/ascii.toml`
- `home/.config/starship/minimal.toml`
- `home/.config/wezterm/wezterm.lua`
- `home/.config/windows-terminal/settings.json`
- `home/.gitconfig`
- `home/.profile`
- `home/.zprofile`
- `home/.zshenv`
- `home/.zshrc`
- `internal/deploy/assets.go`
- `internal/deploy/doctor.go`
- `internal/deploy/files.go`
- `internal/deploy/inventory.go`
- `internal/deploy/lifecycle.go`
- `internal/deploy/lifecycle_test.go`
- `internal/deploy/options.go`
- `internal/deploy/plugins.go`
- `internal/deploy/privacy_other.go`
- `internal/deploy/privacy_windows.go`
- `internal/deploy/privacy_windows_test.go`
- `internal/deploy/runtimes_test.go`
- `internal/deploy/shells_test.go`
- `internal/deploy/tools.go`
- `internal/deploy/tools_test.go`
- `machines/mac-studio.zsh`
- `packages/Brewfile`
- `packages/Brewfile.cli`
- `packages/Brewfile.runtimes`
- `packages/nixos.nix`
- `packages/shell.nix`
- `scripts/cross-build.sh`
- `scripts/install-tools.ps1`
- `scripts/install-tools.sh`
- `tests/container/Dockerfile`
- `tests/container/history-pty.go`
- `tests/container/install-plugins.sh`
- `tests/container/install-tools.sh`
- `tests/container/verify.ts`
- `tests/distros/Dockerfile`
- `tests/portable/bsd.sh`

## Exclusions and provenance

`work/`, `outputs/`, `dist/`, `.git/`, private overrides, shell/application histories, Atuin keys/sessions/databases, credential files, environment databases, private agent connections, installed plugin trees, download caches, and private deployment journals remain excluded. Never stage the entire workspace or bulk-copy a home/configuration directory.

New files contain native configuration, standard-library Go lifecycle/tool setup, synthetic tests, native package sources, and documentation. Official release/plugin URLs and digests are public provenance. Plugins are installed outside this repository, retaining their upstream contents/notices. Optional personal instruction/skill snapshots retain the latest upstream versions and source policy. No new account enrollment, scheduler, service deployment, or live device activation is part of this PR.

Before publication, regenerate the excluded `outputs/portability-files.sha256` snapshot from this exact inventory and check the final diff. CI logs, test evidence, device acceptance, publication, and deployment are distinct results. Screenshots/runtime prompts can reveal identity or host context and need a separate review.
