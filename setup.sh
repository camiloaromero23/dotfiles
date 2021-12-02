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
locations+=( "tmux/tmux_config" )
dotfiles+=( ".tmux.conf" )

# zsh
locations+=( "zsh" )
dotfiles+=( ".config/zsh" )

# Kitty terminal emulator
locations+=( "kitty" )
dotfiles+=( ".config/kitty" )

# Uncomment these if sens_conf needed
# locations+=( "zsh/sens_conf" )
# dotfiles+=( ".sens_conf" )

for i in "${!dotfiles[@]}"
do
  echo "ln -s ~/dotfiles/${locations[$i]} ~/${dotfiles[$i]}"
done
