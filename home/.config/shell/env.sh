# POSIX environment only: no subprocesses, downloads, or interactive hooks.
: "${DOTFILES_CONFIG_HOME:=${XDG_CONFIG_HOME:-$HOME/.config}}"
: "${DOTFILES_DATA_HOME:=${XDG_DATA_HOME:-$HOME/.local/share}}"
export DOTFILES_CONFIG_HOME DOTFILES_DATA_HOME
for _dotfiles_bin in "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/bin}" /opt/homebrew/bin /home/linuxbrew/.linuxbrew/bin "${CARGO_HOME:-$HOME/.cargo}/bin" "${PNPM_HOME:-$DOTFILES_DATA_HOME/pnpm}" "${GOBIN:-${GOPATH:-$HOME/go}/bin}" "$HOME/bin" "$HOME/.local/bin"; do
    [ -d "$_dotfiles_bin" ] || continue
    case ":$PATH:" in *:"$_dotfiles_bin":*) ;; *) PATH="$_dotfiles_bin${PATH:+:$PATH}" ;; esac
done
case ,${DOTFILES_RUNTIMES-}, in *,bun,*)
    _dotfiles_bin="${BUN_INSTALL:-$HOME/.bun}/bin"
    if [ -d "$_dotfiles_bin" ]; then
        case ":$PATH:" in *:"$_dotfiles_bin":*) ;; *) PATH="$_dotfiles_bin${PATH:+:$PATH}" ;; esac
    fi
esac
unset _dotfiles_bin
export PATH LESS='-R' LESSHISTFILE=-
[ ! -r "$DOTFILES_CONFIG_HOME/ripgrep/config" ] || export RIPGREP_CONFIG_PATH="$DOTFILES_CONFIG_HOME/ripgrep/config"
[ ! -r "$DOTFILES_CONFIG_HOME/starship.toml" ] || export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$DOTFILES_CONFIG_HOME/starship.toml}"
[ ! -r "$DOTFILES_CONFIG_HOME/atuin/config.toml" ] || export ATUIN_CONFIG_DIR="${ATUIN_CONFIG_DIR:-$DOTFILES_CONFIG_HOME/atuin}"
true
