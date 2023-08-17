source $ZDOTDIR/exports.zsh

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
BASE_PATH=$([ "$(uname)" = "Darwin" ] && echo "/Users" || echo "/home")

# Path to your oh-my-zsh installation.
export ZSH="$BASE_PATH/$USER/.oh-my-zsh"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
 # DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
 DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
 COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
 DISABLE_UNTRACKED_FILES_DIRTY="true"
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
