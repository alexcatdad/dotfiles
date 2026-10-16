# Remote non-interactive Bash may read .bashrc: keep it silent.
[ ! -r "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/shell/env.sh" ] || . "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/shell/env.sh"
case $- in *i*) ;; *) return 0 ;; esac
[ -z "${_DOTFILES_BASH_LOADED-}" ] || return 0
_DOTFILES_BASH_LOADED=1
[ ! -r "$DOTFILES_CONFIG_HOME/shell/interactive.bash" ] || . "$DOTFILES_CONFIG_HOME/shell/interactive.bash"
[ ! -r "$HOME/.bashrc.local" ] || . "$HOME/.bashrc.local"
if [ "${DOTFILES_BASH_BLE-}" = 1 ] && [ "$(type -t ble-attach)" = function ]; then ble-attach; fi
true
