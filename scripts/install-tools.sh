#!/bin/sh
# Explicit setup only. Uses reviewed local Go source; no curl|sh bootstrap.
set -eu
dotfiles_repo=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
dotfiles_build_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-tools.XXXXXX")
trap 'rm -rf "$dotfiles_build_dir"' EXIT HUP INT TERM
(
    cd "$dotfiles_repo"
    GOTOOLCHAIN=local go build -o "$dotfiles_build_dir/dotfiles" ./cmd/dotfiles
)
"$dotfiles_build_dir/dotfiles" tools --repo "$dotfiles_repo" "$@"
