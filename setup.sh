#!/bin/bash

declare -a locations # Locations of the dotfiles to link
declare -a dotfiles # Location of the link

# Neovim
# locations+=( "nvim" )
# dotfiles+=( ".config/nvim" )

# Lunarvim
locations+=( "lunarvim/config.lua" )
dotfiles+=( ".config/lvim" )

# Tmux
locations+=( "tmux" )
dotfiles+=( ".config/tmux" )

# zsh
locations+=( "zsh" )
dotfiles+=( ".config/zsh" )

# Kitty terminal emulator
locations+=( "kitty" )
dotfiles+=( ".config/kitty" )

# Weztterm terminal emulator
locations+=( "wezterm" )
dotfiles+=( ".config/wezterm" )

# zsh
locations+=( "starship.toml" )
dotfiles+=( ".config/starship.toml" )

# Git Config
locations+=( "git/.gitconfig" )
dotfiles+=( "" )
locations+=( "git/.gitignore_global" )
dotfiles+=( "" )

# I3
locations+=( "i3" )
dotfiles+=( ".config/i3" )

# Uncomment these if sens_conf needed
# locations+=( "zsh/sens_conf" )
# dotfiles+=( ".sens_conf" )

for i in "${!dotfiles[@]}"
do
  echo "ln -s ~/dotfiles/${locations[$i]} ~/${dotfiles[$i]}"
done
echo "ln -s ~/dotfiles/warp ~/.warp"
