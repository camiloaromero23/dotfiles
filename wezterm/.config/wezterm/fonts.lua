local wezterm = require "wezterm"
local os = io.popen("uname"):read "l"

local sf_mono_name = os == "Linux" and "SFMonoNerdFontMono" or "SFMono Nerd Font"

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

  sf_mono = {
    font = wezterm.font {
      family = sf_mono_name,
      weight = "Medium",
    },
    rules = {
      {
        intensity = "Half",
        italic = false,
        font = wezterm.font {
          family = sf_mono_name,
          weight = "Regular",
        },
      },
    },
    size = 19.25,
  },

  dm_mono = {
    font = wezterm.font {
      family = "DM Mono",
      weight = "Medium",
    },
    rules = {},
    size = 19.75,
    line_height = 1.15,
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
