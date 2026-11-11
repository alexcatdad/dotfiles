#!/bin/sh
# Checks that need no network and touch nothing outside a temp directory.
# Usage: scripts/test.sh [shell]
#   (no argument)  lint the scripts, then test linking and shell startup
#   shell          only the linking and shell startup test
set -eu

repo=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
cd "$repo"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
ok() { printf 'ok: %s\n' "$*"; }

if [ "${1-}" != shell ]; then
    if command -v shellcheck >/dev/null 2>&1; then
        shellcheck bootstrap.sh scripts/*.sh .githooks/pre-commit home/.config/agent-hooks/agent-hook.sh
        # Sourced files have no shebang and source paths that exist only at runtime.
        shellcheck --shell=sh --exclude=SC1090,SC1091 \
            home/.profile home/.config/shell/env.sh home/.config/shell/capabilities.sh
        shellcheck --shell=bash --exclude=SC1090,SC1091,SC2139 home/.bashrc home/.bash_profile home/.config/shell/interactive.bash
        ok shellcheck
    else
        printf 'skip: shellcheck not installed\n'
    fi
    for file in home/.zshenv home/.zprofile home/.zshrc home/.config/shell/*.zsh machines/*.zsh; do
        zsh -n "$file" || fail "zsh syntax: $file"
    done
    ok 'zsh syntax'
    if [ "$(uname -s)" = Darwin ]; then
        plutil -lint launchd/*.plist >/dev/null || fail 'launchd plist'
        ok 'launchd plist'
    fi
    # The agent hook must deny, ask or allow each command as listed.
    if command -v jq >/dev/null 2>&1; then
        hook=home/.config/agent-hooks/agent-hook.sh
        while IFS="$(printf '\t')" read -r want agent cmd; do
            rc=0
            out=$(jq -cn --arg c "$cmd" '{hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:$c}}' \
                | sh "$hook" --agent "$agent" 2>/dev/null) || rc=$?
            case "$rc:$out" in 2:*) got=deny ;; 0:*'"ask"'*) got=ask ;; 0:) got=allow ;; *) got="exit $rc" ;; esac
            [ "$got" = "$want" ] || fail "agent hook: wanted $want, got $got ($agent): $cmd"
        done < scripts/agent-hook-cases.tsv
        # stop MESSAGE ALREADY_BLOCKED [TYPE]: a turn ending with one background task running.
        stop() {
            jq -cn --arg m "$1" --argjson a "$2" --arg t "${3-shell}" '{hook_event_name:"Stop",cwd:"/nonexistent",last_assistant_message:$m,
                stop_hook_active:$a,background_tasks:[{id:"t1",type:$t,status:"running",description:"tests"}]}' | sh "$hook" --agent claude-code
        }
        stop 'Finished.' false subagent | grep -q '"block"' || fail 'agent hook: unreported background subagent not blocked'
        out=$(stop 'Finished.' false monitor)
        [ -z "$out" ] || fail 'agent hook: blocked on a monitor'
        stop 'Finished.' false | grep -q '"block"' || fail 'agent hook: unreported background work not blocked'
        out=$(stop 'Still running: tests' false)
        [ -z "$out" ] || fail 'agent hook: reported background work blocked'
        out=$(stop 'Finished.' true)
        [ -z "$out" ] || fail 'agent hook: blocked twice'
        ok 'agent hook'
    else
        printf 'skip: jq not installed\n'
    fi
fi

home=$(mktemp -d)
trap 'rm -rf "$home"' EXIT

# A file and a symlinked directory already in the way must be backed up.
mkdir -p "$home/elsewhere"
printf 'old\n' > "$home/.zshrc"
ln -s "$home/elsewhere" "$home/.config"

sh scripts/link.sh --machine mac-studio "$home" >/dev/null
[ "$(readlink "$home/.zshrc")" = "$repo/home/.zshrc" ] || fail '.zshrc is not linked to the repo'
if [ ! -d "$home/.config" ] || [ -L "$home/.config" ]; then fail '.config was not made a real directory'; fi
[ "$(readlink "$home/.config/shell/machine.zsh")" = "$repo/machines/mac-studio.zsh" ] || fail 'machine file not linked'
[ "$(cat "$home"/.dotfiles-backup/*/.zshrc)" = old ] || fail 'replaced file was not backed up'
[ -z "$(ls "$home/elsewhere")" ] || fail 'wrote through a symlinked parent'
ok 'link: links, backups, symlinked parents'

sh scripts/link.sh --machine mac-studio "$home" | grep -q 'Already linked' || fail 'second run changed something'
ok 'link: second run changes nothing'

# Every tracked config is reachable through the links.
( cd home && find . -type f ! -name .DS_Store ! -path './.config/ghostty/platforms/*' ) | while IFS= read -r rel; do
    cmp -s "home/$rel" "$home/$rel" || fail "not linked: $rel"
done
ok 'link: every file reachable'

# Startup must print nothing to stderr, with or without the optional tools.
if command -v zsh >/dev/null 2>&1; then
    err=$(HOME="$home" ZDOTDIR="$home" TERM=xterm-256color zsh -i -c 'exit 0' 2>&1 >/dev/null </dev/null || true)
    # Without a terminal (CI) zsh itself reports that it cannot open one; not ours.
    err=$(printf '%s\n' "$err" | grep -v "can't open terminal" || true)
    [ -z "$err" ] || fail "zsh startup printed: $err"
    ok 'zsh starts cleanly'
fi
# Bash is checked without a terminal: the login and non-interactive paths.
if command -v bash >/dev/null 2>&1; then
    bash -n home/.config/shell/interactive.bash || fail 'bash syntax: interactive.bash'
    # shellcheck disable=SC2016 # expanded by the inner shell
    err=$(HOME="$home" LC_ALL=C bash -c '. "$HOME/.bash_profile" && . "$HOME/.bashrc" && [ -n "$DOTFILES_CONFIG_HOME" ]' 2>&1 || echo 'non-zero exit')
    [ -z "$err" ] || fail "bash startup printed: $err"
    ok 'bash loads cleanly'
fi
