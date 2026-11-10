# Agent instructions and skill sources

`home/.codex/AGENTS.md` is the global agent instruction file. `bootstrap.sh`
links it to `~/.codex/AGENTS.md`, and `~/.claude/CLAUDE.md` imports it.

`skills.json` records the agent skills installed on my machines, each pinned to
a full commit SHA. GitHub CLI installs them into `~/.agents/skills`; nothing in
this repo installs or updates a skill automatically. Some sources are private
repositories and need `gh` read access.

## Install one

```sh
name=use-up
entry=$(jq -c --arg n "$name" '.skills[] | select(.name==$n)' skills.json)
repo=$(printf '%s' "$entry" | jq -r .repository)
path=$(printf '%s' "$entry" | jq -r .path)
pin=$(printf '%s' "$entry" | jq -r .pin)
gh skill preview "$repo" "$path@$pin"
gh skill install "$repo" "$path" --dir "$HOME/.agents/skills" --pin "$pin"
```

`gh skill install` can drop executable bits; restore them on a package's
`scripts/*.sh` after installing.

## Update one

Pinned packages are skipped by `gh skill update`. Review the new commit and its
full contents, then install it with the new pin and record the pin in
`skills.json`. Never link a skill from a working checkout.
