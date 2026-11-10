#!/bin/sh
# Link every file under home/ to the same path in a home directory.
# Anything already there is moved to a timestamped backup, never deleted.
#
# Usage: scripts/link.sh [--machine NAME] [--dry-run] [TARGET_HOME]
#   --machine NAME  also link machines/NAME.zsh as ~/.config/shell/machine.zsh
#   --dry-run       print what would change
#   TARGET_HOME     defaults to $HOME; pass a temp directory to test
set -eu

repo=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
machine='' target='' dry_run=0
while [ $# -gt 0 ]; do
    case $1 in
        --machine) machine=${2:?--machine needs a name}; shift 2 ;;
        --machine=*) machine=${1#--machine=}; shift ;;
        --dry-run) dry_run=1; shift ;;
        -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        -*) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
        *) target=$1; shift ;;
    esac
done
target=${target:-$HOME}
[ -d "$target" ] || { printf 'Not a directory: %s\n' "$target" >&2; exit 1; }
target=$(CDPATH='' cd -- "$target" && pwd -P)
backup="$target/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
changed=0

run() { if [ "$dry_run" -eq 1 ]; then printf '  would: %s\n' "$*"; else "$@"; fi; }

# Move an existing path into the backup directory, keeping its relative path.
set_aside() {
    rel=$1
    run mkdir -p "$backup/$(dirname "$rel")"
    run mv "$target/$rel" "$backup/$rel"
}

# A parent that is itself a symlink (for example into a read-only store) would
# make the new link land somewhere else, so replace it with a real directory.
real_parents() {
    rel=$1 walked=''
    dir=$(dirname "$rel")
    [ "$dir" = . ] && return 0
    old_ifs=$IFS; IFS=/
    # shellcheck disable=SC2086 # deliberate split on /
    set -- $dir
    IFS=$old_ifs
    for part; do
        walked=${walked:+$walked/}$part
        if [ -L "$target/$walked" ] || { [ -e "$target/$walked" ] && [ ! -d "$target/$walked" ]; }; then
            set_aside "$walked"
        fi
    done
    run mkdir -p "$target/$dir"
}

link() {
    src=$1 rel=$2
    dst="$target/$rel"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then return 0; fi
    printf '%s\n' "$rel"
    changed=$((changed + 1))
    real_parents "$rel"
    if [ -e "$dst" ] || [ -L "$dst" ]; then set_aside "$rel"; fi
    run ln -s "$src" "$dst"
}

list=$(mktemp)
trap 'rm -f "$list"' EXIT
( cd "$repo/home" && find . -type f ! -name .DS_Store | sed 's|^\./||' | sort ) > "$list"
while IFS= read -r rel; do
    case $rel in
        # Platform files are linked under one fixed name, below.
        .config/ghostty/platforms/*) continue ;;
    esac
    link "$repo/home/$rel" "$rel"
done < "$list"

if [ "$(uname -s)" = Darwin ]; then
    link "$repo/home/.config/ghostty/platforms/macos.conf" .config/ghostty/platform.conf
fi

if [ -n "$machine" ]; then
    [ -r "$repo/machines/$machine.zsh" ] || { printf 'No machines/%s.zsh\n' "$machine" >&2; exit 1; }
    link "$repo/machines/$machine.zsh" .config/shell/machine.zsh
fi

if [ "$changed" -eq 0 ]; then
    printf 'Already linked: nothing to change in %s\n' "$target"
elif [ "$dry_run" -eq 1 ]; then
    printf 'Dry run: %s path(s) would change in %s\n' "$changed" "$target"
else
    printf 'Linked %s path(s) into %s\n' "$changed" "$target"
    [ ! -d "$backup" ] || printf 'Replaced files are in %s\n' "$backup"
fi
