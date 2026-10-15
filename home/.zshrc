setopt AUTO_CD HIST_IGNORE_DUPS HIST_IGNORE_SPACE APPEND_HISTORY EXTENDED_HISTORY
# One history-writing mode; Atuin independently provides cross-session search.
setopt SHARE_HISTORY
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"

[[ -r "$HOME/.config/shell/machine.zsh" ]] && source "$HOME/.config/shell/machine.zsh"

# Additional completions before compinit. No plugin manager or downloads.
for _dotfiles_completion in /opt/homebrew/share/zsh/site-functions /usr/local/share/zsh/site-functions /opt/homebrew/share/zsh-completions /usr/local/share/zsh-completions /usr/share/zsh-completions "$HOME/.local/share/zsh/plugins/zsh-completions/src"; do
  [[ -d $_dotfiles_completion ]] && fpath=( "$_dotfiles_completion" $fpath )
done
unset _dotfiles_completion
autoload -Uz compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
bindkey -e

source "$HOME/.config/shell/aliases.zsh"
source "$HOME/.config/shell/functions.zsh"

(( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd cd)"
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"
# Preserve normal Up-arrow behavior; use Atuin explicitly on Ctrl-R.
(( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow --disable-ai)"
(( $+commands[starship] )) && eval "$(starship init zsh)"

[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
# Load widget-sensitive highlighting last.
source "$HOME/.config/shell/plugins.zsh"
