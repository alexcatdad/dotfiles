# Bash 3.2-compatible. External integrations require the versions in COMPATIBILITY.md.
HISTSIZE=50000
HISTFILESIZE=50000
HISTCONTROL=ignoreboth
[ ! -r "$DOTFILES_CONFIG_HOME/shell/capabilities.sh" ] || . "$DOTFILES_CONFIG_HOME/shell/capabilities.sh"
shopt -s histappend checkwinsize
bind 'set completion-ignore-case on'
if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
    for _dotfiles_completion in "${HOMEBREW_PREFIX:-/opt/homebrew}/etc/profile.d/bash_completion.sh" /usr/local/etc/profile.d/bash_completion.sh /usr/share/bash-completion/bash_completion; do
        if [ -r "$_dotfiles_completion" ]; then . "$_dotfiles_completion"; break; fi
    done
fi
unset _dotfiles_completion
# Optional native Bash editor enhancement. Installation/revision review is a
# separate setup action; no extension is fetched or enabled implicitly.
if [ "${DOTFILES_BASH_BLE-}" = 1 ] && [ "${TERM-}" != dumb ] && [ "${NO_COLOR+x}" != x ]; then
    for _dotfiles_ble in "$DOTFILES_DATA_HOME/blesh/ble.sh" /usr/share/blesh/ble.sh; do
        if [ -r "$_dotfiles_ble" ]; then . "$_dotfiles_ble" --noattach; break; fi
    done
    unset _dotfiles_ble
fi
if command -v eza >/dev/null 2>&1; then
    _dotfiles_icons='--icons'
    if [ "${NO_COLOR+x}" = x ] || [ "${DOTFILES_ICONS-}" = 0 ] || [ "${TERM-}" = dumb ]; then _dotfiles_icons='--icons=never --color=never'; fi
    alias ls="eza $_dotfiles_icons --group-directories-first"
    alias ll="eza -lag $_dotfiles_icons --group-directories-first --git"
    alias la="eza -a $_dotfiles_icons --group-directories-first"
    alias lt="eza -T $_dotfiles_icons --level=2"
    alias tree="eza -T $_dotfiles_icons"
    unset _dotfiles_icons
fi
command -v rg >/dev/null 2>&1 && alias grep='rg --smart-case'
if command -v fd >/dev/null 2>&1; then alias find='fd'; elif command -v fdfind >/dev/null 2>&1; then alias find='fdfind'; fi
for _dotfiles_pair in woodpecker:woodpecker-cli scaleway:scw proton-pass:pass-cli opentofu:tofu; do
    _dotfiles_alias=${_dotfiles_pair%%:*}; _dotfiles_cli=${_dotfiles_pair#*:}
    if ! command -v "$_dotfiles_alias" >/dev/null 2>&1 && command -v "$_dotfiles_cli" >/dev/null 2>&1; then alias "$_dotfiles_alias=$_dotfiles_cli"; fi
done
unset _dotfiles_pair _dotfiles_alias _dotfiles_cli
duf() (
    # A subshell keeps glob settings local and handles empty directories.
    shopt -s nullglob
    _dotfiles_entries=("${1:-.}"/*)
    [ "${#_dotfiles_entries[@]}" -gt 0 ] || return 0
    command du -sk -- "${_dotfiles_entries[@]}" 2>/dev/null | command sort -rn | command head -20
)
suggest-aliases() {
    command -v atuin >/dev/null 2>&1 || { printf '%s\n' 'Requires atuin' >&2; return 1; }
    atuin history list --cmd-only | command sort | command uniq -c | command sort -rn |
        command awk -v count="${1:-5}" -v length_min="${2:-20}" '$1 >= count {n=$1; $1=""; sub(/^ +/, ""); if (length($0)>=length_min) print n "x " $0}'
}
# Alias reminders parse only alias declarations and compare literal text.
# No DEBUG trap: it would interfere with Atuin and other history integrations.
dotfiles_alias_tip() {
    local name expansion line=${1-}
    while IFS= read -r name; do
        expansion=$(alias "$name")
        expansion=${expansion#*=}; expansion=${expansion#\'}; expansion=${expansion%\'}
        [ -n "$expansion" ] || continue
        case "$line" in "$expansion"|"$expansion "*) printf 'Alias tip: %s\n' "$name"; return 0 ;; esac
    done < <(compgen -A alias)
}
_dotfiles_init_code() {
    local code
    code=$("$@" 2>/dev/null) || return 0
    printf '%s\n' "$code"
}
case ${DOTFILES_PROFILE-server} in minimal|container) ;; *)
    case ,${DOTFILES_RUNTIMES-}, in *,fnm,*) command -v fnm >/dev/null 2>&1 && eval "$(_dotfiles_init_code fnm env --use-on-cd --shell bash)" ;; esac
    command -v zoxide >/dev/null 2>&1 && eval "$(_dotfiles_init_code zoxide init bash --cmd cd)"
    command -v direnv >/dev/null 2>&1 && eval "$(_dotfiles_init_code direnv hook bash)"
esac
if [ "${TERM-}" != dumb ]; then
    case ${DOTFILES_PROFILE-server} in minimal|container) ;; *)
        command -v atuin >/dev/null 2>&1 && eval "$(_dotfiles_init_code atuin init bash --disable-up-arrow --disable-ai)"
    esac
    if command -v starship >/dev/null 2>&1 && [ "${NO_COLOR+x}" != x ]; then
        eval "$(_dotfiles_init_code starship init bash)"
    else
        PS1='\u@\h:\w\$ '
    fi
fi
# Atuin's Bash integration provides a composable preexec hook on supported
# Bash versions. Minimal Bash retains the explicitly callable reminder.
if declare -p preexec_functions >/dev/null 2>&1; then
    preexec_functions+=(dotfiles_alias_tip)
fi
true
