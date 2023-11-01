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

  geist_mono = {
    font = wezterm.font {
      family = "Geist Mono",
      weight = "DemiBold",
      harfbuzz_features = { "ss09=1" },
    },
    rules = {},
    size = 19.5,
    line_height = 1.225,
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
