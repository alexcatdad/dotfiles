[[ -o interactive && -z ${_DOTFILES_ZSH_LOADED-} ]] || return 0
typeset -g _DOTFILES_ZSH_LOADED=1
typeset -g _DOTFILES_CONFIG="${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}"
setopt AUTO_CD HIST_IGNORE_DUPS HIST_IGNORE_SPACE APPEND_HISTORY EXTENDED_HISTORY
# One history-writing mode; Atuin independently provides cross-session search.
setopt SHARE_HISTORY
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"

[[ -r "$_DOTFILES_CONFIG/shell/machine.zsh" ]] && source "$_DOTFILES_CONFIG/shell/machine.zsh"

# Additional completions before compinit. No plugin manager or downloads.
typeset -U fpath
for _dotfiles_completion in "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh/site-functions" /usr/local/share/zsh/site-functions /opt/homebrew/share/zsh-completions /usr/local/share/zsh-completions /usr/local/share/zsh/plugins/zsh-completions/src /usr/share/zsh-completions /usr/share/zsh/vendor-completions /usr/share/zsh/site-functions "${DOTFILES_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}}/zsh/plugins/zsh-completions/src" "${DOTFILES_PLUGIN_DIR:+$DOTFILES_PLUGIN_DIR/zsh-completions/src}"; do
  [[ -d $_dotfiles_completion ]] && fpath=( "$_dotfiles_completion" $fpath )
done
unset _dotfiles_completion
autoload -Uz compinit
# Audit normally and ignore insecure directories without prompting (SSH/CI
# sessions may have no terminal). This does not use -u or bypass the audit.
compinit -i
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
bindkey -e

[[ -r "$_DOTFILES_CONFIG/shell/aliases.zsh" ]] && source "$_DOTFILES_CONFIG/shell/aliases.zsh"
[[ -r "$_DOTFILES_CONFIG/shell/functions.zsh" ]] && source "$_DOTFILES_CONFIG/shell/functions.zsh"
[[ -r "$_DOTFILES_CONFIG/shell/capabilities.sh" ]] && source "$_DOTFILES_CONFIG/shell/capabilities.sh"
_dotfiles_init_code() {
  local code
  code=$("$@" 2>/dev/null) || return 0
  printf '%s\n' "$code"
}

if [[ ${DOTFILES_PROFILE-server} != (minimal|container) ]]; then
  if [[ ,${DOTFILES_RUNTIMES-}, == *,fnm,* ]]; then
    (( $+commands[fnm] )) && eval "$(_dotfiles_init_code fnm env --use-on-cd --shell zsh)"
  fi
  (( $+commands[zoxide] )) && eval "$(_dotfiles_init_code zoxide init zsh --cmd cd)"
  (( $+commands[direnv] )) && eval "$(_dotfiles_init_code direnv hook zsh)"
fi
# Preserve normal Up-arrow behavior; use Atuin explicitly on Ctrl-R.
if [[ ${TERM-} != dumb ]]; then
  if [[ ${DOTFILES_PROFILE-server} != (minimal|container) ]]; then
    (( $+commands[atuin] )) && eval "$(_dotfiles_init_code atuin init zsh --disable-up-arrow --disable-ai)"
  fi
  if [[ ,${DOTFILES_RUNTIMES-}, == *,bun,* ]]; then
    [[ -r "${BUN_INSTALL:-$HOME/.bun}/_bun" ]] && source "${BUN_INSTALL:-$HOME/.bun}/_bun"
  fi
  if (( $+commands[starship] )) && [[ -z ${NO_COLOR+x} ]]; then
    eval "$(_dotfiles_init_code starship init zsh)"
  else
    PROMPT='%n@%m:%~%# '
  fi
fi

[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
# Load widget-sensitive highlighting last.
if [[ ${TERM-} != dumb && ${DOTFILES_PROFILE-server} != (minimal|container) ]]; then
  [[ -r "$_DOTFILES_CONFIG/shell/plugins.zsh" ]] && source "$_DOTFILES_CONFIG/shell/plugins.zsh"
fi
true
