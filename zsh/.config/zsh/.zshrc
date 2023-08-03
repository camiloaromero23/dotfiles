# Append local binaries to path
export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk/
PATH=$PATH:$HOME/.scripts
PATH=~/.local/bin:$PATH
PATH=/opt/homebrew/bin:$PATH
PATH=/opt/local/bin:$PATH
PATH=~/.fnm:$PATH
PATH=$PATH:$ANDROID_SDK_ROOT/emulator
PATH=$PATH:$HOME/Library/Python/3.9/bin
export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools
export GPG_TTY=$(tty)
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
BASE_PATH=$([ "$(uname)" = "Darwin" ] && echo "/Users" || echo "/home")

# Path to your oh-my-zsh installation.
export ZSH="$BASE_PATH/$USER/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="juanghurtado"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" "af-magic" )

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

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
 HIST_STAMPS="%d/%m/%y %H:%M"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# Plugins
plugins=(zsh-autosuggestions sudo zsh-syntax-highlighting vi-mode git pass)

# Set cursor mode
VI_MODE_SET_CURSOR=true

bindkey -M viins 'jk' vi-cmd-mode # Comment if you don't want vi-mode
bindkey -M viins 'kj' vi-cmd-mode # Comment if you don't want vi-mode

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias ohmyzsh="mate ~/.oh-my-zsh"
export EDITOR='nvim'
# export BROWSER='firefox'
export LC_CTYPE=en_US.UTF-8
export MANPAGER='nvim +Man!'

# Aliases
alias la="exa -a -l -h --git --icons"
alias lai="exa -a -l -h --git --icons --git-ignore"
alias ls="exa --icons"
alias cat="bat"
alias lg="lazygit"
alias ess="eslint_d stop"
alias sourcezsh="source $ZDOTDIR/.zshrc"
alias uninstallLvim="bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/uninstall.sh)"
alias installLvim="bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/rolling/utils/installer/install.sh)"
alias installLvimRolling="LV_BRANCH=rolling bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/rolling/utils/installer/install.sh)"

# History
SAVEHIST=1000
HISTSIZE=1000
HISTFILESIZE=1000000000
HISTFILE=$ZDOTDIR/.zsh_history

setopt INC_APPEND_HISTORY
setopt HIST_FIND_NO_DUPS

# Source sens_conf file if exists
[ -f ~/.sens_conf ] && source ~/.sens_conf

# Fuzzy finder for searching previous commands
if [ -x "$(command -v fzf)" ]
then
  fzf_dir=$([ "$(uname)" = "Darwin" ] && echo "/opt/local/share/fzf/shell" || echo "/usr/share/fzf/")
  source $fzf_dir/key-bindings.zsh
  source $fzf_dir/completion.zsh
fi

# Source custom aliases
[ -f $ZDOTDIR/plugins/cheatsheet.sh ] && source $ZDOTDIR/plugins/cheatsheet.sh
# [ -f $ZDOTDIR/plugins/notify.sh ] && source $ZDOTDIR/plugins/notify.sh
[ -f $ZDOTDIR/plugins/cdmk.sh ] && source $ZDOTDIR/plugins/cdmk.sh

eval "$(starship init zsh)"

# Directory jumping
eval "$(zoxide init zsh)"

# FNM
eval "$(fnm env --use-on-cd)"
# eval "$(fnm env)"

# tmux-session-manager
bindkey -s '^s' 'tmux-session-manager\n'
bindkey -s '^k' 'tmux-session-manager -k\n'
