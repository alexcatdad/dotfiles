# Optional non-secret machine integration. Manually select as
# ~/.config/shell/machine.zsh during a separately approved activation.
if [[ $OSTYPE == darwin* ]]; then
  if [[ -r "$HOME/.orbstack/shell/init.zsh" && -z ${_DOTFILES_ORBSTACK_LOADED-} ]]; then
    source "$HOME/.orbstack/shell/init.zsh"
    typeset -g _DOTFILES_ORBSTACK_LOADED=1
  fi
  # Existing application path; no application is installed by this file.
  if [[ -d "$HOME/.lmstudio/bin" ]]; then
    typeset -U path
    path+=( "$HOME/.lmstudio/bin" )
  fi
fi
# Scaleway CLI completion (previously appended to ~/.zshrc by scw).
(( $+commands[scw] )) && eval "$(scw autocomplete script shell=zsh)"
