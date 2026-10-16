# Native acceptance record

Use synthetic commands, a disposable user/home where possible, and reviewed per-file activation. Record OS/version, architecture, shell/tool versions, terminal, commit, profile/components, test date, and result privately. Public reports should omit identities, machine addresses, histories, and detailed private paths.

## Automated gates

- Parse all selected native shell files before execution. Parse PowerShell with its native AST parser and JSON using a native JSON parser. Validate Brewfile syntax separately without installing packages.
- Run the lifecycle suite, including preview/no-write, repeat/no-op, first-adoption conflicts, changed permissions, symlink preservation, corrupt backups, interrupted writes, locks, rollback, uninstall, and local drift.
- Exercise Unicode/quoted paths and custom XDG configuration. Record the known Zsh startup-filename workaround rather than concealing a skipped combination.
- Run full real-tool Debian integration on both x86-64 and ARM64, disconnected and non-root. Verify aliases, completion, Zoxide, direnv isolation, Bun/fnm switching, prompt rendering, synthetic Atuin history, real PTY Ctrl-R, SSH CLI, jq, and offline Go compilation.
- Run available native shell tests on each OS and representative distro. Require intended shell prerequisites through `DOTFILES_REQUIRED_SHELLS`; inspect every skip.
- Run extended BSD/Ghostty probes when accepting those paths. Cross-build output alone is insufficient.

## Interactive desktop and assistive technology

- Open fresh login and non-login sessions in the actual terminal, then an SSH/tmux/screen session where used. Confirm quiet startup, prompt redraw, resizing, Unicode, and correct executable priority.
- Test Ctrl-R, normal Up-arrow, completion, suggestions, highlighting, alias reminders, Shift-Enter, Alt/Option, keyboard layout, clipboard, open-file helpers, and notification preferences.
- Verify the full font, black background, theme, contrast, focus, key mappings, split behavior, and fallback prompt. Validate Ghostty with its installed native validator before checking its appearance.
- Test `NO_COLOR`, `TERM=dumb`, `DOTFILES_ICONS=0`, minimal/ASCII prompts, terminal reduced-motion settings, and the user's actual screen reader. Preserve native accessibility behavior and record shortcomings.
- On Linux, test the actual Wayland or X11 clipboard provider. On Windows, test actual PowerShell/PSReadLine, redirected Documents, native terminal profiles, and ACL-backed rollback. On macOS, test native permission prompts and physical input/display behavior separately.

## Platform-specific probes

- **WSL:** record WSL 1/2 and distro; test with Windows interop enabled and disabled, Linux home permissions, no `/mnt/c` assumption, and clipboard opt-in.
- **NixOS:** evaluate the module/shell against the consuming pinned nixpkgs, build the system change before switching, and ensure another file manager does not own the same destinations.
- **Termux:** verify Bionic-native tools and executable locations on the actual device; test private storage versus shared storage and shell startup. Record unsupported required runtimes honestly.
- **Other BSDs/architectures:** run native Go/lifecycle and shell checks, verify native command flags, locales, package names, and tool availability. Do not execute an unrelated ABI's binary.
- **Restricted/offline systems:** verify user-local installation without privilege changes; stage archives on an authorized connected machine, disconnect, install from cache, and reject missing/corrupt artifacts.

## State and deployment acceptance

Preserve original shell and Atuin histories, private includes, signing/credential settings, and account state. Confirm Git local identity and any chosen signing helper privately without copying them into the repository. Test existing SSH/Tailscale access only to explicitly authorized targets; do not change enrollment, routing, firewalls, or authentication as a dotfiles check.

After installation, run status/doctor, repeat installation and confirm zero file writes, then exercise rollback on a disposable deployment and verify original contents/metadata. Confirm omitted components and unrelated files remain intact. For optional agent instructions/skills, reconcile overrides/duplicate providers and verify discovery in a fresh agent session; do not access personal service records as a health check.

Accept software behavior, visual/accessibility behavior, account setup, real connectivity, and physical-device behavior separately. Sign-ins, licenses, default-browser changes, and OS permission grants are not supplied by this repository. Keep the private deployment journal and backups until acceptance and retention are agreed.
