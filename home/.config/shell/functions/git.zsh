# ══════════════════════════════════════════════════════════════════════════════
# Git Helper Functions
# ══════════════════════════════════════════════════════════════════════════════
# Enhanced git workflows with fzf integration

# Interactive branch checkout with fzf
# Usage: gco (without arguments for interactive mode)
# Note: This shadows the alias in zshrc when called without args
gcof() {
  if ! command -v fzf &> /dev/null; then
    echo "Requires fzf for interactive mode"
    return 1
  fi
  local branch=$(git branch -a --color=always | \
    fzf --ansi --height 40% --reverse \
        --preview 'git log --oneline --color=always {1} | head -20' | \
    tr -d '[:space:]')
  if [[ -n "$branch" ]]; then
    # Strip remote prefix if present
    git checkout "${branch#remotes/origin/}"
  fi
}

# Interactive git log with fzf preview
# Usage: gshow
gshow() {
  if ! command -v fzf &> /dev/null; then
    git log --oneline -20
    return
  fi
  git log --oneline --color=always | \
    fzf --ansi --preview 'git show --color=always {1}' \
        --bind 'enter:execute(git show {1} | less -R)'
}

# Delete merged branches (safe - excludes main/master/develop)
# Usage: git-cleanup
git-cleanup() {
  local branches=$(git branch --merged | grep -v '\*\|main\|master\|develop')
  if [[ -z "$branches" ]]; then
    echo "No merged branches to clean up"
    return 0
  fi
  echo "Branches to delete:"
  echo "$branches"
  echo ""
  read "confirm?Delete these branches? [y/N] "
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "$branches" | xargs -n 1 git branch -d
    echo "Done!"
  else
    echo "Cancelled"
  fi
}

# Quick amend without editing message
# Usage: git-amend
git-amend() {
  git add -A && git commit --amend --no-edit
}

# Interactive staging with fzf
# Usage: gadd
gadd() {
  if ! command -v fzf &> /dev/null; then
    git add -i
    return
  fi
  local files=$(git status --short | \
    fzf --multi --preview 'git diff --color=always {2}' | \
    awk '{print $2}')
  [[ -n "$files" ]] && echo "$files" | xargs git add
}

# Show git stash list with fzf and preview
# Usage: gstash
gstash() {
  if ! command -v fzf &> /dev/null; then
    git stash list
    return
  fi
  local stash=$(git stash list | \
    fzf --preview 'git stash show -p $(echo {} | cut -d: -f1)' | \
    cut -d: -f1)
  if [[ -n "$stash" ]]; then
    echo "Apply, Pop, or Drop? [a/p/d]"
    read "action?"
    case "$action" in
      a) git stash apply "$stash" ;;
      p) git stash pop "$stash" ;;
      d) git stash drop "$stash" ;;
      *) echo "Cancelled" ;;
    esac
  fi
}

# Pretty git log graph
# Usage: glog
glog() {
  git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit "$@"
}

# Find commits by message
# Usage: gfind "bug fix"
gfind() {
  git log --oneline --all --grep="$1"
}

# Show who last modified each line
# Usage: gblame file.txt
gblame() {
  git blame --color-by-age --color-lines "$@"
}
