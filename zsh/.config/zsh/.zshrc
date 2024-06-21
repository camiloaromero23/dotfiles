source $ZDOTDIR/exports.zsh

BASE_PATH=$([ "$(uname)" = "Darwin" ] && echo "/Users" || echo "/home")

# Path to your oh-my-zsh installation.
export ZSH="$BASE_PATH/$USER/.oh-my-zsh"

export BAT_THEME="Catppuccin Mocha"

# Uncomment the following line to automatically update without prompting.
DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to disable auto-setting terminal title.
 DISABLE_AUTO_TITLE="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
 DISABLE_UNTRACKED_FILES_DIRTY="true"

source $ZDOTDIR/nix_config.zsh

# Plugins
plugins=(zsh-autosuggestions sudo zsh-syntax-highlighting vi-mode git pass)

source $ZSH/oh-my-zsh.sh

# Aliases
source $ZDOTDIR/aliases.zsh

# History
source $ZDOTDIR/history.zsh

# Source sens_conf file if exists
[ -f $HOME/.sens_conf ] && source $HOME/.sens_conf

# Fuzzy finder for searching previous commands
source $ZDOTDIR/fzf.zsh

# Source custom commands
source $ZDOTDIR/custom_commands.zsh

# External plugins
source $ZDOTDIR/plugins.zsh

# Keybindings
source $ZDOTDIR/keybindings.zsh

# source "$HOME/.zshrc"
