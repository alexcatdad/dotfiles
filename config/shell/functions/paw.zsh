# ══════════════════════════════════════════════════════════════════════════════
# Paw Dotfiles Manager Functions
# ══════════════════════════════════════════════════════════════════════════════

# Background sync for shell startup
# Silently syncs dotfiles in the background without blocking the shell
# Usage: Add `paw-sync-bg` to ~/.zshrc.local to enable
paw-sync-bg() {
  # Skip if paw is not installed
  command -v paw &>/dev/null || return 0

  # Run sync in background, fully detached
  # --quiet suppresses all output
  # --skip-update avoids network calls for paw binary (faster startup)
  (paw sync --quiet --skip-update 2>/dev/null &)

  # Disown to prevent job control messages
  disown 2>/dev/null
}

# Full background sync including paw update check
# Use this for periodic full syncs (e.g., in a cron job or tmux hook)
# Usage: paw-sync-full-bg
paw-sync-full-bg() {
  command -v paw &>/dev/null || return 0
  (paw sync --quiet --auto-update 2>/dev/null &)
  disown 2>/dev/null
}

# Interactive sync with output
# Usage: paw-sync
paw-sync() {
  command -v paw &>/dev/null || {
    echo "paw is not installed"
    return 1
  }
  paw sync "$@"
}
