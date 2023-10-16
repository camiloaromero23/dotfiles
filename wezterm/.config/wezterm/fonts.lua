local wezterm = require "wezterm"
local os = io.popen("uname"):read "l"

local fonts = {
  caskaydia_cove = {
    font = wezterm.font {
      family = "CaskaydiaCove Nerd Font",
      weight = "Medium",
    },
    rules = {
      {
        intensity = "Half",
        italic = false,
        font = wezterm.font {
          family = "CaskaydiaCove Nerd Font",
          weight = "Regular",
        },
      },
    },
    size = os == "Linux" and 15.5 or 19.75,
  },

  jetbrains_mono = {
    font = wezterm.font {
      family = "JetBrainsMono Nerd Font",
      weight = "Medium",
    },
    rules = {},
    size = 19.5,
    line_height = 1.15,
  },
}

return fonts
