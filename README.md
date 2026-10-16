# Portable plain dotfiles

Shared preferences with native Zsh, Bash, Fish, PowerShell, and POSIX entrypoints, explicit package setup, and a standard-library Go lifecycle tool. Configuration stays in plain files. Shell startup never installs, downloads, updates, or synchronizes software.

The established Mac deployment remains the historical baseline. This portability revision does **not** activate changes on any existing device. See [baseline evidence](docs/BASELINE.md), [compatibility and limitations](docs/COMPATIBILITY.md), and the [complete implementation/acceptance ledger](docs/CHECKLIST.md).

## Quick start

Install Go 1.23 or later through your platform's native distribution, then build from the reviewed checkout:

```sh
GOTOOLCHAIN=local go build -trimpath -o dotfiles ./cmd/dotfiles
./dotfiles packages                          # preview missing native packages
./dotfiles tools                             # preview pinned binary fallbacks
./dotfiles plugins                           # preview the three Zsh plugin sources
./dotfiles plan --shells zsh,bash,fish
./dotfiles doctor --shells zsh,bash,fish
```

Every write requires an explicit `--apply`. Package/tool setup and configuration deployment are separate operations:

```sh
./dotfiles packages --apply                  # native manager; may require privileges
./dotfiles tools --apply                     # missing pinned tools in ~/.local/bin
./dotfiles plugins --apply                   # reviewed plugins in XDG data/zsh/plugins
./dotfiles install --shells zsh,bash,fish --apply
./dotfiles status --shells zsh,bash,fish
```

An existing different file is a conflict. After reviewing its contents locally and the plan, add `--replace` to back up and adopt that file. That flag never overrides drift in an already managed file. Do not add it blindly to an existing agent-instruction or skill installation. A missing optional dependency leaves the basic shell usable; `doctor` explains missing or incompatible tools.

All examples assume a confirmed target user. `--home /absolute/path` selects a different configuration target, but does not select another user's package installation. No commands change the default shell, enroll accounts, configure credentials, or remove services.

## Components and profiles

The default components are `shell,git,prompt,history,search`. Select any subset with `--components`. Additional opt-in components are `terminal`, `agents`, `skills`, and `machine`.

- `--shells zsh,bash,fish,powershell,posix` selects native entrypoints. POSIX provides login environment only.
- `--profile server` retains the normal interactive tool integrations without desktop applications.
- `--profile desktop` uses the same shell baseline; select terminal configuration separately.
- `--profile minimal` and `--profile container` skip runtime-manager/history/plugin hooks and default to the smaller prompt.
- `--prompt full|minimal|ascii` selects prompt appearance. `NO_COLOR`, `TERM=dumb`, and `DOTFILES_ICONS=0` provide additional terminal controls.
- `--components terminal --terminal ghostty|kitty|alacritty|wezterm|windows-terminal` selects a terminal configuration. Windows Terminal is installed as a reference to merge into the real application settings; it never replaces an existing settings database automatically.
- `--components machine --machine machines/mac-studio.zsh` explicitly selects the existing optional Mac integration. No hostname-based selection occurs.
- `--git-lfs` adds the separate LFS filter configuration after its CLI is installed.

`--config-dir`, `--data-dir`, `--cache-dir`, `--state-dir`, `--zsh-dir`, and `--powershell-profile` support custom locations. XDG defaults are inherited only when targeting the invoking user's home. Generated startup files record the reviewed configuration paths; other shared files can optionally use `--mode symlink`. Rendered entrypoints always use copies. Symlink mode deliberately makes repository edits affect linked live files.

## Native Windows

Use PowerShell 7.4 or later and native Go:

```powershell
$env:GOTOOLCHAIN = 'local'
go build -trimpath -o dotfiles.exe ./cmd/dotfiles
.\dotfiles.exe packages --shells powershell
.\dotfiles.exe plan --shells powershell --powershell-profile $PROFILE.CurrentUserAllHosts
.\dotfiles.exe install --shells powershell --powershell-profile $PROFILE.CurrentUserAllHosts --apply
```

Pass the actual profile location, especially when Documents is redirected or OneDrive-managed. Native PowerShell keeps its object-producing `ls`/`dir` behavior and exposes `ll`, `la`, and `lt` for enhanced listings. Atuin 18.23 has a native PowerShell hook; PSReadLine provides native prediction. See [platform quick starts](docs/SETUP.md) for WSL, BSD, NixOS, Termux, and restricted/offline environments.

## Lifecycle and recovery

```sh
./dotfiles plan
./dotfiles install --apply
./dotfiles status
./dotfiles rollback                          # preview latest transaction
./dotfiles rollback --apply
./dotfiles uninstall                         # preview restoration of original files
./dotfiles uninstall --apply
```

The private deployment index and per-transaction journal live under `${XDG_STATE_HOME:-~/.local/state}/dotfiles` by default. Original files, original symlink objects, permissions, and ownership of created files/directories are tracked. Regular-file contents never appear in plans. Repeated installation makes no managed-file writes when bytes already match. Rollback and uninstall refuse local drift and validate backup hashes before restoration. Interrupted transactions block later writes until recovered.

Backups and journals are sensitive. POSIX state directories require private permissions; Windows state roots receive a protected current-user/SYSTEM DACL. Keep them outside the repository. Uninstall restores only managed files and removes only installer-created empty directories; packages, user history, accounts, and unrelated files remain separate. See [lifecycle details](docs/LIFECYCLE.md) and [device acceptance](ACTIVATION.md).

## Dependencies and updates

`jq` and Go remain the managed-device requirements. Bun and fnm stay outside the baseline; `--runtimes bun,fnm` explicitly enables their optional shell integration. Native package mapping covers Homebrew, APT, DNF, Pacman, Zypper, APK, BSD packages, Nix, Winget, Scoop, and Chocolatey. The existing desktop Brewfile remains available; `packages/Brewfile.cli` provides a CLI-only alternative. Nix consumers can use `packages/shell.nix` or import `packages/nixos.nix` deliberately.

Pinned fallback assets cover the available upstream OS/architecture/libc combinations for Bun, fnm, Starship, and Atuin. Unsupported combinations fail explicitly. Existing PATH tools are retained; an explicit `tools --upgrade --apply` replaces only regular binaries in the chosen prefix and retains their previous bytes in the archive cache. Native package managers can resolve dependency changes even when only missing packages are requested; review their transactions.

```sh
./dotfiles tools --download-only --apply     # prepare verified offline archives
./dotfiles plugins --download-only --apply
./dotfiles tools --offline --apply
./dotfiles plugins --offline --apply
```

Use [package mappings and prerequisites](docs/PACKAGES.md) and the [maintenance/release procedure](docs/MAINTENANCE.md). No update process runs at login.

## Verification

```sh
GOTOOLCHAIN=local go test -v ./...
GOTOOLCHAIN=local go vet ./...
sh scripts/cross-build.sh

docker build --platform linux/amd64 -f tests/container/Dockerfile -t dotfiles-validation:review .
docker run --rm --network none --cap-drop ALL --security-opt no-new-privileges dotfiles-validation:review
```

Use `linux/arm64` on ARM64. The 17-check current baseline plus a separate opt-in runtime check now select native architecture assets. New tests cover lifecycle failure/recovery, Unicode and quoted paths, custom XDG locations, permissions, symlinks, offline cache verification, and available native shells. `DOTFILES_REQUIRED_SHELLS` turns missing shell prerequisites into failures instead of skips.

CI covers native Linux/macOS/Windows on x86-64 and ARM64, representative Linux distro containers, minimum Go, and installer cross-compilation. PR CI and manual extended runs add FreeBSD/OpenBSD VM and native Ghostty validation. Cross-compilation does not prove runtime support. WSL, Termux, other BSDs, desktop visuals, physical keyboards, screen readers, and real account/connectivity behavior have explicit acceptance procedures and evidence status.

In managed environments with a custom CA, pass a combined system/proxy bundle as `--secret id=proxy_ca,src=/absolute/bundle.pem` to Docker builds. The networked release/plugin/toolchain steps use the temporary secret with TLS verification enabled. Never mount a real home, histories, credentials, or the Docker socket into test containers.

## Project and privacy boundaries

`home/` contains reviewed preferences, `machines/` explicit machine differences, `packages/` native setup sources, `cmd/` and `internal/` the lifecycle tool, and `tests/` synthetic checks. Never bulk-copy a home or `.config` directory.

`home/.codex/AGENTS.md` and `home/.agents/skills/` are optional reviewed snapshots, governed by [SKILL-SOURCES.md](SKILL-SOURCES.md). Installing them does not configure service connections. The project-root `AGENTS.md` is not global guidance. Existing guidance and overrides need deliberate reconciliation.

Review exact files in [PUBLIC-CONTENTS.md](PUBLIC-CONTENTS.md) before publication. Local overrides, histories, keys, environment databases, agent connections, deployment state, `work/`, `outputs/`, and compiled `dist/` artifacts stay outside public contents. Project memory is maintained in Scratchpad when connected; [RUNBOOK.md](RUNBOOK.md) locates the established records.
