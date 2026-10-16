# Maintenance, upgrades, releases, and troubleshooting

## Configuration changes

Keep shared preferences, platform adaptations, machine differences, and private state separate. Change the smallest relevant native file and run the corresponding parser before execution. Preserve the full Starship/Ghostty appearance unless a change is requested; new minimal profiles are opt-in alternatives. Add regression tests for meaningful behavior and lifecycle failure paths, not snapshots that merely repeat implementation text.

Run `go test -v ./...`, `go vet ./...`, shell parsers, and the relevant container/native checks. Inspect skipped prerequisites. Use `DOTFILES_REQUIRED_SHELLS` for acceptance environments so missing shells cannot appear as success. Cross-builds establish compilation only. Update the compatibility matrix when new execution evidence exists, with its platform, architecture, versions, commit, and limitations.

Record consequential rationale and reusable procedures in the confirmed Scratchpad `dotfiles` project when connected. `RUNBOOK.md` locates established records. If unavailable, report unsaved memory; do not substitute another service or edit mirrored JSONL manually.

## Dependency and plugin changes

Installation and upgrades remain separate. For native package upgrades, use the target OS's supported maintenance process under its own reviewed authorization. The `packages` command requests missing tools and never adds repositories or performs cleanup. Arch and declarative Nix systems need their normal system-level consistency procedures rather than an ad hoc partial upgrade.

For a pinned tool update:

1. Review the upstream release, supported OS/CPU/libc requirements, license, and changes to initialization flags.
2. Retrieve the named release's asset metadata and independent checksum/attestation where available. Do not use a `latest` download URL in code.
3. Download the selected official artifact with TLS verification, compute SHA-256 locally, and compare with the reviewed upstream digest. Record provenance in the PR.
4. Update only the corresponding explicit entries in `internal/deploy/assets.go`. Keep the exact archive member allowlist. Do not introduce an unverified architecture fallback.
5. Test extraction, offline cache rejection, native execution/version, shell initialization, and the full integration suite on affected architectures. Refresh version assertions deliberately.
6. Run `tools --download-only --apply` on an authorized setup target, then preview the explicit upgrade. `tools --upgrade --apply` retains previous binary bytes under the archive cache. Verify PATH selection in a fresh shell.

The three approved Zsh plugin commits and archive hashes are recorded in `internal/deploy/plugins.go`; the historical container installer records the same revisions. `plugins` only installs missing directories. To update an existing user-local plugin, review the new pinned revision, back up its current directory privately, move that exact reviewed directory aside, then invoke setup for the missing directory. Do not delete edits or compiled caches blindly. Native-packaged plugins should be updated through their package manager instead of being shadowed by an unreviewed source checkout. No `.git` dependency trees are copied into this repository.

Bundled personal skills follow `SKILL-SOURCES.md`, including its existing upstream-package gap. A portability change does not authorize refreshing those snapshots, replacing an account connection, or adopting a moving branch.

## Release procedure

1. Review the exact source diff, changed-file allowlist, licenses/notices for any newly vendored material, and synthetic examples. Do not stage the entire workspace.
2. Run native lifecycle tests, shell parsers, architecture integration, and the intended extended probes. Retain reports privately with their commit and version evidence.
3. Update `CHANGELOG.md`, the compatibility matrix, migration guidance, and the implementation/acceptance ledger. Explain remaining platform limits plainly.
4. Build release executables with `scripts/cross-build.sh` using an identified Go toolchain. Rebuild from the same source with `-trimpath` and compare hashes on a second controlled build when publishing reproducible artifacts.
5. Generate SHA-256 checksums for the exact release artifacts. Sign/attest through the repository's established approved release identity if one exists; never invent signing credentials.
6. Publish source through a reviewed PR. Tagging, uploading binary releases, signing, and merging remain explicit separate release actions. No new schedule or background updater is installed.
7. Roll out per device using `ACTIVATION.md` and its private deployment journal. CI green is not visual/account/device acceptance.

Review upstream/dependency changes deliberately during normal maintenance or before a rollout. Record the chosen review date and responsible maintainer; this repository does not silently create recurring automation.

## Configuration migrations

Treat the existing live Mac configuration as the historical deployment. New CLI deployments do not inherit ownership merely because files resemble the old baseline. Preview first, preserve original private backups/journals, and use backed-up adoption only for reviewed conflicts. Reconcile global agent instructions separately.

When changing components or paths, install the new selected files first under an explicitly reviewed plan. Omitted components are not automatically deleted. Use the prior deployment's index and a deliberate rollback/uninstall or manual per-file migration to retire old ownership. Never reuse the state directory of a different target user or move journals without reconciling their absolute destinations and backup references.

For a package manager or runtime-manager migration, preserve existing installations until PATH/runtime selection is accepted. Remove old packages only under a separate reviewed operation. Keep project-specific toolchains and dependencies with their projects.

## Troubleshooting

| Symptom | Check / action |
| --- | --- |
| CLI will not build | Confirm native `go version` is Go 1.23+; a command named `go` may be unrelated. Use `GOTOOLCHAIN=local`; do not let a build silently fetch a compiler. |
| Tool exists but shell feature is absent | Run `doctor`; check minimum version, shell hook support, terminal type, profile, and fresh PATH selection. Initializer failures intentionally fall back quietly. |
| `fd` missing on Debian | `fdfind` is supported directly by shell aliases; shell-free programs should use its native name. |
| Install reports conflict | Review existing content locally; use a private override or reviewed merge. `--replace` is for backed-up first adoption, not bypassing drift. |
| Update reports drift | Compare live non-secret configuration with its private accepted snapshot. Preserve useful edits before updating the candidate. |
| Interrupted transaction | Keep private state, stop the owned process, and run `rollback --apply`. Confirm the exact state/target paths. |
| Stale deployment lock | Verify no installer is running, inspect the private journal, then remove only the exact stale empty lock directory. |
| Parent path is rejected | Resolve symlinked/system-mapped paths and ownership explicitly. Do not bypass the check by copying through an unknown link. |
| Windows ACL or read-only error | Use a private ACL-capable state location; reconcile file attributes/policy. Do not weaken system permissions or execution policy automatically. |
| Zsh Unicode startup error | Use an ASCII `ZDOTDIR` exported before launch; see the reproduced Zsh 5.9 limitation. |
| Completion prompt/errors | Check plugin package location and `compaudit`; fix reviewed ownership/permissions. Do not disable completion security checks. |
| Boxes or wrong prompt glyphs | Install the selected font locally, use `--prompt ascii`, or disable icons. Test actual terminal rendering. |
| Broken clipboard/open command over SSH | No GUI provider is assumed. Use explicit file transfer/editor tools; opt into WSL interop only where wanted. |
| Atuin history seems different | Keep the existing private database/key/session in place; only preferences are deployed. Verify Ctrl-R separately from terminal-specific Command-R. |
| Node changes unexpectedly | Inspect fnm versus system/runtime-manager PATH precedence and project version files; never auto-install missing project versions at login. |
| direnv variable remains set | Check the supported shell hook and project trust/unload behavior; use a fresh shell to isolate user overrides. |
| Offline setup fails | Pre-stage the exact checksum-named archives; corrupt/missing cache entries fail instead of requesting the network. |
| Download/build returns proxy/TLS errors | Check configured proxy policy and trusted CA bundle. Preserve TLS verification and use the supported environment recovery path. |

Diagnostics and PR logs must not include real histories, tokens, identities, private endpoints, configuration contents, or credential-bearing environment dumps.
