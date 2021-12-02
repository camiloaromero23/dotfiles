# Append local binaries to path
PATH=$PATH:$HOME/.scripts
export PATH=~/.local/bin:$PATH

export EDITOR='lvim'
export BROWSER='firefox'
export LC_CTYPE=en_US.UTF-8
export MANPAGER='lvim +Man!'
export TERMINAL='kitty'
# export TERM='xterm-256color' # Uncomment if not using kitty terminal emulator

# Aliases
alias la="exa -a -l -h --git --icons"
alias lai="exa -a -l -h --git --icons --git-ignore"
alias ls="exa --icons"

# Autocd
setopt autocd

# vi mode
# Keybindings for vi normal mode
bindkey -M viins 'jk' vi-cmd-mode # Comment if you don't want vi-mode
bindkey -M viins 'kj' vi-cmd-mode # Comment if you don't want vi-mode

# Set cursor mode
VI_MODE_SET_CURSOR=true

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

# History search
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward

autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^[[A" history-beginning-search-backward-end
bindkey "^[[B" history-beginning-search-forward-end

# Source prompt info & theme
source $ZDOTDIR/prompt.sh

# Source sens_conf file if exists
[ -f ~/.sens_conf ] && source ~/.sens_conf

# Fuzzy finder for searching previous commands
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Plugins
# sudo on double esc plugin
source $ZDOTDIR/plugins/sudo.plugin.zsh
# vi-mode plugin
source $ZDOTDIR/plugins/vi-mode.plugin.zsh # Comment if you don't want vi-mode
# zsh-autosuggestions
source $ZDOTDIR/plugins/zsh-autosuggestions.plugin.zsh
# zsh-syntax-highlighting
source $ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
# z.sh directory jumping plugin
source $ZDOTDIR/plugins/z.sh
