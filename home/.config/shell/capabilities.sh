# Functions only: capability checks happen when explicitly invoked.
dotfiles_open() {
    if command -v xdg-open >/dev/null 2>&1 && [ -n "${DISPLAY-}${WAYLAND_DISPLAY-}" ]; then xdg-open "$@"
    elif command -v open >/dev/null 2>&1; then command open "$@"
    elif command -v wslview >/dev/null 2>&1; then wslview "$@"
    else printf '%s\n' 'No desktop opener available; use an editor or browser explicitly.' >&2; return 1
    fi
}
dotfiles_copy() {
    if command -v wl-copy >/dev/null 2>&1 && [ -n "${WAYLAND_DISPLAY-}" ]; then wl-copy
    elif command -v pbcopy >/dev/null 2>&1; then pbcopy
    elif command -v xclip >/dev/null 2>&1 && [ -n "${DISPLAY-}" ]; then xclip -selection clipboard
    elif command -v clip.exe >/dev/null 2>&1 && [ "${DOTFILES_WSL_INTEROP-}" = 1 ]; then clip.exe
    else printf '%s\n' 'No clipboard provider available.' >&2; return 1
    fi
}
dotfiles_paste() {
    if command -v wl-paste >/dev/null 2>&1 && [ -n "${WAYLAND_DISPLAY-}" ]; then wl-paste --no-newline
    elif command -v pbpaste >/dev/null 2>&1; then pbpaste
    elif command -v xclip >/dev/null 2>&1 && [ -n "${DISPLAY-}" ]; then xclip -selection clipboard -o
    else printf '%s\n' 'No clipboard provider available.' >&2; return 1
    fi
}
