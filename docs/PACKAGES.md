# Native packages and verified fallbacks

Package installation is explicit and separate from configuration activation. `dotfiles packages` selects a native manager and prints missing-package commands. `--apply` executes those commands without adding repositories, trusting new taps, elevating privileges, cleaning packages, or upgrading the existing baseline. Managers may resolve dependencies; review their own transaction preview. Use `DOTFILES_PACKAGE_MANAGER` to select a supported installed manager deliberately when several exist.

## Native mapping

| Family / manager | Managed core | Interactive additions | Gaps / notes |
| --- | --- | --- | --- |
| Debian/Ubuntu / APT | git, git-lfs, jq, golang-go | zsh, bash, fish, eza, ripgrep, fd-find, zoxide, direnv | Current release packages differ from older LTS; pinned tools fill gaps |
| Fedora/RHEL / DNF | git, git-lfs, jq, golang | zsh, bash, fish, eza, ripgrep, fd-find, zoxide, direnv | EPEL/third-party repository setup remains explicit |
| Arch / Pacman | git, git-lfs, jq, go | zsh, bash, fish, eza, ripgrep, fd, zoxide, direnv, atuin, starship | Do not perform partial-system upgrades; use the distro's normal maintenance procedure |
| openSUSE / Zypper | git, git-lfs, jq, go | zsh, bash, fish, eza, ripgrep, fd, zoxide, direnv | Verify Leap versus Tumbleweed availability |
| Alpine / APK | git, git-lfs, jq, go | zsh, bash, fish, eza, ripgrep, fd, zoxide, direnv | Select musl assets; no reviewed fnm musl release |
| Homebrew | git, git-lfs, jq, go; optional runtime Brewfile | CLI Brewfile includes tools, shells, completions, and Zsh plugins | Review/trust taps separately; desktop casks remain opt-in |
| FreeBSD / pkg | git, git-lfs, jq, go | zsh, bash, fish, eza, ripgrep, fd, zoxide, direnv | Ports/binary availability differs by release and architecture |
| OpenBSD / pkg_add | git, git-lfs where available, jq, go | zsh, bash, fish, ripgrep, fd, direnv | Bun/fnm/Atuin/full baseline unavailable unless separately supported upstream |
| NetBSD / pkgin or pkgsrc | Native git, jq, Go and shell packages | Check the current pkgsrc tree | Manual procedure; not auto-detected as FreeBSD pkg |
| Termux / pkg | git, jq, golang | bash, zsh, fish, ripgrep, fd, direnv where available | Android/Bionic packages must come from Termux; do not install generic glibc binaries |
| Nix / NixOS | Explicit module/development shell | Native package set in `packages/` | Pin nixpkgs in the consuming system; use declarative changes deliberately |
| Windows / Winget | Git.Git, GitHub.GitLFS, jqlang.jq, GoLang.Go; optional Oven-sh.Bun | Microsoft.PowerShell, eza-community.eza, BurntSushi.ripgrep.MSVC, sharkdp.fd, ajeetdsouza.zoxide, Schniz.fnm, Starship.Starship | Native Atuin fallback provided; direnv package/source availability needs review |
| Windows / Scoop | git, git-lfs, jq, go; optional bun | pwsh, eza, ripgrep, fd, zoxide, fnm, starship | Buckets and trust decisions remain explicit |
| Windows / Chocolatey | git, git-lfs, jq, golang | powershell-core, ripgrep, fd, zoxide, starship | Other tools use verified upstream/native alternatives |

The CLI reports unmapped dependencies rather than claiming setup is complete. An installed executable is retained even when old; `doctor` checks minimum versions. Bash completion and native Zsh plugin packages can be installed separately with the package manager or the CLI Brewfile. The fixed `plugins` setup command supplies user-local Zsh fallbacks.

On Debian, aliases accept either `fd` or `fdfind`; a global compatibility symlink is unnecessary. Shell-free automation should call the executable name actually installed. This also applies to the convenience CLI aliases documented in the baseline.

## Pinned binary fallback

`internal/deploy/assets.go` records exact upstream URLs, SHA-256 digests, archive members, OS, architecture, and libc. The checked-in pins match the established optional Bun 1.4.2/fnm 1.39.0 and baseline Starship 1.26.0/Atuin 18.23.0 versions. GitHub release metadata supplied the additional architecture digests; downloaded bytes are verified again before extraction.

```sh
./dotfiles tools --tools bun,fnm,starship,atuin              # preview
./dotfiles tools --tools bun,fnm,starship,atuin --apply
./dotfiles tools --tools bun,starship --libc musl --apply   # appropriate native musl host only
```

The default executable prefix is `~/.local/bin`. Existing tools in the prefix or PATH are retained. No archive is unpacked wholesale: only its exact reviewed regular executable member is read, with size limits. Unsupported OS/architecture/libc combinations fail before installation. Baseline x86-64 Bun artifacts avoid requiring AVX2; other upstream CPU/OS minimums still apply. Review upstream release requirements on older CPUs or operating systems.

Foreign assets can be prepared with `--target-os`, `--target-arch`, and `--libc`, but may only be written as archives with `--download-only`. Installation refuses a foreign target. Android artifacts are not interchangeable with glibc or musl.

## Offline, proxies, certificates, restricted users

```sh
./dotfiles tools --download-only --apply
./dotfiles plugins --download-only --apply
./dotfiles tools --offline --apply
./dotfiles plugins --offline --apply
```

Copy only the reviewed checksum-named archive cache into an offline target's chosen cache directory. `--offline` never requests the network and fails when an archive is absent or corrupt. A tool upgrade is a separate `tools --upgrade --apply` action; previous binary bytes remain in the cache for deliberate recovery. Tool/package removal is never part of configuration uninstall.

The Go HTTP client respects standard HTTP(S) proxy settings, TLS verification, system trust, and Go's `SSL_CERT_FILE`/`SSL_CERT_DIR` support on Unix. Supply a combined trusted bundle where the platform requires one. Bounded downloads retry transient failures and retain verified cached archives. Do not bypass organizational proxy or certificate policy.

No-root environments can use the user-local binary/plugin prefixes, native user-level Nix/Scoop where permitted, or approved prebuilt tools. A missing Go compiler needs a platform-supported bootstrap before building this repository; these scripts do not download an unverified compiler. If Go/jq cannot run on a platform, select a useful configuration subset and report that the complete managed-device baseline is unmet.

## Desktop apps and fonts

The established Mac desktop Brewfile is unchanged. Other systems use their supported distributions for Ghostty, Kitty, Alacritty, WezTerm, Windows Terminal, native browsers, Tailscale, and password managers. Mac-only applications such as BetterDisplay and usb-boop have no automatic Linux/Windows substitute. Do not install arbitrary lookalikes to claim parity.

FiraCode Nerd Font Mono is the appearance baseline. Install it through a supported native font package/cask or the reviewed upstream release; use terminal-native font management on Windows. The minimal/ASCII prompt and `DOTFILES_ICONS=0` support systems without that font. Accounts, licenses, default-browser changes, accessibility permissions, device access, and real connectivity remain device-local acceptance steps.
