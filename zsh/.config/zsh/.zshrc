[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh"

# Exports
plug "$ZDOTDIR/exports.zsh"

# History
plug "$ZDOTDIR/history.zsh"

# Source sens_conf file if exists
[ -f $HOME/.sens_conf ] && plug $HOME/.sens_conf

# Aliases
plug "$ZDOTDIR/aliases.zsh"

# Keybindings
plug "$ZDOTDIR/keybindings.zsh"
# Source custom commands
plug "$ZDOTDIR/custom_commands.zsh"

# External plugins
plug "$ZDOTDIR/plugins.zsh"
plug "$ZDOTDIR/clipboard.zsh"

plug "zap-zsh/supercharge"
plug "zsh-users/zsh-autosuggestions"
plug "zsh-users/zsh-syntax-highlighting"
plug "zsh-users/zsh-completions"
plug "zap-zsh/sudo"

# Oh-my-zsh plugins
plug "$ZDOTDIR/ohmyzsh_plugins/vi-mode.plugin.zsh"
plug "$ZDOTDIR/ohmyzsh_plugins/git.plugin.zsh"
plug "$ZDOTDIR/ohmyzsh_plugins/completions.zsh"

#WARN: Do not move this lines to the top of the file, it will break the keybindings
# Keybindings
plug "$ZDOTDIR/keybindings.zsh"

# Fuzzy finder for searching previous commands
# plug "zap-zsh/fzf"
plug "$ZDOTDIR/fzf.zsh"
