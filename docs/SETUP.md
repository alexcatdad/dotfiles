# Platform quick starts and manual setup

Confirm the target user, repository revision, filesystem layout, and existing configurations before writing. All `install`, `tools`, `plugins`, `packages`, rollback, and uninstall examples remain previews until `--apply` is supplied. Build with a supported local Go toolchain. See `ACTIVATION.md` for an existing managed-device rollout.

## Linux desktops and servers

```sh
GOTOOLCHAIN=local go build -o dotfiles ./cmd/dotfiles
./dotfiles packages --shells zsh,bash,fish
./dotfiles tools
./dotfiles plugins
./dotfiles plan --shells zsh,bash,fish --profile server
```

Use the native manager's reviewed privilege procedure for packages; do not run the configuration installer as root against a personal home. Resolve missing packages using `docs/PACKAGES.md`, then add `--apply` to the reviewed individual steps. Select `--components terminal --terminal ghostty` separately on a supported desktop. Shared paths and aliases work with native GNU tools; headless systems do not need GUI packages or fonts.

For a minimal shell, preview `--profile minimal --components shell,git,prompt,search`. Container and minimal profiles skip fnm, Zoxide, direnv, Atuin, and Zsh plugin initialization; optional tools remain available as explicit commands.

On NixOS, import `packages/nixos.nix` into the reviewed system configuration, or enter `nix-shell packages/shell.nix` using a trusted pinned nixpkgs. Preview the system change with the normal NixOS build/diff procedure before switching. Use the lifecycle tool for user files only when another manager does not already own them. Do not install a second Home Manager/symlink owner over the same paths.

## macOS

```sh
HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --no-upgrade --file=packages/Brewfile.cli
GOTOOLCHAIN=local go build -o dotfiles ./cmd/dotfiles
./dotfiles plan --shells zsh,bash,fish
```

Review taps first. Use the original `packages/Brewfile` only for the approved desktop app set. Existing Mac activation is historical evidence for the prior baseline; this revision needs its own per-file review. Apple Silicon, Intel, Linuxbrew, and a configured custom `HOMEBREW_PREFIX` have explicit path handling. A newer Homebrew Bash may be required by third-party integrations even though the base Bash files parse on 3.2.

## Windows and PowerShell

Build in PowerShell 7.4+ with `$env:GOTOOLCHAIN = 'local'`, then `go build -o dotfiles.exe ./cmd/dotfiles`. Pass `--shells powershell --powershell-profile $PROFILE.CurrentUserAllHosts` to plan/install. Preview `packages --shells powershell`; select a trusted installed manager through `$env:DOTFILES_PACKAGE_MANAGER` when necessary.

Use copy mode unless symlink privileges are deliberately configured. State ACL setup must succeed before backups are written. The installer never changes execution policy. If organization policy restricts profiles, use the allowed explicit dot-source procedure or keep shell settings uninstalled.

`--components terminal --terminal windows-terminal` creates a reference settings JSON under the selected config directory. Back up the actual Windows Terminal settings through its native UI, merge the reviewed defaults/scheme into the existing file, and verify profiles/key bindings. Its package-specific live settings path is not guessed or overwritten. For WezTerm, Kitty, Alacritty, and Ghostty, verify each application's native config discovery on that platform.

## WSL

Build and install inside the chosen Linux distribution, using its Linux home and package manager. Keep Linux state/history on the Linux filesystem. The native Windows profile is a separate deployment. Use `wsl --list --verbose` on the Windows host to record whether WSL 1 or 2 is being accepted.

Test fresh login/non-login shells, Linux-only PATH operation with Windows interop disabled, paths with spaces, terminal fonts, clipboard behavior, and the ability to return to the original shell. Set `DOTFILES_WSL_INTEROP=1` only when the `clip.exe` fallback is wanted. No Windows executable, systemd instance, GUI stack, or default distribution is assumed.

## BSD

Install Go, jq, Git, and the selected shells from the native package system. On FreeBSD, use `pkg`; on OpenBSD, use `pkg_add`; on NetBSD, use reviewed pkgsrc/pkgin sources. Check package and shell executable names before changing any startup files. Use canonical paths where `/home` or `/var` is a symlink.

Run `go test -v ./...` natively before applying a shell subset. Full managed-device support requires Go and jq; optional runtime/tool gaps remain real limitations, not permission to install a foreign Linux binary. The extended CI workflow supplies isolated FreeBSD/OpenBSD baseline probes. Other BSDs retain explicit native acceptance status.

## Android / Termux

Use Termux's native packages and private application filesystem, not shared Android storage. POSIX/Bash/Fish settings can be adopted independently. Record Android/Termux versions, architecture, native shell path, and executable policy. Go's Android ABI and the optional Android Bun asset require native validation; generic Linux glibc downloads are inappropriate.

Use manual configuration copies if the lifecycle binary is not supported by the device's toolchain. Do not root the device, alter SELinux policy, or grant storage permissions merely to install dotfiles. A useful partial shell setup is distinct from a complete managed-device baseline.

## Custom paths and shell selection

```sh
./dotfiles plan --home /confirmed/home \
  --config-dir /confirmed/config --data-dir /confirmed/data \
  --cache-dir /confirmed/cache --state-dir /confirmed/private-state \
  --zsh-dir /confirmed/ascii-zdotdir --shells zsh,bash
```

Use the same path choices for installation, status, update, and recovery. For a multibyte home with Zsh 5.9, export an ASCII `ZDOTDIR` in the launching terminal/session before Zsh starts; see the reproduced limitation in `COMPATIBILITY.md`.

Shell installation does not change the account default. Test with an explicit executable first. To change a default shell later, record the original, verify the new executable is allowed by the OS, use its supported account-settings command, and verify a fresh login. Restore through the same native interface if acceptance fails. On Windows Terminal, select a default profile independently of PowerShell profile installation.

## Manual installation and partial adoption

The source-to-destination map is explicit in `internal/deploy/inventory.go` and supplemented by `ACTIVATION.md`. Copy selected dependencies/config files before startup entrypoints. Use individual copies and private backups, not recursive copies of `home/` or `.config/`. Set the custom config/data directory variables in the selected startup files when copying without the renderer. Render Git's ignore path explicitly for a non-default config location and opt into the separate LFS include only when installed.

Private overrides are `~/.zshenv.local`, `~/.zshrc.local`, `~/.bashrc.local`, `~/.bash_profile.local`, `~/.profile.local`, `~/.gitconfig.local`, the selected config's `fish/local.fish`, and `powershell/local.ps1`. They are not installed from the repository. POSIX environment does not force itself into arbitrary non-interactive shells; source it explicitly when automation needs it. Bash non-interactive aliases are not assumed to expand.

Agent instructions and personal skills are independent optional components. Reconcile existing global defaults, overrides, and duplicate plugin/personal skills, preserve the reviewed source revisions, and verify discovery in a new agent session. Do not copy service connection configuration, credentials, or private records.
