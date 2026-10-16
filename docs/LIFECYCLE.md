# Configuration lifecycle

Build `cmd/dotfiles` with a local Go 1.23+ toolchain. The inventory in `internal/deploy/inventory.go` is finite and explicit; there is no configuration DSL or background synchronizer. Commands default to a read-only preview. Package and tool operations have their own lifecycle and do not run during configuration updates.

## Review and installation

1. Confirm the target OS, architecture, user home, actual shell startup locations, XDG directories, and repository revision. Use `ACTIVATION.md` to reconcile an existing managed device.
2. Choose `--components`, `--shells`, `--profile`, prompt, and any terminal/machine profile explicitly. Desktop apps and global agent instructions are opt-in.
3. Run `plan` with the same options that will be passed to `install`. Plans list paths and actions, never original contents. A different pre-existing file or symlink is a conflict without `--replace`.
4. Review conflicts locally without exposing credentials or real histories. For agent instructions/skills, produce the reviewed merge separately before adoption; do not replace a non-empty override blindly.
5. Install only the missing dependencies using `packages`, `tools`, or the documented native paths. Review native manager transactions and required privileges. Existing tools are not automatically upgraded.
6. Run `install` with the reviewed options and `--apply`. `--replace` permits backed-up first adoption, but never bypasses subsequent local drift.
7. Run `status`, `doctor`, and the relevant device acceptance procedure. Verify actual font and keyboard behavior separately.

Generated Zsh/Bash/POSIX/Fish/PowerShell entrypoints record config/data paths and profile. Git's ignore path and optional LFS include are rendered for the selected config directory. Shared file sources remain reviewable text. The installer does not store user identity in the repository.

## Safety and state

Default state is `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles`. With an explicit `--home`, defaults derive from that home instead of borrowing the controlling user's XDG directories. Pass exactly the same `--state-dir` for later operations. State must remain outside the repository.

On POSIX systems, the state root requires current-user ownership and mode 0700; state files/backups use 0600. Windows applies a protected current-user/SYSTEM DACL to the state root and records original file DACLs for restoration. Restore Windows backups on a filesystem with suitable ACL support. State contains private original file contents and paths and should never be published.

`index.json` records owned destinations, original file/symlink fingerprints, original backup references, current deployed fingerprints, created directories, and the latest transaction. Each `transactions/<id>/journal.json` records its before/after index, per-file backup, intended transition, and progress. `pending.json` identifies an interrupted transaction. A lock directory prevents concurrent installer processes.

All regular originals are backed up before the first live write. Each destination is rechecked before replacement. Candidates use same-directory temporary files and rename, replacing a destination symlink object rather than following it. Unknown ownership, symlinked parents, non-file destinations, insecure parents, corrupt state, and local drift cause errors. Supported sticky temporary directories and user-namespace system roots are recognized.

The installer is for a user's own reviewed configuration, not a privilege boundary against an adversary concurrently replacing directory trees. Do not run it through `sudo` against another user's files. It does not inspect real SSH configuration, credential stores, history databases, or unrelated application state.

## Recovery

If an operation fails after a journal is created, keep the state directory intact. Later writes refuse to proceed while a transaction is pending. Inspect the private journal, stop any surviving owned installer process, and run:

```sh
./dotfiles rollback --home /confirmed/home --state-dir /confirmed/private/state --apply
```

Rollback verifies all current destinations and backup hashes before starting restoration. It accepts completed or interrupted writes matching the recorded before/after states, and refuses unrelated edits. Recovery itself is marked pending and can be resumed after interruption. Never fabricate a missing backup or delete the index to bypass drift.

A stale `lock` directory requires manual inspection: confirm no installer is running before removing that exact empty lock directory. Do not recursively clear the state directory. Preserve journals/backups until device acceptance and retention are agreed.

## Updates, rollback, and uninstall

A repeated installation with identical bytes is a no-op, including timestamps and permissions. An identical file that existed before adoption remains unowned and will not be deleted on uninstall. An update compares against the last deployed fingerprint; useful local edits must be reconciled deliberately into a candidate or private override.

`rollback --apply` reverses the most recent transaction. Repeated rollback walks earlier transactions. `uninstall --apply` restores the pre-adoption original state of all owned files, including across multiple updates, and removes only installer-created empty directories. Uninstall is itself reversible through rollback. Private backups remain available afterward.

Configurations in symlink mode reflect source edits immediately; symlink identity is tracked without reading arbitrary original targets. Rendered startup/Git entrypoints remain copies. Prefer copy mode when reproducibility, source-branch isolation, or source relocation matters.

Package removal, default-shell reversal, accounts, histories, terminal databases, service changes, and credential enrollment require their own explicit procedures. No configuration rollback runs cleanup or uninstall commands against native packages.
