# tmux-session-manager
bindkey -s '^s' 'tmux-session-manager\n'
bindkey -s '^k' 'tmux-session-manager -k\n'
stty stop undef

# vi-mode
bindkey -M viins 'jk' vi-cmd-mode
bindkey -M viins 'kj' vi-cmd-mode
