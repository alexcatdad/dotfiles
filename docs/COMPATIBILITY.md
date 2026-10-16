# Compatibility and evidence

A configuration implementation, a successful cross-build, a native automated test, and acceptance on a real device are different results. This matrix describes the supplied paths and their verification mechanisms. Consult the PR's exact CI run for results; adding a job is not evidence that it passed.

| Environment | Configuration/setup path | Automated evidence supplied | Remaining acceptance |
| --- | --- | --- | --- |
| Linux glibc x86-64 / ARM64 | Native shells, package mapping, pinned tools | Native hosted jobs; full Debian integration on both architectures | Real SSH, desktop and account behavior |
| Debian / Ubuntu | APT; fd-find fallback | Debian 13 and Ubuntu 26.04 container probes | Older distro package versions |
| Fedora / RHEL family | DNF mapping | Fedora 44 probe | RHEL-family versions/repositories and SELinux policy |
| Arch | Pacman mapping | Current official Arch base probe | Rolling package drift on user systems |
| openSUSE | Zypper mapping | Manual native procedure; extend distro probe when available | Tumbleweed/Leap package names and native execution |
| Alpine / musl | APK; native packages and musl assets | Alpine 3.24 minimal-shell/lifecycle probe | Full tool stack; fnm has no reviewed musl binary |
| NixOS / Nix | Explicit Nix module and development shell | Installer cross-build; native acceptance procedure | Evaluate against the consuming pinned nixpkgs; avoid competing file ownership |
| macOS Apple Silicon / Intel | Homebrew CLI/desktop manifests | Native jobs for both runner architectures; PR/extended Ghostty validation | GUI appearance, permissions, physical keyboards, accounts |
| Windows x86-64 / ARM64 | Native Go + PowerShell; Winget/Scoop/Chocolatey | Native runner jobs; protected state ACL and lifecycle tests | Redirected Documents, terminal UI, package availability |
| WSL 1 / 2 | Linux path, optional explicit Windows clipboard interop | Linux-native tests cover configuration primitives | Actual WSL startup, filesystem permissions, interop, terminal |
| FreeBSD | Native pkg; Bash/Zsh/Fish | PR/extended hosted VM test; installer cross-build | Full optional tool stack and desktop |
| OpenBSD | Native pkg_add; shell fallbacks | PR/extended hosted VM test; installer cross-build | Missing Atuin and optional runtime packages; interactive baseline is partial |
| NetBSD / DragonFly | Manual native packages and shell subset | NetBSD installer cross-build | Native lifecycle/shell checks and missing dependency alternatives |
| Android / Termux | Native packages; POSIX/Bash/Fish subset; Android Bun asset | No native execution claimed | Bionic ABI, device shell paths, executable policy, storage permissions |
| Containers / SSH / restricted users | Minimal/server profile; user-local paths | Disconnected non-root synthetic container checks | Host policy and actual connectivity |
| Linux 32-bit / ARMv7 | Installer cross-build; native package subset | Cross-build only | Runtime/tool availability; full Bun baseline may be impossible |

Do not translate this matrix into a blanket claim that every tool exists on every platform. Missing upstream distributions are explicit compatibility limits. Basic configuration can still be used as a subset; `doctor` reports when the complete managed-device requirements are unmet.

## Shell behavior

| Feature | Zsh | Bash | Fish | PowerShell | POSIX |
| --- | --- | --- | --- | --- | --- |
| Quiet environment setup | Yes | Yes | Yes | Yes | Login environment |
| Listing/search/navigation | Aliases + Zoxide | Aliases + Zoxide | Native functions + Zoxide | Native object listings; enhanced views + Zoxide | Native tools |
| History search | Atuin Ctrl-R | Atuin Ctrl-R | Atuin Ctrl-R | Atuin Ctrl-R + PSReadLine | Shell-provided |
| Runtime switching | fnm hook | fnm hook | fnm hook | fnm hook | Explicit commands |
| Project environment | direnv hook | direnv hook | direnv hook | Supported direnv pwsh hook; explicit refresh helper | Explicit `direnv exec` |
| Suggestions/highlighting | Reviewed plugins | Readline/completion; optional reviewed ble.sh through `DOTFILES_BASH_BLE=1` | Native | PSReadLine | Shell-provided |
| Alias reminders | Automatic native hook | Atuin preexec hook when available; callable helper otherwise | Native abbreviations and listing reminder | Callable `Show-DotfilesAliasTip` plus native prediction | None |
| Prompt | Starship or plain fallback | Starship or plain fallback | Starship or plain fallback | Starship or native fallback | Native |

Bash/Fish/PowerShell are native adaptations, not syntax translations of Zsh plugins. Zsh widget plugins are never sourced into another shell. Native Bash 3.2 remains a minimal configuration target; use a newer Bash if third-party integrations require it. An incompatible optional initializer is ignored quietly; use `doctor` for diagnostics.

## Minimum versions and features

| Tool | Minimum for this configuration | Why |
| --- | --- | --- |
| Go | 1.23 | Standard-library lifecycle CLI; local toolchain only |
| jq | 1.6 | Managed-device JSON tools |
| Bun | 1.4.2 pinned, optional | Integration runner and explicitly selected runtime |
| Git | 2.37 | Existing merge conflict style and push defaults |
| Git LFS | 3.0, opt-in | Separate filter component |
| Zsh | 5.8 | Modern completion/widget baseline |
| Bash | 3.2 for base files | Avoid associative arrays and newer syntax in shared config |
| Fish | 3.6 | Native path, abbreviation, and integration support |
| PowerShell | 7.4 | Native cross-platform profile and current PSReadLine |
| eza | 0.20 | Existing icons/listing flags |
| ripgrep / fd | 13 / 8 | Search baseline; fdfind accepted |
| zoxide | 0.9 | Native shell hooks |
| fnm | 1.39.0 pinned, optional | Explicitly selected project-switching integration |
| Atuin | 18.23.0 pinned | Current bindings/AI flags and native PowerShell integration |
| Starship | 1.26.0 pinned | Preserved prompt configuration |
| direnv | 2.32 for Unix hooks | PowerShell hook availability varies by package revision |

Optional initializers are evaluated only after successful execution. Unsupported flags therefore leave the basic shell usable instead of evaluating partial output. Native package versions below the table need review; do not silently upgrade them at login.

## Known platform details

- **Zsh 5.9 and multibyte startup filenames:** locally reproduced `funcstack`/glob errors when Zsh automatically loads startup files from a path containing Japanese characters. Use an ASCII `--zsh-dir` and export `ZDOTDIR` before launching Zsh. Explicitly sourced Unicode config paths and Unicode homes are exercised separately. An ASCII-home bootstrap alone does not fix an already problematic automatic startup path. Recheck with newer Zsh versions before removing this workaround.
- **macOS aliases and system tools:** utilities use explicit native commands. `duf` requires the native sort's human-size support for its formatted variant; use the numeric-KiB Bash/PowerShell equivalents where unavailable.
- **Windows:** installer file changes preserve original DACLs and protect deployment backups. Symlinks require Developer Mode or appropriate privileges; copy mode is the default. Existing read-only files, unsupported reparse objects, network shares without suitable ACLs, and policy-restricted profiles must be reconciled explicitly. PowerShell execution policy is never changed.
- **BSD/macOS real paths:** system paths such as `/var` or `/home` may be symlinks. Confirm their canonical destinations before passing target/state paths; the installer rejects symlinked parents rather than writing through them.
- **WSL:** Linux configuration belongs in the Linux home. Do not deploy Linux histories/state onto `/mnt/c` unless its metadata/permissions behavior is understood. Windows executable interop is optional; `DOTFILES_WSL_INTEROP=1` explicitly enables `clip.exe` as a clipboard fallback.
- **SSH/terminfo:** install the client's terminfo using the terminal's supported procedure or select a compatible terminal type before connecting. These dotfiles never rewrite `TERM` globally or enroll an SSH/Tailscale account.
- **Fonts/accessibility:** the full prompt and terminal profiles use Nerd Font glyphs. Select the ASCII/plain prompt, disable icons, and use native terminal accessibility settings for screen readers or reduced visual detail. A software test cannot establish assistive-technology usability.
