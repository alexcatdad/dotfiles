typeset -U path
if [[ $OSTYPE == darwin* ]]; then
  [[ -d /opt/homebrew/bin ]] && path=( /opt/homebrew/bin /opt/homebrew/sbin $path )
  [[ -x /usr/local/bin/brew ]] && path=( /usr/local/bin /usr/local/sbin $path )
fi
# Only retain language/user paths which actually exist on this machine.
for _dotfiles_bin in "$HOME/.cargo/bin" "$HOME/.local/share/pnpm" "$HOME/bin" "$HOME/.local/bin"; do
  [[ -d $_dotfiles_bin ]] && path=( "$_dotfiles_bin" $path )
done
unset _dotfiles_bin
export PATH
