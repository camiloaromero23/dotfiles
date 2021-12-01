PATH=$PATH:$HOME/.scripts
export PATH=~/.local/bin:$PATH
export EDITOR='lvim'
# export TERMINAL='kitty'
# export BROWSER='firefox'
export MANPAGER='lvim +Man!'
export TERM='xterm-256color'

# Autocd
setopt autocd

# vi mode
bindkey -v

bindkey -M viins 'jk' vi-cmd-mode
bindkey -M viins 'kj' vi-cmd-mode

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

source $ZDOTDIR/prompt.sh
