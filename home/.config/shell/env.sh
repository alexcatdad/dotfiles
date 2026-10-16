# POSIX environment only: no subprocesses, downloads, or interactive hooks.
: "${DOTFILES_CONFIG_HOME:=${XDG_CONFIG_HOME:-$HOME/.config}}"
: "${DOTFILES_DATA_HOME:=${XDG_DATA_HOME:-$HOME/.local/share}}"
export DOTFILES_CONFIG_HOME DOTFILES_DATA_HOME
_dotfiles_gopath=${GOPATH:-$HOME/go}
for _dotfiles_bin in /home/linuxbrew/.linuxbrew/bin /opt/homebrew/bin "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/bin}" "${CARGO_HOME:-$HOME/.cargo}/bin" "${PNPM_HOME:-$DOTFILES_DATA_HOME/pnpm}" "${GOBIN:-${_dotfiles_gopath%%:*}/bin}" "$HOME/bin" "$HOME/.local/bin"; do
    [ -d "$_dotfiles_bin" ] || continue
    if [ -n "${HOMEBREW_PREFIX-}" ] && [ "$_dotfiles_bin" = "$HOMEBREW_PREFIX/bin" ]; then
        # Move a pre-existing configured prefix ahead of fallback installations.
        _dotfiles_rest=$PATH _dotfiles_without=
        while :; do
            _dotfiles_entry=${_dotfiles_rest%%:*}
            [ "$_dotfiles_entry" = "$_dotfiles_bin" ] || _dotfiles_without="$_dotfiles_without:$_dotfiles_entry"
            case $_dotfiles_rest in *:*) _dotfiles_rest=${_dotfiles_rest#*:} ;; *) break ;; esac
        done
        PATH="$_dotfiles_bin$_dotfiles_without"
    else
        case ":$PATH:" in *:"$_dotfiles_bin":*) ;; *) PATH="$_dotfiles_bin${PATH:+:$PATH}" ;; esac
    fi
done
case ,${DOTFILES_RUNTIMES-}, in *,bun,*)
    _dotfiles_bin="${BUN_INSTALL:-$HOME/.bun}/bin"
    if [ -d "$_dotfiles_bin" ]; then
        case ":$PATH:" in *:"$_dotfiles_bin":*) ;; *) PATH="$_dotfiles_bin${PATH:+:$PATH}" ;; esac
    fi
esac
unset _dotfiles_bin _dotfiles_gopath _dotfiles_rest _dotfiles_without _dotfiles_entry
export PATH LESS='-R' LESSHISTFILE=-
[ ! -r "$DOTFILES_CONFIG_HOME/ripgrep/config" ] || export RIPGREP_CONFIG_PATH="$DOTFILES_CONFIG_HOME/ripgrep/config"
[ ! -r "$DOTFILES_CONFIG_HOME/starship.toml" ] || export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$DOTFILES_CONFIG_HOME/starship.toml}"
[ ! -r "$DOTFILES_CONFIG_HOME/atuin/config.toml" ] || export ATUIN_CONFIG_DIR="${ATUIN_CONFIG_DIR:-$DOTFILES_CONFIG_HOME/atuin}"
true
