local M = {}
local wezterm = require "wezterm"

M.sf_mono = wezterm.font {
  family = "SFMono Nerd Font",
  weight = "Medium",
}
M.sf_mono_rules = {
  {
    intensity = "Half",
    italic = false,
    font = wezterm.font {
      family = "SFMono Nerd Font",
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

M.caskaydia_cove_size = 19.75

return M
