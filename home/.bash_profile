[ ! -r "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/shell/env.sh" ] || . "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/shell/env.sh"
case $- in *i*) [ ! -r "$HOME/.bashrc" ] || . "$HOME/.bashrc" ;; esac
[ ! -r "$HOME/.bash_profile.local" ] || . "$HOME/.bash_profile.local"
true
