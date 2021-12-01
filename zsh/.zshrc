# Append local binaries to path
PATH=$PATH:$HOME/.scripts
export PATH=~/.local/bin:$PATH

export EDITOR='lvim'
export BROWSER='firefox'
export LC_CTYPE=en_US.UTF-8
export MANPAGER='lvim +Man!'
export TERMINAL='kitty'
# export TERM='xterm-256color' # Uncomment if not using kitty terminal emulator

# Autocd
setopt autocd

# vi mode
bindkey -v # Uncomment if you want to use vi-mode

# Keybindings for vi normal mode
bindkey -M viins 'jk' vi-cmd-mode
bindkey -M viins 'kj' vi-cmd-mode

# TODO: Update cursor on mode change

# Autocompletion
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list '' 'm:{a-zA-z}={A-Za-z}'

# History
alias history="history -i"
SAVEHIST=1000
HISTSIZE=1000
HISTFILESIZE=1000000000
HISTFILE=$ZDOTDIR/.zsh_history

setopt INC_APPEND_HISTORY
setopt HIST_FIND_NO_DUPS

# Source prompt info & theme
source $ZDOTDIR/prompt.sh

# Source z.sh directory jumping plugin
source $ZDOTDIR/z.sh

# Source sens_conf file if exists
[ -f ~/.sens_conf ] && source ~/.sens_conf

# Fuzzy finder for searching previous commands
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

