#!/bin/sh
# Set up a machine from this repository: link configs, install packages,
# schedule the daily update reminder.
#
# Usage: ./bootstrap.sh [--machine NAME] [--no-packages] [--no-app-store]
#   --machine NAME  also link machines/NAME.zsh (see machines/)
#   --no-packages   link configs only; skip Homebrew
#   --no-app-store  skip App Store apps (they hang unless you are signed in
#                   to the App Store)
#
# Homebrew must already be installed (https://brew.sh). Nothing here downloads
# an installer, asks for a password or signs in to anything.
set -eu

repo=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
machine='' packages=1 app_store=1
while [ $# -gt 0 ]; do
    case $1 in
        --machine) machine=${2:?--machine needs a name}; shift 2 ;;
        --machine=*) machine=${1#--machine=}; shift ;;
        --no-packages) packages=0; shift ;;
        --no-app-store) app_store=0; shift ;;
        -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
done

step() { printf '\n==> %s\n' "$*"; }
failed=''

step 'Linking configs'
if [ -n "$machine" ]; then
    sh "$repo/scripts/link.sh" --machine "$machine"
else
    sh "$repo/scripts/link.sh"
fi

# Scan for secrets before every commit made in this checkout.
if [ -d "$repo/.git" ]; then git -C "$repo" config core.hooksPath .githooks; fi

if [ "$packages" -eq 1 ]; then
    step 'Installing packages'
    brew=$(command -v brew || true)
    for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        [ -n "$brew" ] && break
        [ -x "$candidate" ] && brew=$candidate
    done
    if [ -z "$brew" ]; then
        printf '%s\n' 'Homebrew is not installed. Install it from https://brew.sh, then run this again.' >&2
        failed="$failed packages"
    else
        if [ "$app_store" -eq 0 ]; then
            HOMEBREW_BUNDLE_MAS_SKIP=$(sed -n 's/^mas .*id: *\([0-9]*\).*/\1/p' "$repo/Brewfile" | tr '\n' ' ')
            export HOMEBREW_BUNDLE_MAS_SKIP
        elif grep -q '^mas ' "$repo/Brewfile"; then
            printf '%s\n' 'App Store apps install last and wait forever if you are not signed in to the App Store.' 'If that happens: Ctrl-C, sign in, run this again (or use --no-app-store).'
        fi
        "$brew" bundle --file "$repo/Brewfile" || failed="$failed packages"
        if [ -r "$repo/Brewfile.local" ]; then
            "$brew" bundle --file "$repo/Brewfile.local" || failed="$failed local-packages"
        fi
    fi
fi

if [ "$(uname -s)" = Darwin ]; then
    step 'Scheduling the daily update reminder'
    label=local.dotfiles.update-reminder
    agents="$HOME/Library/LaunchAgents"
    mkdir -p "$agents"
    cp "$repo/launchd/$label.plist" "$agents/$label.plist"
    launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$agents/$label.plist" || failed="$failed reminder"
fi

step 'Next steps (run these yourself)'
cat <<'EOF'
  gh auth login                 sign in to GitHub
  mo touchid enable             Touch ID for sudo
  sh scripts/macos-defaults.sh  optional: software update preferences
  mo slim --dry-run             optional: preview removing Intel code from apps
  Put machine-only settings in ~/.zshrc.local and ~/.gitconfig.local
EOF

if [ -n "$failed" ]; then
    printf '\nFinished with problems in:%s\n' "$failed" >&2
    exit 1
fi
printf '\nDone. Open a new terminal.\n'
