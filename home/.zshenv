# ══════════════════════════════════════════════════════════════════════════════
# ZSHENV - Zsh Environment Variables
# Sourced for all shell types (interactive, non-interactive, login, etc.)
# ══════════════════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────────────────
# PATH Configuration - Never see "add to your PATH" again
# ─────────────────────────────────────────────────────────────────────────────
# Helper function to add to PATH only if directory exists
path_prepend() {
  [[ -d "$1" ]] && PATH="$1:${PATH}"
}

path_append() {
  [[ -d "$1" ]] && PATH="${PATH}:$1"
}

# Start with system PATH
typeset -U PATH  # Ensure no duplicates

# ── User binaries (highest priority) ──
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/bin"

# ── Language-specific package managers ──

# Rust/Cargo
path_prepend "$HOME/.cargo/bin"

# Go
[[ -z "$GOPATH" ]] && export GOPATH="$HOME/go"
path_prepend "$GOPATH/bin"
path_prepend "$HOME/.go/bin"

# Bun
export BUN_INSTALL="$HOME/.bun"
path_prepend "$BUN_INSTALL/bin"

# Deno
export DENO_INSTALL="$HOME/.deno"
path_prepend "$DENO_INSTALL/bin"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
path_prepend "$PNPM_HOME"

# npm global (if not using fnm/nvm)
path_prepend "$HOME/.npm-global/bin"

# Python - pyenv
export PYENV_ROOT="$HOME/.pyenv"
path_prepend "$PYENV_ROOT/bin"
path_prepend "$PYENV_ROOT/shims"

# Python - pipx
path_prepend "$HOME/.local/pipx/bin"

# Ruby - rbenv
path_prepend "$HOME/.rbenv/bin"
path_prepend "$HOME/.rbenv/shims"

# Ruby - user gems
if [[ -d "$HOME/.gem/ruby" ]]; then
  for dir in "$HOME/.gem/ruby"/*/bin(N); do
    path_prepend "$dir"
  done
fi

# PHP - Composer
path_prepend "$HOME/.composer/vendor/bin"
path_prepend "$HOME/.config/composer/vendor/bin"

# Haskell - GHCup
path_prepend "$HOME/.ghcup/bin"
path_prepend "$HOME/.cabal/bin"

# .NET
path_prepend "$HOME/.dotnet/tools"

# Lua - LuaRocks
path_prepend "$HOME/.luarocks/bin"

# ── macOS specific ──
if [[ "$(uname)" == "Darwin" ]]; then
  # Homebrew (Apple Silicon)
  path_prepend "/opt/homebrew/bin"
  path_prepend "/opt/homebrew/sbin"
  # Homebrew (Intel)
  path_prepend "/usr/local/bin"
  path_prepend "/usr/local/sbin"
  # MacPorts (if used)
  path_prepend "/opt/local/bin"
fi

# ── Linux specific ──
if [[ "$(uname)" == "Linux" ]]; then
  # Linuxbrew
  path_prepend "/home/linuxbrew/.linuxbrew/bin"
  path_prepend "/home/linuxbrew/.linuxbrew/sbin"
  # Snap
  path_append "/snap/bin"
  # Flatpak
  path_append "/var/lib/flatpak/exports/bin"
  path_append "$HOME/.local/share/flatpak/exports/bin"
fi

export PATH

# Clean up helper functions
unfunction path_prepend path_append 2>/dev/null

# ─────────────────────────────────────────────────────────────────────────────
# Editor
# ─────────────────────────────────────────────────────────────────────────────
export EDITOR="code --wait"
export VISUAL="$EDITOR"

# ─────────────────────────────────────────────────────────────────────────────
# Language/Locale
# ─────────────────────────────────────────────────────────────────────────────
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# ─────────────────────────────────────────────────────────────────────────────
# Tool Configuration
# ─────────────────────────────────────────────────────────────────────────────
# Less
export LESS="-R"
export LESSHISTFILE=-

# Ripgrep config file
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"

# FZF defaults
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

# ─────────────────────────────────────────────────────────────────────────────
# Machine-Specific Environment (gitignored)
# ─────────────────────────────────────────────────────────────────────────────
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
