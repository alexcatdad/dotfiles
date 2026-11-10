# dotfiles

Shell, Git and terminal configuration, the list of apps I install, and a script
that puts both on a machine. Plain files and symlinks; no configuration manager.

## A new Mac

1. Install [Homebrew](https://brew.sh). Its installer also installs the Xcode
   Command Line Tools, which is where `git` comes from.
2. Clone and run:

   ```sh
   git clone https://github.com/alexcatdad/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ./bootstrap.sh --machine mac-studio
   ```

3. Open a new terminal, then run the follow-ups `bootstrap.sh` prints:
   `gh auth login`, `mo touchid enable`, and optionally
   `sh scripts/macos-defaults.sh` and `mo slim`.

Clone to the internal disk. Configs are symlinks into the checkout, so a
checkout on an external drive leaves the shell unconfigured when the drive is
not mounted.

`bootstrap.sh` is safe to run again. It never deletes: anything it replaces is
moved to `~/.dotfiles-backup/<timestamp>/`.

## What is here

| Path | Purpose |
|---|---|
| `home/` | Configs, linked to the same path under `~` |
| `machines/` | Optional per-machine Zsh file, chosen with `--machine` |
| `Brewfile` | Formulae, casks and App Store apps |
| `bootstrap.sh` | Links configs, runs `brew bundle`, schedules the reminder |
| `scripts/link.sh` | The linking step alone; `--dry-run` shows drift |
| `scripts/macos-defaults.sh` | Optional software update preferences |
| `scripts/test.sh` | Lint and a link-and-startup test in a temp directory |
| `launchd/` | Daily "check for updates" notification |
| `skills.json` | Pinned agent skills, see `SKILL-SOURCES.md` |
| `.claude/skills/reconcile/` | Agent skill that folds manual changes back into the repo |

## Day to day

- **Edit a config:** edit it where it lives; it is a link into this repo.
  Commit when you like.
- **Machine-only settings:** `~/.zshrc.local`, `~/.zshenv.local`,
  `~/.gitconfig.local` (name, email, signing) and `Brewfile.local` are read if
  present and never committed.
- **Updates:** a notification reminds you once a day. Run `brew upgrade` and
  `mas upgrade` yourself; nothing upgrades in the background.
- **Installed or removed something by hand:** ask the agent to run the
  `reconcile` skill in this repo, or check yourself with
  `brew bundle cleanup --file Brewfile` and `brew bundle check --file Brewfile`.
- **Cleanup:** [Mole](https://mole.fit) directly (`mo clean`, `mo uninstall`).

## Linux

`scripts/link.sh` and the shell configs work on Linux. The `Brewfile` is for
macOS; use `./bootstrap.sh --no-packages`.

## Checks

```sh
sh scripts/test.sh
```

CI runs the same script on Linux and macOS, scans the history with `gitleaks`,
and confirms every `Brewfile` entry still exists. A pre-commit hook
(`.githooks/pre-commit`, enabled by `bootstrap.sh`) scans staged changes.
