#!/bin/bash

declare -a locations # Locations of the dotfiles to link
declare -a dotfiles # Location of the link

# Neovim
locations+=( "nvim" )
dotfiles+=( ".config/nvim" )

# Lunarvim
locations+=( "lunarvim/config.lua" )
dotfiles+=( ".config/lvim" )

# Tmux
locations+=( "tmux/tmux_config" )
dotfiles+=( ".tmux.conf" )

# zsh
locations+=( "zsh/zshconfig" )
dotfiles+=( ".zshrc" )
locations+=( "zsh/z.sh" )
dotfiles+=( ".z.sh" )


for i in "${!dotfiles[@]}"
do
  echo "ln -s ~/dotfiles/${locations[$i]} ~/${dotfiles[$i]}"
done
