# Login-only Homebrew environment. Non-login shells get binary paths via .zshenv.
if [[ $OSTYPE == darwin* ]] && (( $+commands[brew] )); then
  eval "$(brew shellenv)"
fi
# Restore user binary priority after macOS path_helper/Homebrew initialization.
[[ -r "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/shell/path.zsh" ]] && source "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/shell/path.zsh"
