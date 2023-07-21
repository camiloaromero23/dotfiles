local M = {}
local wezterm = require "wezterm"
local os = io.popen("uname"):read "l"

local sf_mono_name = os == "Linux" and "SFMonoNerdFontMono" or "SFMono Nerd Font"

M.sf_mono = wezterm.font {
  family = sf_mono_name,
  weight = "Medium",
}
M.sf_mono_rules = {
  {
    intensity = "Half",
    italic = false,
    font = wezterm.font {
      family = sf_mono_name,
      weight = "Regular",
    },
  },
}

M.sf_mono_size = 19.25

M.caskaydia_cove = wezterm.font {
  family = "CaskaydiaCove Nerd Font",
  weight = "Medium",
}

M.caskaydia_cove_rules = {
  {
    intensity = "Half",
    italic = false,
    font = wezterm.font {
      family = "CaskaydiaCove Nerd Font",
      weight = "Regular",
    },
  },
}

M.caskaydia_cove_size = os == "Linux" and 15.5 or 19.75

return M
