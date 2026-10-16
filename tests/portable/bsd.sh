#!/bin/sh
# Invoked only in disposable hosted BSD VMs after native packages are installed.
set -eu
case "$(uname -s)" in
    FreeBSD) pw useradd tester -m -s /bin/sh ;;
    OpenBSD) useradd -m -s /bin/sh tester ;;
    *) printf '%s\n' 'Unsupported VM probe' >&2; exit 1 ;;
esac
mkdir -p /home/tester/dotfiles
for dotfiles_source in home machines cmd internal tests go.mod README.md; do
    cp -R "$dotfiles_source" /home/tester/dotfiles/
done
chown -R tester /home/tester/dotfiles
su -m tester -c 'cd /home/tester/dotfiles && env HOME=/home/tester GOCACHE=/tmp/dotfiles-go-cache GOTOOLCHAIN=local DOTFILES_REQUIRED_SHELLS=zsh,bash,fish,posix go test -v ./...'
