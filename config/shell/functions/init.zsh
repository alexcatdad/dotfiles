# ══════════════════════════════════════════════════════════════════════════════
# Custom Shell Functions - Zinit Plugin Loader
# ══════════════════════════════════════════════════════════════════════════════
# This file is loaded by Zinit as a local plugin. It sources all other .zsh
# files in this directory, enabling modular organization of custom functions.

# Source all .zsh files in this directory (except init.zsh itself)
for func_file in ${0:h}/*.zsh; do
  [[ "${func_file:t}" != "init.zsh" ]] && source "$func_file"
done

unset func_file
