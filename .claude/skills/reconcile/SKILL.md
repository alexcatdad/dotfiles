---
name: reconcile
description: Bring manual changes made on this machine back into the dotfiles repo. Use when the owner asks to reconcile, sync or check drift between the machine and the repo - apps installed or removed by hand, configs edited in place, links an app replaced with a real file.
---

# Reconcile the machine with the repo

Compare what is on this machine with what the repo declares, show the
differences, and let the owner decide each one. Run from the repo root.

## Rules

- Read first, change second. Nothing is installed, removed, re-linked or
  committed until the owner has chosen for that item.
- Never run `brew bundle cleanup --force`, `brew upgrade` or `mas upgrade`.
- This repo is public. Machine-only or sensitive settings belong in untracked
  `*.local` files (`~/.zshrc.local`, `~/.gitconfig.local`, `Brewfile.local`),
  never in tracked files.

## 1. Packages

```sh
brew bundle check --file Brewfile --verbose   # declared but not installed
brew bundle cleanup --file Brewfile           # installed but not declared (lists only)
mas list                                      # App Store apps, compare with mas lines
```

If `Brewfile.local` exists, an entry declared there is not drift.

For each difference offer three choices:

- **Adopt:** add it to `Brewfile` (or `Brewfile.local` if it should stay
  private). Keep the file's order: taps, formulae, casks, App Store apps, each
  alphabetical, with the one-line description comment `brew bundle dump` writes.
- **Revert:** change the machine to match (`brew install` / `brew uninstall`).
- **Ignore:** leave both as they are and say so in the summary.

Dependencies pulled in by another formula are not drift; `brew leaves` shows
what was asked for directly.

## 2. Configs

Linked files are edited in place, so most config changes are already
uncommitted changes in the repo:

```sh
git status --short
git diff
sh scripts/link.sh --dry-run        # paths that are no longer links to the repo
```

- **Edited in place:** show the diff and ask whether to keep it.
- **Link replaced by a real file** (an app rewrote its config): diff the real
  file against the repo copy. To adopt, copy the content into `home/…`, then
  run `sh scripts/link.sh` to restore the link; the replaced file goes to
  `~/.dotfiles-backup/`.
- **New config worth tracking:** list entries in `~/.config` that the repo
  does not carry and ask which, if any, to add under `home/.config/`. Skip
  caches, state, history and anything holding credentials.

## 3. Finish

1. `gitleaks dir . --redact --no-banner` and read every added line for
   hostnames, addresses, account names and customer detail. A token scanner
   does not catch those.
2. Show the final `git diff --staged` and a short summary: adopted, reverted,
   ignored.
3. Commit only when the owner approves. Push only when asked.
