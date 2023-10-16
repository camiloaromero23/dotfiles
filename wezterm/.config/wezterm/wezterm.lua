local wezterm = require "wezterm"
local hyperlink_rules = require "hyperlinks"
local one_dark = require "onehalf_dark"
local fonts = require "fonts"
-- [caskaydia_cove, jetbrains_mono]
local font_name = "caskaydia_cove"

local font = fonts[font_name]

-- === !== == != ++ -- => -> := :: www 0
return {
  warn_about_missing_glyphs = false,
  font = font.font,
  font_rules = font.rules,
  font_size = font.size,
  -- color_scheme = "OneDark (base16)",
  colors = one_dark,
  audible_bell = "Disabled",
  line_height = font.line_height or 1.3,
  hide_tab_bar_if_only_one_tab = true,
  window_decorations = "RESIZE",
  hyperlink_rules = hyperlink_rules,
  window_padding = {
    left = 4,
    right = 0,
    top = 7,
    bottom = 0,
  },
  keys = {
    {
      key = "w",
      mods = "CMD",
      action = wezterm.action.CloseCurrentTab { confirm = true },
    },
  },
}
