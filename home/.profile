# POSIX login environment. Shell-specific interactive settings live elsewhere.
[ ! -r "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/shell/env.sh" ] || . "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/shell/env.sh"
[ ! -r "$HOME/.profile.local" ] || . "$HOME/.profile.local"
true
