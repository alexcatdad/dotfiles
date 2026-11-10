# Preserve the existing command behavior. Use native utilities despite aliases.
duf() {
  local -a entries
  entries=( "${1:-.}"/*(N) )
  (( $#entries )) || return 0
  if command sort -h </dev/null >/dev/null 2>&1; then
    command du -sh -- "${entries[@]}" 2>/dev/null | command sort -rh | command head -20
  else
    command du -sk -- "${entries[@]}" 2>/dev/null | command sort -rn | command head -20
  fi
}

suggest-aliases() {
  if ! (( $+commands[atuin] )); then
    print -u2 'Requires atuin for history analysis'
    return 1
  fi
  local min_count="${1:-5}" min_length="${2:-20}" count cmd suggestion
  print "Commands run ${min_count}+ times, longer than ${min_length} chars:"
  atuin history list --cmd-only 2>/dev/null | command sort | command uniq -c | command sort -rn |
    while read -r count cmd; do
      (( ${#cmd} < min_length || count < min_count )) && continue
      [[ "$cmd" =~ ^cd\ +[^\ ]+$ ]] && continue
      suggestion=$(print -r -- "$cmd" | command awk '{print $1}' | command sed 's/.*\///')
      if [[ "$cmd" == *' '* ]]; then
        suggestion=$(print -r -- "$cmd" | command awk '{for(i=1;i<=NF&&i<=3;i++) printf substr($i,1,1)}')
      fi
      printf "%4d×  %s\n" "$count" "$cmd"
      printf "       → alias %s='%s'\n\n" "$suggestion" "$cmd"
    done
}
