# Keep this file safe for non-interactive shells: no external commands or installs.
[[ -r "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/shell/path.zsh" ]] && source "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/shell/path.zsh"
export LESS='-R'
export LESSHISTFILE=-
[[ -r "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/ripgrep/config" ]] && export RIPGREP_CONFIG_PATH="${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/ripgrep/config"
[[ -r "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/starship.toml" ]] && export STARSHIP_CONFIG="${STARSHIP_CONFIG:-${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/starship.toml}"
export ATUIN_CONFIG_DIR="${ATUIN_CONFIG_DIR:-${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/atuin}"
# CLI aliases also available in non-interactive agent shells.
(( $+commands[woodpecker-cli] && ! $+commands[woodpecker] )) && alias woodpecker='woodpecker-cli'
(( $+commands[scw] && ! $+commands[scaleway] )) && alias scaleway='scw'
(( $+commands[pass-cli] && ! $+commands[proton-pass] )) && alias proton-pass='pass-cli'
(( $+commands[tofu] && ! $+commands[opentofu] )) && alias opentofu='tofu'
[[ -r "$HOME/.zshenv.local" ]] && source "$HOME/.zshenv.local"
true
