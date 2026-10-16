# Fish loads conf.d in non-interactive shells too. Environment stays quiet.
if not set -q DOTFILES_CONFIG_HOME
    set -gx DOTFILES_CONFIG_HOME "$HOME/.config"
    if set -q XDG_CONFIG_HOME; set -gx DOTFILES_CONFIG_HOME "$XDG_CONFIG_HOME"; end
end
if not set -q DOTFILES_DATA_HOME
    set -gx DOTFILES_DATA_HOME "$HOME/.local/share"
    if set -q XDG_DATA_HOME; set -gx DOTFILES_DATA_HOME "$XDG_DATA_HOME"; end
end
# Prepend lower-priority paths first so user-local binaries retain precedence.
for dotfiles_bin in /home/linuxbrew/.linuxbrew/bin /opt/homebrew/bin
    if test -d "$dotfiles_bin"; fish_add_path --path "$dotfiles_bin"; end
end
for dotfiles_var in HOMEBREW_PREFIX
    if set -q $dotfiles_var; and test -d "$$dotfiles_var/bin"; fish_add_path --move --path "$$dotfiles_var/bin"; end
end
set -l dotfiles_pnpm "$DOTFILES_DATA_HOME/pnpm"
if test -n "$PNPM_HOME"; set dotfiles_pnpm "$PNPM_HOME"; end
set -l dotfiles_go "$HOME/go/bin"
if test -n "$GOPATH"; set dotfiles_go "$GOPATH[1]/bin"; end
if test -n "$GOBIN"; set dotfiles_go "$GOBIN"; end
set -l dotfiles_cargo "$HOME/.cargo"
if test -n "$CARGO_HOME"; set dotfiles_cargo "$CARGO_HOME"; end
for dotfiles_bin in "$dotfiles_pnpm" "$dotfiles_go" "$dotfiles_cargo/bin" "$HOME/bin" "$HOME/.local/bin"
    if test -d "$dotfiles_bin"; fish_add_path --path "$dotfiles_bin"; end
end
if contains -- bun (string split , -- "$DOTFILES_RUNTIMES")
    set -l dotfiles_bun "$HOME/.bun"
    if set -q BUN_INSTALL; set dotfiles_bun "$BUN_INSTALL"; end
    if test -d "$dotfiles_bun/bin"; fish_add_path --path "$dotfiles_bun/bin"; end
end
set -gx LESS -R
set -gx LESSHISTFILE -
if test -r "$DOTFILES_CONFIG_HOME/ripgrep/config"; set -gx RIPGREP_CONFIG_PATH "$DOTFILES_CONFIG_HOME/ripgrep/config"; end
if test -r "$DOTFILES_CONFIG_HOME/starship.toml"; and not set -q STARSHIP_CONFIG; set -gx STARSHIP_CONFIG "$DOTFILES_CONFIG_HOME/starship.toml"; end
if test -r "$DOTFILES_CONFIG_HOME/atuin/config.toml"; and not set -q ATUIN_CONFIG_DIR; set -gx ATUIN_CONFIG_DIR "$DOTFILES_CONFIG_HOME/atuin"; end
status is-interactive; or return
set -q _DOTFILES_FISH_LOADED; and return
set -g _DOTFILES_FISH_LOADED 1
function _dotfiles_init
    set -l code (command $argv 2>/dev/null)
    if test $status -eq 0; printf '%s\n' $code | source; end
end
if command -q eza
    set -g _dotfiles_eza_icons --icons
    if set -q NO_COLOR; or test "$DOTFILES_ICONS" = 0; or test "$TERM" = dumb
        set -g _dotfiles_eza_icons --icons=never --color=never
    end
    function ls; command eza $_dotfiles_eza_icons --group-directories-first $argv; end
    function ll; command eza -lag $_dotfiles_eza_icons --group-directories-first --git $argv; end
    function la; command eza -a $_dotfiles_eza_icons --group-directories-first $argv; end
    function lt; command eza -T $_dotfiles_eza_icons --level=2 $argv; end
    function tree; command eza -T $_dotfiles_eza_icons $argv; end
end
if command -q rg; function grep; command rg --smart-case $argv; end; end
if command -q fd
    function find; command fd $argv; end
else if command -q fdfind
    function find; command fdfind $argv; end
end
function duf
    set -l directory .
    if set -q argv[1]; set directory "$argv[1]"; end
    set -l entries "$directory"/*
    if test (count $entries) -eq 0; return 0; end
    command du -sk -- $entries 2>/dev/null | command sort -rn | command head -20
end
function dotfiles_open; sh -c '. "$DOTFILES_CONFIG_HOME/shell/capabilities.sh"; dotfiles_open "$@"' sh $argv; end
function dotfiles_copy; sh -c '. "$DOTFILES_CONFIG_HOME/shell/capabilities.sh"; dotfiles_copy' sh; end
function dotfiles_paste; sh -c '. "$DOTFILES_CONFIG_HOME/shell/capabilities.sh"; dotfiles_paste' sh; end
function suggest-aliases
    command -q atuin; or begin; echo 'Requires atuin' >&2; return 1; end
    set -l min_count 5; set -l min_length 20
    if set -q argv[1]; set min_count "$argv[1]"; end
    if set -q argv[2]; set min_length "$argv[2]"; end
    atuin history list --cmd-only | command sort | command uniq -c | command sort -rn | command awk -v count="$min_count" -v length_min="$min_length" '$1 >= count {n=$1; $1=""; sub(/^ +/, ""); if (length($0)>=length_min) print n "x " $0}'
end
for dotfiles_pair in woodpecker:woodpecker-cli scaleway:scw proton-pass:pass-cli opentofu:tofu
    set -l parts (string split : "$dotfiles_pair")
    if not command -q "$parts[1]"; and command -q "$parts[2]"; alias "$parts[1]" "$parts[2]"; end
end
# Abbreviations display expansions before execution, using Fish's native editor.
abbr --add --global dfll ll
function _dotfiles_alias_tip --on-event fish_preexec
    if string match -qr -- '^eza -lag --icons --group-directories-first --git( |$)' "$argv[1]"
        printf 'Alias tip: ll\n'
    end
end
if not contains -- "$DOTFILES_PROFILE" minimal container
    if contains -- fnm (string split , -- "$DOTFILES_RUNTIMES")
        if command -q fnm; _dotfiles_init fnm env --use-on-cd --shell fish; end
    end
    if command -q zoxide; _dotfiles_init zoxide init fish --cmd cd; end
    if command -q direnv; _dotfiles_init direnv hook fish; end
end
if test "$TERM" != dumb
    if not contains -- "$DOTFILES_PROFILE" minimal container
        if command -q atuin; _dotfiles_init atuin init fish --disable-up-arrow --disable-ai; end
    end
    if command -q starship; and not set -q NO_COLOR
        _dotfiles_init starship init fish
    else
        function fish_prompt; printf '%s:%s> ' "$USER" "$PWD"; end
    end
end
if test -r "$DOTFILES_CONFIG_HOME/fish/local.fish"; source "$DOTFILES_CONFIG_HOME/fish/local.fish"; end
