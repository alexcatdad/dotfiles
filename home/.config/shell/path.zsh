typeset -U path
if [[ $OSTYPE == darwin* ]]; then
  [[ -d /opt/homebrew/bin ]] && path=( /opt/homebrew/bin /opt/homebrew/sbin $path )
  [[ -x /usr/local/bin/brew ]] && path=( /usr/local/bin /usr/local/sbin $path )
fi
# Linuxbrew and custom Homebrew prefixes do not require brew in startup.
for _dotfiles_prefix in /home/linuxbrew/.linuxbrew "$HOME/.linuxbrew" "${HOMEBREW_PREFIX-}"; do
  [[ -n $_dotfiles_prefix && -d $_dotfiles_prefix/bin ]] && path=( "$_dotfiles_prefix/bin" "$_dotfiles_prefix/sbin" $path )
done
# Only retain language/user paths which actually exist on this machine.
_dotfiles_gopath="${GOPATH:-$HOME/go}"
for _dotfiles_bin in "${CARGO_HOME:-$HOME/.cargo}/bin" "${PNPM_HOME:-${DOTFILES_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}}/pnpm}" "${GOBIN:-${_dotfiles_gopath%%:*}/bin}" "$HOME/bin" "$HOME/.local/bin"; do
  [[ -d $_dotfiles_bin ]] && path=( "$_dotfiles_bin" $path )
done
if [[ ,${DOTFILES_RUNTIMES-}, == *,bun,* && -d "${BUN_INSTALL:-$HOME/.bun}/bin" ]]; then
  path=( "${BUN_INSTALL:-$HOME/.bun}/bin" $path )
fi
unset _dotfiles_bin _dotfiles_prefix _dotfiles_gopath
export PATH
