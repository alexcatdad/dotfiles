# Reviewed device activation and rollback

The portable lifecycle CLI implements the per-file workflow below. See `docs/LIFECYCLE.md` for profiles, custom paths, private journals, drift checks, recovery, and uninstall. This revision has not been activated on an existing device. The historical table describes the earlier baseline; `internal/deploy/inventory.go` is the expanded portable inventory. Native acceptance is tracked in `docs/ACCEPTANCE.md` and `docs/CHECKLIST.md`.

Status: the earlier authorized Mac rollout completed with eighteen selected destinations verified: initial application made 17 writes and one no-op; repeated application made zero writes. Its 18 live checks passed. The revised baseline removes Zen, Bun, and fnm from managed setup and Bun/fnm shell integration; the revised shell files have not been activated on the current Mac. Existing identical personal-ledger files were retained in their original skill directory. Private backup objects and the journal remain outside this checkout. Software checks do not establish visual appearance, account setup, or real connectivity.

Use explicit per-file copies. Repository edits must not silently change a running device through symlinks. Never copy `home/` recursively, replace a whole `.config` directory, or install the project-root `AGENTS.md` as global guidance. The tables below are the complete candidate file inventory; packages and test infrastructure are not home files.

## File destinations

`~` means the confirmed target user's home, not the controlling agent's home on another machine. All rows use copies, not links. Shared shell files apply to devices using the approved Zsh baseline; installing Go and jq on a device does not require adopting its shell configuration.

| Candidate source | Destination | Scope / acceptance |
| --- | --- | --- |
| `home/.zshenv` | `~/.zshenv` | Shared Zsh; inspect existing non-interactive behavior first |
| `home/.zprofile` | `~/.zprofile` | Shared Zsh login setup; macOS-specific code is guarded |
| `home/.zshrc` | `~/.zshrc` | Shared interactive Zsh; install dependencies before enabling |
| `home/.config/shell/path.zsh` | `~/.config/shell/path.zsh` | Shared existing-path selection |
| `home/.config/shell/aliases.zsh` | `~/.config/shell/aliases.zsh` | Approved shared aliases |
| `home/.config/shell/functions.zsh` | `~/.config/shell/functions.zsh` | Approved shared utilities |
| `home/.config/shell/plugins.zsh` | `~/.config/shell/plugins.zsh` | Explicit approved plugins; no startup installation |
| `home/.config/shell/alias-tips.zsh` | `~/.config/shell/alias-tips.zsh` | Native Zsh reminders; no Python |
| `home/.config/atuin/config.toml` | `~/.config/atuin/config.toml` | Shared preferences only; preserve existing private history/session state |
| `home/.config/ripgrep/config` | `~/.config/ripgrep/config` | Shared search defaults |
| `home/.config/starship.toml` | `~/.config/starship.toml` | Shared approved prompt appearance |
| `home/.config/ghostty/config` | `~/.config/ghostty/config` | Supported interactive desktops with Ghostty; native validation required |
| `home/.gitconfig` | `~/.gitconfig` | Shared Git behavior; preserve identity and private includes separately |
| `home/.config/git/ignore` | `~/.config/git/ignore` | Shared global ignore patterns |
| `home/.codex/AGENTS.md` | `~/.codex/AGENTS.md`, or confirmed custom Codex home | Device defaults; reconcile existing guidance and overriding file first |
| `home/.agents/skills/scratchpad-memory/SKILL.md` | `~/.agents/skills/scratchpad-memory/SKILL.md` | Reviewed personal skill snapshot; see source policy below |
| `home/.agents/skills/personal-ledger/SKILL.md` | `~/.agents/skills/personal-ledger/SKILL.md` | Reviewed personal skill snapshot; no ledger data or connection setup |
| `home/.agents/skills/personal-ledger/agents/openai.yaml` | `~/.agents/skills/personal-ledger/agents/openai.yaml` | Skill UI metadata |
| `home/.agents/skills/personal-ledger/references/statements.md` | `~/.agents/skills/personal-ledger/references/statements.md` | Required skill reference |
| `home/.agents/skills/personal-ledger/references/evidence.md` | `~/.agents/skills/personal-ledger/references/evidence.md` | Required skill reference |
| `machines/mac-studio.zsh` | `~/.config/shell/machine.zsh` | Optional explicitly selected machine integration; not selected by hostname |

Do not deploy the machine row to every device. Its OrbStack and LM Studio integrations are conditional, but still require deliberate acceptance. Other non-secret machine differences should receive separately reviewed plain files. Private `.zshenv.local`, `.zshrc.local`, and `.gitconfig.local` are preserved in place and never imported into public candidates. Do not read credential values to reconcile these files; request a safe, user-reviewed separation where necessary.

The skill rows describe current reviewed installation snapshots. `SKILL-SOURCES.md` pins the matching maintained Scratchpad source and records the public ledger skill-package gap. Keep the ledger snapshot until its maintained upstream package is prepared and reviewed. Before rollout, confirm the reviewed revision, complete reference set, and chosen installation location; avoid duplicate personal/plugin skills. Do not fetch a moving branch and call it the reviewed snapshot. Frontend and React skills remain project scoped. MCP configuration, endpoints, credentials, and account setup are separate private operations.

## Review before any write

1. Obtain authorization for the named target and exact file/package subset. Confirm user home, OS, architecture, installed package sources, shell, and Codex home. Do not infer these from another computer. Headless machines do not receive the desktop app set.
2. Inspect destination existence and symlink metadata without following symlinks into private files. Check every parent component: refuse symlinked parents until their destination and ownership are explicitly reviewed. A destination symlink must be treated as an object to replace and restore, never as permission to overwrite its target.
3. Classify each destination as absent, regular file, or symlink. Directories, special files, unknown ownership, unreadable files, and unresolved symlinks are conflicts requiring review. Existing global `AGENTS.md` and `AGENTS.override.md` need reconciliation; preserve accepted device-specific instructions. A custom Codex home changes the destination row explicitly.
4. For readable non-secret regular configurations, compare the candidate with the destination. Keep detailed differences private; do not print identities, private paths, environment values, histories, or credential-bearing content into project reports. If a file may contain secrets, do not use a raw diff: resolve it through a safely sanitized review.
5. Identify the last accepted deployment snapshot, if one exists. Compare current live files against that snapshot before replacing them. A changed live file is local drift, not permission to discard it. Review whether its useful changes belong in shared configuration, a machine file, or a private override.
6. Freeze the exact reviewed candidate files and their hashes for this rollout. Agree on conflict resolutions and rollback coverage before proceeding. No remote synchronization, scheduling, or service removal is implied.

Examples for the later authorized review, run from the reviewed candidate root:

```sh
dotfiles_root="$PWD"
dotfiles_src="$dotfiles_root/home/.config/shell/aliases.zsh"
dotfiles_dst="$HOME/.config/shell/aliases.zsh"

# Check parent components without inspecting file contents.
dotfiles_parent="$(dirname "$dotfiles_dst")"
while [ "$dotfiles_parent" != / ]; do
  if [ -L "$dotfiles_parent" ]; then
    printf '%s\n' 'Stop: a destination parent is a symlink.' >&2
    exit 1
  fi
  dotfiles_parent="$(dirname "$dotfiles_parent")"
done

# Only after confirming a readable, non-secret regular destination.
if [ ! -L "$dotfiles_dst" ] && [ -f "$dotfiles_dst" ]; then
  cmp -s "$dotfiles_src" "$dotfiles_dst"
  # Exit 0: identical; exit 1: different; exit >1: an error, not drift.
fi
```

These are review examples, not an unattended installer. A detected unsafe condition must end the operation; do not continue with later commands merely because the loop completed.

## Private backup and deployment journal

Create a private rollout directory outside the repository, with directory permissions `0700`, using a restrictive `umask`. Keep it on the target device or another explicitly authorized private backup location. It must never enter Git history or container build context. Existing configurations may contain private values even when the candidate does not.

For every selected destination, write a journal entry **before replacement** with: destination, candidate source/revision, prior kind (absent/file/symlink), backup location, prior file hash or symlink target recorded privately, intended deployed hash, and planned operation. Record newly created parent directories separately. Preserve original file permissions and original symlink objects; do not dereference links or back up their targets. After a successful replacement, record completion and observed deployed hash. A pending entry after interruption requires inspection, not an automatic second overwrite.

For a reviewed pre-existing regular file or symlink, the per-file backup operation is:

```sh
# dotfiles_backup is a unique filename in the already-created private rollout directory.
# Never reuse or overwrite an existing backup filename.
cp -Pp "$dotfiles_dst" "$dotfiles_backup"
```

An originally absent file has no backup; its journal entry must explicitly record absence. Never interpret a missing backup as proof that a destination was originally absent. Keep backup and journal until the device has passed acceptance and retention has been agreed.

## Explicit activation

Install only the selected missing dependencies during an authorized package step, using native manifests and the runbook's no-upgrade command. No cleanup, uninstall, account enrollment, license activation, or OS permission grants occur implicitly. jq and Go are required on every managed machine; optional shell features need their own listed tools/plugins. Review OS compatibility rather than applying the Mac Brewfile to Linux.

Copy dependency/configuration files before shell startup entrypoints; keep `.zshenv`, `.zprofile`, and `.zshrc` until last. Close the gap between review and write: recheck parent safety and compare the current destination with the journaled prior state immediately before replacement. If anything changed, stop that file and review the conflict. Do not overwrite concurrent edits.

If a regular destination already has identical bytes, leave it untouched and record a no-op. Do not change its timestamp or permissions simply to announce success. A symlink with identical target contents is still a symlink and needs an explicit conversion decision. Preserve intended executable/read permissions, and write configuration using a temporary regular file in the destination directory followed by a rename; this replaces a reviewed destination symlink itself rather than writing through it. Remove only the temporary file owned by this operation after a failure. Journal each completion before starting the next file; keep partial progress visible.

If the portable guidance needs merging with existing instructions, prepare and review that merged candidate first; its deployed hash is the merged file's hash. Do not silently claim the shared candidate was deployed unchanged. Inspect `AGENTS.override.md` precedence and verify the resulting instructions in a fresh agent session. Skill discovery also needs a fresh session, and installing a skill does not establish its service connection.

## Manual device acceptance

- Parse each selected Zsh file before executing it, then check fresh login and non-login shells for errors and approved PATH precedence. Confirm aliases, Zoxide `cd`, Ctrl-R Atuin search, direnv, completion, highlighting, suggestions, and alias reminders. Use synthetic commands; do not dump real history. Retain existing history databases and caches.
- Verify jq and Go are available. Check project runtime selection without downloading a project toolchain implicitly. Confirm the preserved prompt and Ghostty's black background/font visually; use the installed native Ghostty validator for a changed configuration. Command-R remains a separate terminal-specific check.
- On supported interactive Macs, confirm the selected desktop apps: ChatGPT, Wispr Flow, Proton Pass, Raycast, Ghostty/font, BetterDisplay, usb-boop, and Tailscale. Check actual Wispr/BetterDisplay behavior. Account sign-ins, purchased licenses, microphone/accessibility permissions, and browser profiles stay private and require deliberate local setup.
- Verify existing SSH/Tailscale access only for authorized targets without changing enrollment, authentication, firewall, or routing. Skip unreachable laptops; do not wake or repeatedly reconnect them. Container tests do not prove this connectivity.
- Confirm reconciled global guidance and selected personal skills are discovered; project-specific instructions remain project-specific. Verify MCP availability through discovered tools only when the relevant task is authorized. Do not access ledger records as a dotfiles health check.
- Record test results, files activated, device acceptance, unresolved checks, and publication status separately. No Paw service removal is part of file activation; inspect its consumers under separate authorization.

## Rollback and later synchronization

Rollback affects only journaled destinations owned by this rollout. Before each rollback, confirm the live destination is still the regular file with the recorded deployed bytes and expected permissions, and recheck parent paths. A changed file, replacement symlink, changed permissions, or other conflict requires review; never discard post-activation work automatically. Content equality alone does not prove ownership when metadata/state differs.

For an originally absent destination, remove only that unchanged deployed file. For an original regular file, restore the saved file and original permissions through a same-directory temporary file and rename. For an original symlink, remove only the unchanged deployed regular file and restore the saved symlink object with its original target; do not touch the target's contents. Check that backups exist and match the journal before acting. Restore only directories created by this rollout when empty; never remove pre-existing parent directories or unrelated contents. Verify each result and append the rollback outcome to the private journal. Package uninstall, service reversal, histories, and account state are outside file rollback.

Future maintenance uses the accepted deployment journal/snapshot as the comparison baseline. First compare live state against that baseline, then compare the new reviewed candidate against it. Unchanged live files may receive an explicitly authorized update; local drift requires review and reconciliation. No blind overwrite, bulk copy, or new sync daemon is required. Keep important shared decisions in Scratchpad, while per-device paths, backup locations, detailed diffs, and private state remain outside the public project.
