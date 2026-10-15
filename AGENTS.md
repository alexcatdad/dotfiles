# Dotfiles project instructions

## Scope and sources

This file governs work in this project. `home/.codex/AGENTS.md` is the separate, portable device-wide instruction file; do not install this project-specific file as global guidance.

- Use `README.md` for baseline scope and reproducible checks; retrieve relevant project context and runbooks from Scratchpad when changing that baseline. `RUNBOOK.md` locates the central records. Keep future targets and changes within their own task authorization.
- Shared candidate files live in `home/`, optional machine integrations in `machines/`, native package manifests in `packages/`, and isolated checks in `tests/container/`.
- Agents may parallelize independent work. Give each agent clear ownership, integrate its findings, and close it when done. Avoid conflicting edits.
- Keep project memory and operational runbooks in Scratchpad; confirm project scope on every call. Capture consequential rationale and reusable procedures with accurate authority, confidence, and evidence. Report unsaved records if the service is unavailable.

## Baseline and privacy

- Apply KISS: preserve the approved baseline and choose the smallest correct change. Store multi-step procedures in Scratchpad with prerequisites, scope, verification, and rollback.
- Use `ACTIVATION.md` before a device rollout and `PUBLIC-CONTENTS.md` before publication review. Keep installation separate from upgrades; use the documented no-upgrade setup command. Follow `SKILL-SOURCES.md` for reviewed source revisions rather than silently refreshing skill snapshots.
- Use plain files, native package managers, and explicit commands. Do not introduce Paw, Ansible, a plugin manager, a sync daemon, or a custom configuration parser.
- Do not use Python for agent-authored scripts, automation, data processing, or validation commands. Use shell, Bun/TypeScript, or Go instead. Python use requires an explicit user exception. Existing Python-dependent tools are not authorization to use Python for new work; flag their dependencies and preserve approved behavior when planning a replacement.
- `jq` and Go are required on every managed machine. Preserve approved aliases, Zoxide navigation, Atuin search, direnv, shell plugin features, and appearance. Bun, fnm, and Zen are no longer part of the managed baseline; Bun remains a container test-runner dependency.
- Keep shared configuration separate from non-secret machine differences and private/generated state. Never bulk-copy a home or `.config` directory.
- Do not read, print, copy, or publish credentials, private keys, real histories, environment databases, or private project configuration. Use synthetic fixtures for tests.
- No download, install, synchronization, or update command belongs in shell startup. Native shell caches/history may be written during normal interactive use.
- Do not initialize, stage, commit, configure a remote, push, or create a GitHub repository until the user authorizes the exact reviewed public contents. Treat existing `.git` metadata as unreviewed.
- Local preparation and disposable container tests are authorized. Host installation, live file relinking, service removal, remote changes, and scheduling require separate task authorization.
- Container checks never mount the host home or Docker socket. Run tests disconnected, non-root, without capabilities, and remove test containers after exit.
- Linux validation does not establish macOS GUI behavior or real connectivity. Report test success, activation, publication, and machine acceptance separately.
- Later fleet maintenance may use SSH over existing Tailscale, skip unreachable machines, and keep private values outside the public project. Do not schedule it now or redesign homelab backups.

## Validation and delivery

- For shell, plugin, or package changes, follow the Docker build/run commands in `README.md` and the relevant Scratchpad runbook. Do not rerun the container suite for documentation-only edits.
- Parse changed Zsh files before executing them. Use synthetic fixtures for behavior tests and validate the native Brewfile syntax separately.
- Preserve Starship and Ghostty appearance unless the user requests a change. Validate Ghostty with the installed native validator when its configuration changes.
- Review the exact public file allowlist in `README.md`; never stage the entire workspace. `work/` and `outputs/` are local artifacts, and existing `.git` history remains unreviewed.
- Report changed files, verified behavior, unresolved device-specific checks, and whether anything was activated or published. Keep hostnames, addresses, identity, and secrets out of public reports and logs.
