#!/bin/sh
# Optional macOS software update preferences. Run it yourself; it asks for sudo.
# Security responses and system data files install automatically; macOS
# upgrades download but wait for you to restart.
set -eu
[ "$(uname -s)" = Darwin ] || { printf '%s\n' 'macOS only.' >&2; exit 1; }
domain=/Library/Preferences/com.apple.SoftwareUpdate
sudo defaults write "$domain" AutomaticCheckEnabled -bool true
sudo defaults write "$domain" AutomaticDownload -bool true
sudo defaults write "$domain" CriticalUpdateInstall -bool true
sudo defaults write "$domain" ConfigDataInstall -bool true
sudo defaults write "$domain" AutomaticallyInstallMacOSUpdates -bool false
printf '%s\n' 'Software update preferences written.'
