#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# Claude Code Status Line - Gruvbox Dark Theme with Powerline
# Managed by dotfiles: https://github.com/alexcatdad/dotfiles
# ══════════════════════════════════════════════════════════════════════════════

# Read JSON input from stdin
input=$(cat)

# Gruvbox Dark color palette
color_fg0='#fbf1c7'
color_bg1='#3c3836'
color_bg3='#665c54'
color_blue='#458588'
color_aqua='#689d6a'
color_green='#98971a'
color_orange='#d65d0e'
color_purple='#b16286'
color_red='#cc241d'
color_yellow='#d79921'

# Powerline separator characters (U+E0B0, U+E0B2)
# Using ANSI-C quoting $'...' which bash interprets at assignment time
sep_right=$'\xee\x82\xb0'   # Powerline right arrow (U+E0B0)
sep_left=$'\xee\x82\xb2'    # Powerline left arrow (U+E0B2)

# Get data from JSON
hostname=$(hostname -s)
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')

# Detect OS icon
case "$(uname -s)" in
    Darwin) os_symbol="󰀵" ;;
    Linux)  os_symbol="󰌽" ;;
    *)      os_symbol="?" ;;
esac

# Get directory name (truncate path similar to starship)
dir_name=$(basename "$cwd")
parent_dir=$(dirname "$cwd")
if [ "$parent_dir" != "/" ] && [ "$parent_dir" != "$HOME" ]; then
    parent_name=$(basename "$parent_dir")
    display_path="…/$parent_name/$dir_name"
else
    display_path="$dir_name"
fi

# Get git branch and status (skip optional locks)
git_branch=""
git_status_info=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    git_branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null || echo "detached")

    # Check for uncommitted changes
    if ! git -C "$cwd" --no-optional-locks diff-index --quiet HEAD -- 2>/dev/null; then
        git_status_info="✘"
    fi

    # Check for untracked files
    if [ -n "$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null)" ]; then
        git_status_info="${git_status_info}?"
    fi
fi

# Get current time
current_time=$(date +"%R")

# Get context window usage
usage=$(echo "$input" | jq '.context_window.current_usage')
context_display=""
if [ "$usage" != "null" ]; then
    # Calculate current context usage (input + cache creation + cache read)
    current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    size=$(echo "$input" | jq '.context_window.context_window_size')

    if [ "$current" != "null" ] && [ "$size" != "null" ] && [ "$size" -gt 0 ]; then
        pct=$((current * 100 / size))

        # Format the tokens with k suffix if over 1000
        if [ "$current" -ge 1000 ]; then
            current_k=$((current / 1000))
            context_display="${current_k}k/${pct}%"
        else
            context_display="${current}/${pct}%"
        fi
    fi
fi

# Build the status line with powerline style
printf "\033[48;2;214;93;14m\033[38;2;251;241;199m %s %s " "$os_symbol" "$hostname"
printf "\033[48;2;215;153;33m\033[38;2;214;93;14m%s" "$sep_right"
printf "\033[48;2;215;153;33m\033[38;2;251;241;199m %s " "$display_path"

if [ -n "$git_branch" ]; then
    printf "\033[48;2;104;157;106m\033[38;2;215;153;33m%s" "$sep_right"
    printf "\033[48;2;104;157;106m\033[38;2;251;241;199m  %s " "$git_branch"
    if [ -n "$git_status_info" ]; then
        printf "\033[48;2;104;157;106m\033[38;2;251;241;199m%s " "$git_status_info"
    fi
    printf "\033[48;2;69;133;136m\033[38;2;104;157;106m%s" "$sep_right"
else
    printf "\033[48;2;69;133;136m\033[38;2;215;153;33m%s" "$sep_right"
fi

# Model name section (using blue color)
printf "\033[48;2;69;133;136m\033[38;2;251;241;199m  %s " "$model"

# Context usage section (using bg3 color like docker/conda in starship)
if [ -n "$context_display" ]; then
    printf "\033[48;2;102;92;84m\033[38;2;69;133;136m%s" "$sep_right"
    printf "\033[48;2;102;92;84m\033[38;2;131;165;152m  %s " "$context_display"
    printf "\033[48;2;60;56;54m\033[38;2;102;92;84m%s" "$sep_right"
else
    printf "\033[48;2;60;56;54m\033[38;2;69;133;136m%s" "$sep_right"
fi

# Time section
printf "\033[48;2;60;56;54m\033[38;2;251;241;199m   %s " "$current_time"
printf "\033[0m\033[38;2;60;56;54m%s" "$sep_right"
printf "\033[0m"
