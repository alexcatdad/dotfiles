#!/bin/sh
# One hook entry point for Claude Code and Codex. Reads the hook JSON on stdin,
# dispatches on hook_event_name. Usage: agent-hook.sh --agent claude-code|codex
# Wiring: see SKILL-SOURCES.md. A guardrail on command text, not a sandbox.
set -eu
agent=${2:-claude-code}
input=$(cat)
# Without jq the hook cannot read its input; never break the agent over that.
command -v jq >/dev/null 2>&1 || exit 0
event=$(printf '%s' "$input" | jq -r '.hook_event_name // ""')
state_dir=${PROGRESS_DIR:-$(printf '%s' "$input" | jq -r '.cwd // "."')/session-progress}
render=${PROGRESS_RENDER:-$HOME/.agents/skills/html-session-progress/scripts/render.sh}

# Claude Code can hand the decision to the owner; Codex can only deny.
ask() {
 if [ "$agent" = claude-code ]; then
  jq -cn --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
  exit 0
 fi
 printf 'Blocked: %s Ask the owner first.\n' "$1" >&2; exit 2
}
deny() { printf 'Blocked: %s\n' "$1" >&2; exit 2; }

guard() {
 [ "$(printf '%s' "$input" | jq -r '.tool_name // ""')" = Bash ] || exit 0
 cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
 # Each test sees the command with a leading separator so patterns anchor on a command start.
 has() { printf ';%s' "$cmd" | grep -Eq "$1"; }
 s='(^|[;&|(]|&&|\|\|)[[:space:]]*(sudo[[:space:]]+)?'
 has "${s}git[[:space:]]+reset[[:space:]].*--hard" && deny 'git reset --hard discards work.'
 has "${s}git[[:space:]]+(checkout|restore)[[:space:]]+(--[[:space:]]+)?\.([[:space:]]|$)" && deny 'this discards uncommitted work.'
 has "${s}git[[:space:]]+clean[[:space:]].*-[a-zA-Z]*f" && deny 'git clean -f deletes untracked files.'
 has "${s}git[[:space:]]+push([[:space:]].*)?[[:space:]](--force|-[a-zA-Z]*f)" && deny 'force push rewrites remote history.'
 has "${s}git[[:space:]].*--no-verify" && deny '--no-verify bypasses required checks.'
 has "${s}sudo[[:space:]]" && ask 'sudo needs the owner.'
 has "${s}(brew[[:space:]]+(install|upgrade|uninstall|reinstall|tap)|mas[[:space:]]+(install|upgrade)|(npm|pnpm|bun)[[:space:]]+(i|install|add)[[:space:]].*(-g|--global)|yarn[[:space:]]+global[[:space:]]+add|pip3?[[:space:]]+install|pipx[[:space:]]+install|uv[[:space:]]+(tool|pip)[[:space:]]+install|cargo[[:space:]]+install|go[[:space:]]+install|gem[[:space:]]+install|apt(-get)?[[:space:]]+install)([[:space:]]|$)" && ask 'installing software needs the owner.'
 exit 0
}

# Render state.json to HTML when the html-session-progress skill is installed.
draw() {
 if [ -f "$render" ]; then sh "$render" "$state_dir/state.json" "$state_dir/index.html" >/dev/null 2>&1 || true; fi
}

# Turn any supported task tool call into state.json, then render the dashboard.
progress() {
 mkdir -p "$state_dir"
 st="$state_dir/state.json"
 [ -f "$st" ] || jq -n '{title:"Session progress",updated:"",tasks:[],blockers:[],report:""}' > "$st"
 now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
 new=$(printf '%s' "$input" | jq --slurpfile s "$st" --arg now "$now" '
  def norm: {pending:"todo",in_progress:"doing",completed:"done"}[.] // "todo";
  def list(f): [to_entries[] | {id:(.key+1|tostring), text:(.value|f), status:(.value.status|norm)}];
  . as $in | .tool_input as $i | $s[0] as $old |
  (if   $in.tool_name=="TaskCreate" then
     $old.tasks + [{id:($in.tool_response.task.id|tostring), text:$i.subject, status:"todo"}]
   elif $in.tool_name=="TaskUpdate" then
     ($old.tasks | map(select(($i.status // "")!="deleted" or .id!=($i.taskId|tostring))
        | if .id==($i.taskId|tostring) and $i.status then .status=($i.status|norm) else . end
        | if .id==($i.taskId|tostring) and $i.subject then .text=$i.subject else . end))
   elif ($i.items|type)=="array" then $i.items | list(.content)
   elif ($i.plan |type)=="array" then $i.plan  | list(.step)
   elif ($i.todos|type)=="array" then $i.todos | list(.content)
   elif $i.advance==true then
     ($old.tasks | (map(.status)|index("doing")) as $d | (map(.status)|index("todo")) as $t
      | to_entries | map(if .key==$d then .value.status="done" elif .key==$t then .value.status="doing" else . end | .value))
   elif ($i.done|type)=="array" or ($i.start|type)=="number" then
     ($old.tasks | to_entries | map(
        if ((.key+1) as $n | ($i.done // []) | index($n)) != null then .value.status="done"
        elif (.key+1)==($i.start // 0) then .value.status="doing" else . end | .value))
   else $old.tasks end) as $tasks
  | $old | .tasks=$tasks | .updated=$now')
 printf '%s\n' "$new" > "$st.tmp" && mv -f "$st.tmp" "$st"
 draw
 exit 0
}

stop() {
 # Publish the final message to the dashboard when one exists.
 st="$state_dir/state.json"
 if [ -f "$st" ]; then
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  printf '%s' "$input" | jq --slurpfile s "$st" --arg now "$now" '(.last_assistant_message // "") as $m | $s[0] | .report=$m | .updated=$now' > "$st.tmp" && mv -f "$st.tmp" "$st"
  draw
 fi
 # Second pass after a block: let the turn end.
 [ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = true ] && exit 0
 running=$(printf '%s' "$input" | jq -r '[.background_tasks // [] | .[] | select(.status=="running") | "\(.id): \(.description // .command // "")"] | join("; ")')
 [ -n "$running" ] || exit 0
 printf '%s' "$input" | jq -e '(.last_assistant_message // "") | test("still running"; "i")' >/dev/null && exit 0
 jq -cn --arg r "Background work still running ($running). Before ending: add a \"Still running\" block saying what, how you will know it finished, and when you will check; set one fallback check." '{decision:"block",reason:$r}'
 exit 0
}

case "$event" in
 PreToolUse) guard ;;
 PostToolUse) progress ;;
 Stop) stop ;;
 *) exit 0 ;;
esac
