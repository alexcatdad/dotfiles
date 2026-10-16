# Install plugins during explicit setup, never from shell startup.
for _dotfiles_plugin in \
  "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/local/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  "${DOTFILES_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}}/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"; do
  if [[ -r $_dotfiles_plugin ]]; then source "$_dotfiles_plugin"; break; fi
done

[[ -r "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/shell/alias-tips.zsh" ]] && source "${DOTFILES_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}/shell/alias-tips.zsh"

for _dotfiles_plugin in \
  "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" \
  /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh \
  /usr/local/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh \
  /usr/local/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh \
  /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh \
  /usr/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh \
  "${DOTFILES_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}}/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"; do
  if [[ -r $_dotfiles_plugin ]]; then source "$_dotfiles_plugin"; break; fi
done
unset _dotfiles_plugin
true
