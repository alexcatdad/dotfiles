# Agent instructions and skill sources

`home/.codex/AGENTS.md` is the global agent instruction file. `bootstrap.sh`
links it to `~/.codex/AGENTS.md`, and `~/.claude/CLAUDE.md` imports it.

It is written for agents: one statement per line, each starting with a keyword
(`NEVER`, `ALWAYS`, `IF`, `WHILE`, `FOR EACH`, `ON END`, `DO`). Keep that form
when editing, and check its size with `uvx ttok -m gpt-4o < home/.codex/AGENTS.md`.

## Hooks

`home/.config/agent-hooks/agent-hook.sh` enforces the rules a script can check.
It needs `jq`, and is linked to `~/.config/agent-hooks/` but not registered:
nothing in this repo edits an agent's settings.

| Event | Effect |
|---|---|
| `PreToolUse` on `Bash` | Denies `git reset --hard`, `git checkout .`, `git clean -f`, force pushes and `--no-verify`. For `sudo` and installs, Claude Code asks the owner and Codex denies. |
| `PostToolUse` | Mirrors the agent's task list into `session-progress/state.json` and renders it when the `html-session-progress` skill is installed. |
| `Stop` | Copies the final message to the dashboard. Blocks once when background work is running and the message has no "Still running" note. |

Register it for Claude Code by merging this into the `hooks` object of
`~/.claude/settings.json`; use the same command with `--agent codex` in
`~/.codex/hooks.json`, then trust it there with `/hooks`:

```json
{
  "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "sh ~/.config/agent-hooks/agent-hook.sh --agent claude-code" }] }],
  "PostToolUse": [{ "matcher": "TaskCreate|TaskUpdate|TodoWrite|update_plan", "hooks": [{ "type": "command", "command": "sh ~/.config/agent-hooks/agent-hook.sh --agent claude-code" }] }],
  "Stop": [{ "hooks": [{ "type": "command", "command": "sh ~/.config/agent-hooks/agent-hook.sh --agent claude-code" }] }]
}
```

## Skills

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
