# Remind about an existing normal shell alias without invoking external tools.
# Compare shell words as data: never eval the command or alias expansion.
_alias_tips__preexec() {
  emulate -L zsh
  local command_line=$1 name best='' i
  local -a words expansion
  local best_count=0 matched
  words=( ${(z)command_line} )
  (( $#words )) || return 0
  # An alias was already used; do not remind about its expanded command.
  (( ${+aliases[${words[1]}]} )) && return 0
  for name in ${(k)aliases}; do
    expansion=( ${(z)aliases[$name]} )
    (( $#expansion && $#expansion <= $#words && ${#name} < ${#aliases[$name]} )) || continue
    matched=1
    for (( i=1; i <= $#expansion; i++ )); do
      [[ ${words[$i]} == ${expansion[$i]} ]] || { matched=0; break; }
    done
    (( matched )) || continue
    if (( $#expansion > best_count )) || { (( $#expansion == best_count )) && [[ -z $best || ${#name} -lt ${#best} || ( ${#name} -eq ${#best} && $name < $best ) ]]; }; then
      best=$name
      best_count=$#expansion
    fi
  done
  # Print the alias name only; do not echo arguments that could be sensitive.
  [[ -n $best ]] && print -r -- "Alias tip: $best"
  return 0
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec _alias_tips__preexec
