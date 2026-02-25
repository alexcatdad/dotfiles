# 🐱 alexcatdad/dotfiles

Personal dotfiles managed by [paw](https://github.com/alexcatdad/paw).

## Quick Install

```bash
brew tap alexcatdad/tap
brew install alexcatdad/tap/paw
paw init https://github.com/alexcatdad/dotfiles
paw install
```

This bootstrap installs `paw`, clones this repo, and runs `paw install`.

## Commands

```bash
paw install
paw link --force
paw status
paw sync
paw push "message"
paw doctor
```

## Layout (Hybrid)

```text
dotfiles/
├── home/                        # mirrored $HOME tree
│   ├── .zshrc
│   ├── .zshenv
│   ├── .gitconfig
│   ├── .config/
│   │   ├── shell/functions/
│   │   ├── starship.toml
│   │   ├── git/ignore
│   │   ├── ghostty/config
│   │   ├── homebrew/Brewfile
│   │   └── ripgrep/config
│   └── .claude/
│       ├── settings.json
│       └── statusline-command.sh
├── templates/                   # machine-local template sources
├── extras/                      # non-linked extras (reference material)
│   └── ssh/config
├── paw.toml                     # native paw configuration
└── install.sh
```

## Machine-Specific Files

`paw` creates these from templates and keeps them out of git:

- `~/.zshrc.local`
- `~/.zshenv.local`
- `~/.gitconfig.local`
- `~/.ssh/config.local`

## Notes

- `paw.toml` is the single source of truth.
- Hooks are command strings in TOML; no TS runtime config.
- This repo targets Linux, macOS, and WSL.
