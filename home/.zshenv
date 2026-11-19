# Keep this file safe for non-interactive shells: no external commands or installs.
[[ -r "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/shell/path.zsh" ]] && source "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/shell/path.zsh"
export LESS='-R'
export LESSHISTFILE=-
[[ -r "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/ripgrep/config" ]] && export RIPGREP_CONFIG_PATH="${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/ripgrep/config"
[[ -r "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/starship.toml" ]] && export STARSHIP_CONFIG="${STARSHIP_CONFIG:-${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/starship.toml}"
[[ -r "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/atuin/config.toml" ]] && export ATUIN_CONFIG_DIR="${ATUIN_CONFIG_DIR:-${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/atuin}"
# Supply-chain defaults, mirrored from shell/env.sh for zsh and agent shells.
export npm_config_ignore_scripts=true npm_config_allow_git=none npm_config_min_release_age=7
export HOMEBREW_CASK_OPTS="${HOMEBREW_CASK_OPTS:---require-sha}"
# CLI aliases also available in non-interactive agent shells.
(( $+commands[woodpecker-cli] && ! $+commands[woodpecker] )) && alias woodpecker='woodpecker-cli'
(( $+commands[scw] && ! $+commands[scaleway] )) && alias scaleway='scw'
(( $+commands[pass-cli] && ! $+commands[proton-pass] )) && alias proton-pass='pass-cli'
(( $+commands[tofu] && ! $+commands[opentofu] )) && alias opentofu='tofu'
[[ -r "$HOME/.zshenv.local" ]] && source "$HOME/.zshenv.local"
# Debian/Ubuntu: skip the system compinit; .zshrc runs its own with -i.
skip_global_compinit=1
true
