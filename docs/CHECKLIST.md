# Comprehensive portability implementation and acceptance ledger

This ledger retains the full scope of the requested universal-dotfiles checklist. `[x]` means the implementation, documented investigation, or reproducible procedure is supplied. It does **not** imply every platform has passed native acceptance. `[ ]` identifies execution or device evidence that cannot be replaced by code/documentation. Native CI results are authoritative only for the exact tested commit.

Upstream decisions are preserved: jq/Go remain required; Bun/fnm integration is opt-in, Zen is absent from managed packages, and Ghostty's current native titlebar preference is retained. No existing device has been activated by this work.

## Compatibility definition and investigation

- [x] Inventory every configuration file, dependency, integration, and platform assumption: explicit Go inventory, native sources, `COMPATIBILITY.md`, `PACKAGES.md`.
- [x] Publish a macOS/Linux/Windows/BSD compatibility matrix with partial and unsupported cases.
- [x] Cover Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE, Alpine, and NixOS setup paths.
- [x] Cover native Windows, WSL, containers, SSH, and development environments.
- [x] Assess FreeBSD, OpenBSD, NetBSD/DragonFly, Android/Termux, and distinct package/filesystem conventions.
- [x] Cover x86-64/ARM64 and assess 32-bit/ARMv7 through cross-builds and upstream asset availability.
- [x] Define Zsh, Bash, Fish, PowerShell, and POSIX support, including native feature differences.
- [x] Record minimum OS/tool/shell prerequisites and upstream ABI/CPU limitations.
- [x] Distinguish desktop, laptop, server, container, and restricted-user requirements through components/profiles.
- [x] Document unavoidable platform differences and supported alternatives without pretending full parity.

## Configuration layout

- [x] Separate shared preferences, platform adaptations, explicit machines, and private overrides.
- [x] Respect custom XDG config/data/cache/state locations where the tools support them.
- [x] Support ZDOTDIR and an explicitly selected native PowerShell profile path.
- [x] Avoid usernames, hostnames, fixed homes, fixed checkout locations, and guessed Windows application data locations.
- [x] Exercise spaces, quotes, and Unicode in target/config paths; document the reproduced Zsh 5.9 automatic-startup limitation.
- [x] Handle Windows path separators and case-insensitive destination collisions.
- [x] Define LF line endings and executable/configuration permission rules.
- [x] Prefer capability checks for tools, terminal features, clipboard, and open-file behavior.
- [x] Keep optional machine integrations explicitly selected instead of hostname-triggered.

## Dependencies and setup

- [x] Replace hardcoded ARM64 tool downloads with reviewed OS/architecture/libc asset selection.
- [x] Check SHA-256 for all selected release/plugin archives before use.
- [x] Distinguish glibc, musl, Android/Bionic, baseline CPU variants, and unsupported combinations.
- [x] Map Homebrew/APT/DNF/Pacman/Zypper/APK/Nix native package paths.
- [x] Map Winget/Scoop/Chocolatey and document platform repository gaps.
- [x] Map BSD packages and document pkgsrc/Termux-native alternatives.
- [x] Prefer suitable native packages and retain existing installations/sources.
- [x] Supply verified fallback assets and a reviewed-source-build procedure when no asset exists.
- [x] Support no-root binary/plugin installation in user-local directories.
- [x] Handle fd/fdfind and native executable names in shell-free automation.
- [x] Check versions explicitly and document feature-specific hook gaps through doctor/compatibility guidance.
- [x] Separate required dependencies, optional enhancements/runtimes, and GUI applications.
- [x] Separate installation, upgrades, and removal; avoid implicit repository/tap trust or cleanup.
- [x] Respect proxies/TLS trust, bounded retries, and managed-network policies.
- [x] Provide verified archive caching and strict offline setup.
- [x] Keep package, download, synchronization, and upgrade operations out of startup.

## Installation and recovery

- [x] Add an explicit installer with target/platform selection and actionable prerequisites.
- [x] Select shells, Git, prompt, history, search, terminals, instructions, skills, and machine integration independently.
- [x] Provide desktop/server/minimal/container profiles and explicit optional runtimes.
- [x] Preview filesystem and package changes before mutation.
- [x] Detect files, directories, symlinks, ownership, permissions, and conflicts.
- [x] Preserve private overrides and require reviewed merges for existing instructions/skills.
- [x] Back up replaced files/symlink objects in a private deployment manifest/journal.
- [x] Apply with same-directory temporary files and rename; preserve original POSIX permissions and Windows file DACLs for restoration.
- [x] Make repeated matching configuration deployment a managed-file no-op.
- [x] Reject local drift before updating managed files.
- [x] Journal and recover interrupted/partial writes, including interrupted rollback.
- [x] Support deliberate copy/symlink modes; keep rendered entrypoints copied.
- [x] Roll back or uninstall only owned changes and empty created directories.
- [x] Verify written results and report incomplete setup rather than claiming success.
- [x] Document individual manual copies independently of the installer.

## Shell adaptations

- [x] Identify native feature parity and differences for every supported shell.
- [x] Provide native Zsh/Bash/Fish/PowerShell files and a minimal POSIX login environment.
- [x] Preserve enhanced listings, search, Zoxide, Atuin, direnv, and explicitly selected runtimes where supported.
- [x] Supply native custom-function/alias-reminder equivalents with documented automatic versus callable behavior.
- [x] Separate quiet environment initialization from interactive hooks.
- [x] Supply tests for login/non-login and interactive/non-interactive startup.
- [x] Keep automation/SSH-style startup quiet and discard failed optional initializer output.
- [x] Discover plugins/completions in native package and user-local locations.
- [x] Load completion/widget-sensitive plugins in the required order.
- [x] Guard repeated initialization and preserve native shell hooks.
- [x] Provide usable missing-tool/minimal/TERM=dumb fallbacks.
- [x] Parse on Bash 3.2-compatible syntax and avoid loading newer completion packages into that shell.
- [x] Document explicit default-shell selection and reversal without changing it automatically.

## Commands and development tools

- [x] Audit utility behavior across GNU/BSD/BusyBox/PowerShell and supply numeric/native fallbacks.
- [x] Document aliases that intentionally differ from standard tools; preserve PowerShell object pipelines.
- [x] Use explicit native commands inside scripts/functions rather than interactive aliases.
- [x] Avoid shadowing existing executables for convenience CLI aliases.
- [x] Maintain existing-only, duplicate-free PATH entries and documented ordering.
- [x] Support Intel/Apple Silicon/Linuxbrew/custom Homebrew prefixes.
- [x] Keep Bun/fnm optional and document conflicts with system Node/other managers.
- [x] Avoid automatically downloading project runtimes/toolchains during initialization.
- [x] Respect supported user/language-tool paths without installing project toolchains.
- [x] Preserve direnv's trust boundary and environment-unload checks.
- [x] Provide platform clipboard/open helpers and respect native editor/pager/browser choices.
- [x] Keep SSH agents, credential helpers, signing, and Git identity in private native configuration.
- [x] Make Git LFS optional and check Git feature-version requirements.

## Terminals, desktop, remote, and accessibility

- [x] Split Ghostty shared settings from its macOS-specific preference file.
- [x] Supply native Ghostty validation procedure/job; preserve current appearance.
- [x] Add Kitty/Alacritty/WezTerm profiles and a mergeable Windows Terminal reference.
- [x] Document native font installation and missing-Nerd-Font alternatives.
- [x] Provide Unicode/full, minimal, ASCII/plain, no-icon, and no-color paths.
- [x] Respect TERM/NO_COLOR and native terminal capabilities without globally faking TERM.
- [x] Document native key/layout and Ctrl-R/Enter/Shift-Enter/Alt/Option/clipboard checks.
- [x] Provide Wayland/X11/macOS/Windows capability paths; keep notification preferences native.
- [x] Document tmux/screen/nested-shell/remote-session acceptance.
- [x] Document missing remote terminfo recovery through supported terminal procedures.
- [x] Make WSL Windows interop explicit and keep Linux-only operation usable.
- [x] Make desktop apps/terminal files/fonts optional on headless systems.
- [x] Provide accessibility/reduced-visual-detail options and native acceptance procedure.
- [ ] Verify visual appearance, physical keyboard/layout behavior, screen readers, and accessibility on actual supported devices.

## User state, privacy, and maintenance

- [x] Exclude histories, credentials, sessions, keys, caches, environment databases, and deployment state from publication/build context.
- [x] Deploy Atuin preferences without importing private history/key/session data.
- [x] Preserve history/account state across configuration installation, update, and rollback.
- [x] Document simultaneous-session behavior, secret-filter limitations, and synchronization choices.
- [x] Keep contents/arguments/private values out of plans and generic diagnostics.
- [x] Reject unsafe parents/ownership and document shared-filesystem/ACL requirements.
- [x] Make agent instructions/skills optional and preserve upstream snapshot/version decisions.
- [x] Reconcile existing guidance/overrides and duplicate skill providers through an explicit procedure.
- [x] Keep service availability/credentials separate from instruction installation.
- [x] Track exact archive/plugin revisions and dependency provenance.
- [x] Add doctor/status for missing tools, incompatible versions, pending transactions, and drift.
- [x] Document update/migration/release/recovery procedures without installing a scheduler or sync daemon.

## Verification coverage

- [x] Supply full Debian integration jobs for x86-64 and ARM64.
- [x] Supply native-package lifecycle/shell container probes for Debian/Ubuntu/Fedora/Arch/Alpine.
- [x] Supply native macOS Intel/Apple Silicon and Windows x86-64/ARM64 jobs.
- [x] Supply FreeBSD/OpenBSD VM probes, other BSD cross-builds, and WSL/NixOS/Termux native acceptance procedures.
- [x] Test available native shells; require intended prerequisites explicitly in acceptance jobs.
- [x] Test minimal/partial dependencies and successful/failed opt-in runtime initialization.
- [x] Test custom paths, Unicode/quotes, permissions, symlink parents/objects, and unsupported destinations.
- [x] Test preview, repeat installation, backed-up adoption, updates, rollback, uninstall, pending-write recovery, and corrupt backups.
- [x] Test lock conflicts and recheck destinations before mutation.
- [x] Test offline cache misses/corruption and unsupported asset combinations.
- [x] Preserve real-tool completion, highlighting, suggestions, aliases, prompt, direnv, runtime, and synthetic-history tests.
- [x] Preserve actual pseudo-terminal Ctrl-R testing in the full integration image.
- [x] Add a minimal-startup regression ceiling and native diagnostic procedures.
- [x] Parse native shell/Brewfile/PowerShell/JSON sources and supply native application validators where available.
- [x] Isolate test homes, histories, Git fixtures, and project environments from real user state.
- [x] Keep test results, configured CI, cross-build success, native acceptance, activation, and publication distinct.
- [x] Execute the hosted matrix, including real-tool Debian integration on both architectures; record commit-specific results in the PR. The final PR checks remain authoritative.
- [ ] Execute WSL/NixOS/Termux/remaining BSD/rare-architecture acceptance on native targets before promoting their support status.
- [ ] Verify full-stack read-only/shared-filesystem and restricted-policy cases on native targets before promising them.

## Documentation and delivery

- [x] Publish compatibility status and evidence mechanisms per platform combination.
- [x] Write platform/shell quick starts and manual/partial adoption instructions.
- [x] Document component destinations, prerequisites, overrides, and changed command behavior.
- [x] Provide PATH/font/completion/permission/history/runtime troubleshooting.
- [x] Document backups, rollback, uninstall, migration, and recovery.
- [x] Add a changelog, release procedure, support policy, and deliberate dependency-review cadence.
- [x] Keep examples synthetic and review public files explicitly.
- [ ] Run native account/SSH/Tailscale/physical-device acceptance only on separately authorized targets.
- [ ] Save consequential rationale/evidence in Scratchpad when the service is connected; unavailable in this session.
- [ ] Complete automated security review when the paying account has quota; the review service reports an account usage limit in this session.

The unchecked items remain visible release/acceptance conditions. They are not silently reclassified as completed implementation, and no historical Mac acceptance result is reused as evidence for this revision.
