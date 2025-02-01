local wezterm = require "wezterm"

local config = wezterm.config_builder()

local hyperlink_rules = require "hyperlinks"

-- local one_dark = require "onehalf_dark"
-- local hybrid = require "hybrid"

local fonts = require "fonts"
-- [caskaydia_cove, jetbrains_mono, geist_mono, monaspace, ibm, commit_mono]
local font_name = "geist_mono"

local font = fonts[font_name]
-- === !== == != ++ -- => -> := :: www 0

local line_height = font.line_height

config.warn_about_missing_glyphs = false
config.font = font.font
config.font_rules = font.rules
config.font_size = font.size
config.color_scheme = "Catppuccin Mocha"
-- config.colors = colorscheme
config.audible_bell = "Disabled"
config.line_height = line_height or 1.3
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"
config.hyperlink_rules = hyperlink_rules
config.window_padding = {
  left = 4,
  right = 0,
  top = 7,
  bottom = 0,
}
config.keys = {
  {
    key = "w",
    mods = "CMD",
    action = wezterm.action.CloseCurrentTab { confirm = true },
  },
}

return config
