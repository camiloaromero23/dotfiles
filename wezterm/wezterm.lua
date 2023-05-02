local wezterm = require "wezterm"
local hyperlink_rules = require "hyperlinks"
local one_dark = require "onehalf_dark"
local fonts = require "fonts"
-- caskaydia_cove or sf_mono
local font_name = "caskaydia_cove"

-- === !== == != ++ -- => -> := :: www 0
return {
  font = fonts[font_name],
  font_rules = fonts[font_name .. "_rules"],
  font_size = fonts[font_name .. "_size"],
  -- color_scheme = "OneDark (base16)",
  colors = one_dark,
  audible_bell = "Disabled",
  line_height = 1.3,
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
