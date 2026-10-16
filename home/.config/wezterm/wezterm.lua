local wezterm = require 'wezterm'
return {
  font = wezterm.font_with_fallback { 'FiraCode Nerd Font Mono', 'monospace' },
  font_size = 13,
  colors = { background = '#000000', foreground = '#c6c6c6', cursor_bg = '#80a0ff' },
  window_padding = { left = 10, right = 10, top = 8, bottom = 10 },
  audible_bell = 'Disabled',
}
