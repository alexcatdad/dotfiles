# Changelog

## Unreleased — portability and lifecycle

- Add explicit preview/install/status/rollback/uninstall tooling with private backups, drift checks, interrupted-transaction recovery, and native Windows ACL preservation.
- Add native Bash, Fish, PowerShell, and POSIX entrypoints alongside Zsh; support custom configuration locations and minimal/headless profiles.
- Generalize pinned tool downloads across available OS/architecture/libc combinations and add verified offline/user-local setup.
- Add optional terminal profiles, split Ghostty platform preferences, and make Git LFS an explicit component.
- Add native package mappings, CLI-only Homebrew and Nix sources, compatibility/acceptance documentation, and expanded CI.
- Preserve the historical Mac baseline as evidence; no existing device is implicitly activated or upgraded.
