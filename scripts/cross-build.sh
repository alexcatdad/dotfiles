#!/bin/sh
set -eu
mkdir -p dist
for dotfiles_target in linux/amd64 linux/arm64 linux/386 linux/arm darwin/amd64 darwin/arm64 windows/amd64 windows/arm64 freebsd/amd64 freebsd/arm64 openbsd/amd64 openbsd/arm64 netbsd/amd64; do
    dotfiles_os=${dotfiles_target%/*}
    dotfiles_arch=${dotfiles_target#*/}
    dotfiles_suffix=''
    [ "$dotfiles_os" != windows ] || dotfiles_suffix=.exe
    CGO_ENABLED=0 GOTOOLCHAIN=local GOOS="$dotfiles_os" GOARCH="$dotfiles_arch" \
        go build -trimpath -o "dist/dotfiles-$dotfiles_os-$dotfiles_arch$dotfiles_suffix" ./cmd/dotfiles
    printf 'BUILT %s\n' "$dotfiles_target"
done
