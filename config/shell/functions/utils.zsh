# ══════════════════════════════════════════════════════════════════════════════
# General Utility Functions
# ══════════════════════════════════════════════════════════════════════════════

# Extract any archive format
# Usage: extract archive.tar.gz
extract() {
  if [[ -f "$1" ]]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz)  tar xzf "$1" ;;
      *.tar.xz)  tar xJf "$1" ;;
      *.bz2)     bunzip2 "$1" ;;
      *.gz)      gunzip "$1" ;;
      *.tar)     tar xf "$1" ;;
      *.tbz2)    tar xjf "$1" ;;
      *.tgz)     tar xzf "$1" ;;
      *.zip)     unzip "$1" ;;
      *.Z)       uncompress "$1" ;;
      *.7z)      7z x "$1" ;;
      *.rar)     unrar x "$1" ;;
      *.zst)     unzstd "$1" ;;
      *)         echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Create directory and cd into it
# Usage: mkcd new-project
mkcd() {
  mkdir -p "$@" && cd "$@"
}

# Quick HTTP server in current directory
# Usage: serve [port]
serve() {
  local port="${1:-8000}"
  echo "Serving on http://localhost:$port"
  python3 -m http.server "$port"
}

# Get public IP address
myip() {
  curl -s ifconfig.me
  echo  # Add newline
}

# Get local IP address
localip() {
  if [[ "$(uname)" == "Darwin" ]]; then
    ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null
  else
    hostname -I | awk '{print $1}'
  fi
}

# Quick notes - append timestamped notes to a file
# Usage: note "remember to fix the bug" or just `note` to view
note() {
  local file="$HOME/.notes.md"
  if [[ $# -eq 0 ]]; then
    if [[ -f "$file" ]]; then
      cat "$file"
    else
      echo "No notes yet. Usage: note \"your note here\""
    fi
  else
    echo "- $(date '+%Y-%m-%d %H:%M'): $*" >> "$file"
    echo "Note added."
  fi
}

# Fuzzy cd with zoxide + fzf
# Usage: zf
zf() {
  if ! command -v zoxide &> /dev/null || ! command -v fzf &> /dev/null; then
    echo "Requires zoxide and fzf"
    return 1
  fi
  local dir=$(zoxide query -l | fzf --height 40% --reverse --preview 'eza -la --color=always {}' 2>/dev/null)
  [[ -n "$dir" ]] && cd "$dir"
}

# Weather in terminal
# Usage: weather [city]
weather() {
  curl -s "wttr.in/${1:-}"
}

# Cheat sheet for commands
# Usage: cheat tar
cheat() {
  curl -s "cheat.sh/$1"
}

# Quick calculator
# Usage: calc "2 + 2"
calc() {
  echo "$@" | bc -l
}

# Find and kill process by name
# Usage: killnamed chrome
killnamed() {
  ps aux | grep -i "$1" | grep -v grep | awk '{print $2}' | xargs kill -9
}

# Create a backup of a file
# Usage: backup important-file.txt
backup() {
  cp "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
}

# Show disk usage sorted by size
duf() {
  du -sh "${1:-.}"/* 2>/dev/null | sort -rh | head -20
}

# Suggest aliases for frequently used long commands
# Usage: suggest-aliases [min_count] [min_length]
suggest-aliases() {
  if ! command -v atuin &> /dev/null; then
    echo "Requires atuin for history analysis"
    return 1
  fi

  local min_count="${1:-5}"
  local min_length="${2:-20}"

  echo "Commands run ${min_count}+ times, longer than ${min_length} chars:\n"

  atuin history list --cmd-only 2>/dev/null | \
    sort | uniq -c | sort -rn | \
    while read count cmd; do
      # Skip short commands
      [[ ${#cmd} -lt $min_length ]] && continue
      # Skip if run less than min_count times
      [[ $count -lt $min_count ]] && continue
      # Skip simple cd commands
      [[ "$cmd" =~ ^cd\ +[^\ ]+$ ]] && continue

      # Generate suggested alias name
      local suggestion=$(echo "$cmd" | awk '{print $1}' | sed 's/.*\///')
      if [[ "$cmd" == *" "* ]]; then
        # Multi-word: use first letters
        suggestion=$(echo "$cmd" | awk '{for(i=1;i<=NF&&i<=3;i++) printf substr($i,1,1)}')
      fi

      printf "%4d×  %s\n" "$count" "$cmd"
      printf "       → alias %s='%s'\n\n" "$suggestion" "$cmd"
    done
}
