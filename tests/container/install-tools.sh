#!/bin/sh
set -eu
# Explicit disposable prefix. The native installer selects architecture/libc.
exec /usr/local/bin/dotfiles tools --repo /src --home /tmp/dotfiles-tool-setup \
    --prefix /usr/local/bin --cache-dir /tmp/dotfiles-tool-cache --tools starship,atuin,bun,fnm --apply "$@"
