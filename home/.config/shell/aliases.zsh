if (( $+commands[eza] )); then
  if [[ -n ${NO_COLOR+x} || ${DOTFILES_ICONS-} == 0 || ${TERM-} == dumb ]]; then
    alias ls='eza --icons=never --color=never --group-directories-first'
    alias ll='eza -lag --icons=never --color=never --group-directories-first --git'
    alias lt='eza -T --icons=never --color=never --level=2'
    alias la='eza -a --icons=never --color=never --group-directories-first'
    alias tree='eza -T --icons=never --color=never'
  else
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lag --icons --group-directories-first --git'
    alias lt='eza -T --icons --level=2'
    alias la='eza -a --icons --group-directories-first'
    alias tree='eza -T --icons=auto'
  fi
fi
(( $+commands[rg] )) && alias grep='rg --smart-case'
(( $+commands[fd] )) && alias find='fd'
(( ! $+commands[fd] && $+commands[fdfind] )) && alias find='fdfind'
true
