local wezterm = require "wezterm"
local os = io.popen("uname"):read "l"

local function font_with_nerd_fonts(font)
  local family = font.family
  local weight = font.weight

  return wezterm.font_with_fallback {
    {
      family = family,
      weight = weight,
    },
    {
      family = "Symbols Nerd Font",
    },
  }
end

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

  ibm = {
    font = font_with_nerd_fonts {
      family = "IBM Plex Mono",
      weight = "Medium",
    },
    size = 20,
    line_height = 1.15,
  },
  monaspace = {
    font = font_with_nerd_fonts {
      family = "Monaspace neon",
      weight = "Medium",
    },
    size = 19.75,
    line_height = 1.25,
  },
  commit_mono = {
    font = font_with_nerd_fonts {
      family = "CommitMono",
      weight = "Regular",
    },
    rules = {},
    size = os == "Linux" and 15.75 or 19.75,
    line_height = os == "Linux" and 1.35 or 1.375,
  },
  geist_mono = {
    font = font_with_nerd_fonts {
      family = "Geist Mono",
      weight = "DemiBold",
    },
    rules = {},
    size = 19.5,
    line_height = 1.2525,
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
