# Historical baseline before the portability revision

This is the upstream baseline captured at commit `1d2f092e5d07241926518dadc29b656a1be8dae9`. Its deployment claims concern earlier revisions, not acceptance of this PR. The current entrypoint is the repository-root README.

# Plain dotfiles baseline

Status: the original reviewed 39-file baseline was published at [alexcatdad/dotfiles](https://github.com/alexcatdad/dotfiles) and activated on the current Mac. Its 18 live checks passed; repeated activation made zero writes. The revised baseline removes Zen, Bun, and fnm from managed setup and Bun/fnm shell integration; those shell changes have not been activated on the current Mac. Private backups and the deployment journal remain outside the repository. Other devices have not been activated. The current public inventory contains 40 files after adding the CI workflow; see `PUBLIC-CONTENTS.md`.

This setup preserves the approved shell shortcuts and appearance using plain Zsh files, native package manifests, and explicit machine differences. No Paw, Zinit, Ansible, startup downloads, or synchronization daemon is required.

## Contents

- `home/`: shared candidate files, including the preserved Starship and Ghostty preferences.
- `machines/mac-studio.zsh`: optional Mac Studio integration. It is not automatically selected by hostname and is not installed in the Linux test image.
- `packages/Brewfile`: the approved Mac package baseline. `jq` and Go are required on every managed device. Use native packages where available.
- `tests/container/`: an isolated ARM64 Debian setup and integration checks. Debian native packages provide the Linux baseline; official pinned binary releases provide tools absent from Debian's package set.
- `RUNBOOK.md`: locator for operational runbooks in Scratchpad. Scratchpad holds project memory and procedures; `decisions.jsonl` retains historical evidence.
- `ACTIVATION.md`: per-file destinations, conflict review, repeatable activation, rollback, and device acceptance.
- `PUBLIC-CONTENTS.md`: exact candidate publication inventory and its privacy review boundary.
- `SKILL-SOURCES.md`: verified public upstream references and revision status for personal skills.
- `examples/`: synthetic private-override templates; they are not installed automatically.
- `AGENTS.md`: instructions for maintaining this dotfiles project.
- `home/.codex/AGENTS.md`: reusable device-wide working agreements, intended for each user's Codex home (normally `~/.codex/AGENTS.md`).
- `home/.agents/skills/`: selected reusable personal skills and their required references. These are candidate instructions, not MCP connections or installations.

## Agent instruction placement

The project file governs this project. The portable file supplies defaults across projects on each device; do not substitute the project file for it. If a device uses a custom Codex home, place the portable file there instead. An existing non-empty `AGENTS.override.md` takes precedence at that level; inspect and reconcile it rather than deleting or overwriting it blindly. Project instructions are loaded after global instructions and can specialize them.

The portable file is installed on the current Mac after reconciliation with existing global guidance. For each later rollout, review existing instructions, preserve device-specific rules, and merge the portable defaults deliberately. On devices without Codex, a remote maintenance agent can read the file explicitly; installing Codex is not required solely for this workflow.

The 2026-10-06 agent-focused revision is installed on the current Mac. It defines KISS, unattended implementation, and recurring monitoring of PR checks and human/tool feedback until merge or closure, alongside current service roles and language preferences. Green is a readiness report; monitoring continues and merging still requires an explicit request. Operational runbooks and rationale are in Scratchpad, located through `RUNBOOK.md`. Device-specific requirements remain in this project's documents and manifests. The installed file matches the source, no global override masks it, and its original is privately backed up. Codex's refreshed instruction context confirms the new global guidance is loaded.

Source: [official instruction discovery documentation](https://learn.chatgpt.com/docs/agent-configuration/agents-md).

## Portable personal skills

The device-wide instructions identify Scratchpad for project memory and runbooks, and pa-mcp for personal-assistant state: attention, tasks/reminders, bills, pet care, travel, finances, and buying intents. Codex handles conversation and scheduled execution; pa-mcp provides typed domain operations. Available tool schemas determine connected capabilities; installing instructions does not authorize access to personal data.

Scratchpad stores consequential decisions, ADRs, findings, failures, constraints, questions/answers, project state, and runbooks. Use its typed capture and retrieval tools with provenance, authority, and confidence. Optional repository mirroring is managed by Scratchpad. Codex discovers the packaged skills; the installed agent instructions do not duplicate their loading or workflow rules. The personal-ledger snapshot below covers the financial subset of pa-mcp.

| Skill | Purpose | Candidate source and review |
| --- | --- | --- |
| `scratchpad-memory` | Recover and preserve project reasoning, decisions, and evidence | Existing personal skill; includes public Scratchpad integration links |
| `personal-ledger` | Use pa-mcp for requested financial records, reconciliation, reports, and evidence | Existing personal skill plus statement/evidence references and UI metadata; no records or connection configuration |

The copied instructions are unchanged local snapshots. `SKILL-SOURCES.md` records the matching pinned Scratchpad source and the unresolved public ledger skill package. No upstream version upgrade is implied. Frontend design and React/Next.js skills belong in each relevant project rather than the device-wide baseline. Homelab operations and workspace-connectivity skills depend on specific infrastructure and are not part of this shared set. System and plugin skills remain managed by their providers rather than vendored from plugin caches. Before rollout, reconcile equivalent plugin skills and existing personal copies to avoid duplicates.

The intended user-level destination is `~/.agents/skills/`, as documented in [official skill discovery guidance](https://learn.chatgpt.com/docs/build-skills). Deployment and private MCP connection setup are separate tasks. There are no server addresses, key paths, credentials, ledger data, or Scratchpad records in this bundle.

## Preserved behavior

The `ls`, `ll`, `la`, `lt`, `tree`, `grep`, and `find` aliases remain. Zoxide provides `cd`; Atuin provides Ctrl-R search; Direnv handles project environments. Autosuggestions, fast syntax highlighting, completion, and alias tips load explicitly. The only custom utility functions are `duf` and `suggest-aliases`.

`.zshenv` provides `woodpecker` → `woodpecker-cli`, `scaleway` → `scw`, `proton-pass` → `pass-cli`, and `opentofu` → `tofu` in interactive and non-interactive Zsh. Each alias requires the target CLI and leaves an existing executable with the alias name untouched. These are shell aliases; shell-free process launches use the native executable names. No optional CLI is installed by this configuration.

These aliases are active on the current Mac. The isolated 18-check baseline, synthetic argument/exit-status and name-conflict checks, native macOS startup-mode checks, and real CLI version calls passed. `.zshenv` was applied with its original privately backed up and the change journaled; the later agent-instruction rollout verified it unchanged and made no additional shell writes.

Atuin is configured for local history without automatic cloud synchronization, update checks, daemon setup, or AI bindings. Existing account/history data is never copied. Ctrl-R is the shell binding; Command-R is terminal-specific and has not been assumed equivalent.

Alias reminders are implemented in plain Zsh at `home/.config/shell/alias-tips.zsh`; they inspect normal shell aliases without executing their expansions or echoing command arguments. The candidate does not require Python. Homebrew provides autosuggestions, fast syntax highlighting, and completions on macOS. Docker pins the same inspected upstream plugin commits so retained behavior can be verified independently of Zinit.

## Public/private boundary

Use this allowlist for future publication review: `.github/workflows/ci.yml`, `home/`, `machines/`, `packages/`, `tests/`, `examples/`, `README.md`, `AGENTS.md`, `RUNBOOK.md`, `ACTIVATION.md`, `PUBLIC-CONTENTS.md`, `SKILL-SOURCES.md`, `.gitignore`, `.dockerignore`, and a reviewed `decisions.jsonl`. Review the exact individual files listed in `PUBLIC-CONTENTS.md`, not just these directory names. Reports and scratch files are excluded. Inherited unreviewed Git metadata was archived privately; the public repository starts with fresh reviewed history.

Do not copy host credential files, SSH keys/configuration, authorized keys, known hosts, Atuin keys/session/database, shell histories, environment databases, application caches, hardware identities, or project secrets. `.gitconfig.local`, `.zshenv.local`, and `.zshrc.local` remain private. Secret filtering in history is a convenience, not a guarantee that commands are secret-free.

## Reproduce the container checks

From this project directory, using the existing Docker daemon:

```sh
docker build --platform linux/arm64 -f tests/container/Dockerfile -t dotfiles-validation:review .
docker run --rm --network none --cap-drop ALL --security-opt no-new-privileges dotfiles-validation:review
```

The build context is allowlisted. No host home, SSH data, private environment, Git metadata, Docker socket, or live dotfiles are mounted into the container. A non-root disposable user runs the checks. Tests create only synthetic history, environment files, and fixture Git repositories inside the container. The named image and build cache remain for reproduction; test containers are removed on exit.

Bun is retained only as a container test-runner dependency, not a managed shell/runtime requirement. The integration runner uses Bun and a standard-library Go helper for the real pseudo-terminal history search check. Tests also verify that Python is absent. The official binary/plugin archives are version/commit pinned and checksum-verified. The base image is digest pinned. Debian package versions are recorded from the test image but use Debian's current signed repositories rather than a frozen snapshot.

## Continuous integration

`.github/workflows/ci.yml` runs on pull requests, pushes to `main`, and manual dispatch. The ARM64 Linux job runs the Docker commands above, including all 17 isolated integration checks. The macOS job parses shared and machine Zsh files and validates the Brewfile with Ruby and Homebrew without installing packages.

The workflow uses a commit-pinned checkout with read-only repository permission and no persisted credentials. New runs cancel older runs for the same pull request or branch. CI does not activate dotfiles, validate GUI appearance, or establish real connectivity.

## Setup later

### Native macOS rehearsal

The earlier baseline (before removal of Bun, fnm, and Zen) in a disposable headless macOS 26.6.2 guest passed 18 native checks, including actual Ctrl-R history search, Bun completion loading, fnm project switching, Go offline compilation, direnv, and native Ghostty validation. The full Brewfile installed after reviewing and trusting its two third-party package entries under Homebrew 7. A repeated package setup required no new installs; repeated file activation made zero writes. All 20 shared files rolled back to independently verified original states. Synthetic checks also exercised interrupted writes, local drift rejection, and symlink preservation.

This was a prepared Cirrus Labs base image with preinstalled developer/CI tools, not factory Setup Assistant. It does not establish sign-in, license activation, physical USB/display behavior, OS permissions, visual appearance, fresh Codex skill discovery, or real Tailscale enrollment. The preserved Scratchpad runbook, located through `RUNBOOK.md`, contains the native rehearsal and package-trust/completion-permission steps. No host baseline activation or publication occurred. The disposable VM and its image cache were removed; local evidence remains excluded in `outputs/`.

### Approved desktop apps

The Mac Brewfile includes ChatGPT, Wispr Flow, Proton Pass, Raycast, Ghostty and the current font, BetterDisplay, usb-boop from `alexcatdad/tap`, and Tailscale. This is the accepted interactive Mac baseline; other reviewed apps remain optional, development-specific, or hardware-specific.

At an authorized Mac rollout, use `brew bundle --no-upgrade --file=packages/Brewfile` after reviewing existing packages and compatibility. Do not use cleanup or uninstall commands. The current usb-boop cask requires Apple Silicon and macOS 14 or later; check the installed package metadata again at rollout. Other operating systems use their own supported app distribution paths rather than this Mac manifest. GUI apps are not required on the homelab.

Package installation is separate from sign-in, license activation, OS permissions and verifying app behavior. Those are device-local acceptance steps. No license keys, account sessions, or browser profiles belong in the repository. Nothing is installed or activated during candidate preparation.

On macOS, the Brewfile is a native Homebrew manifest and includes Go. Go uses the native `golang-go` package in the Debian validation image; other devices use their native Go package or an explicitly installed official distribution. Runtime requirements are device-wide; project-specific Go versions and dependencies remain with each project. On Linux, use the native packages demonstrated in the Dockerfile; Starship and Atuin are explicitly installed during setup where native packages are absent. The Dockerfile is test infrastructure, not a fleet deployment manager.

Alias reminders ship with the shared shell files and need no separate installation. On machines without native packages for autosuggestions, highlighting, or completions, the pinned archives in `tests/container/install-plugins.sh` can use the documented `~/.local/share/zsh/plugins/` paths. Do not copy dependency `.git` directories into the dotfiles project.

`ACTIVATION.md` maps every managed file and defines explicit copies, private backups, drift checks, repeatable no-ops, rollback, and acceptance. Later activation requires review and authorization of the exact target and file subset. Do not use a bulk copy or Homebrew cleanup command. Paw Proxy consumers must be inspected before any service change. Native startup and synthetic history search passed on the current Mac; terminal appearance, existing history continuity, and remote SSH/Tailscale access remain separate acceptance checks.
