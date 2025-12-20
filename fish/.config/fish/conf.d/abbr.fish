status is-interactive; or return

# Listing
abbr -ag la  'eza -a -l -h --git --icons'
abbr -ag lai 'eza -a -l -h --git --icons --git-ignore'
abbr -ag ls  'eza --icons'
abbr -ag cat 'bat'
abbr -ag lg  'lazygit'

# Git
abbr -ag grpo  'git remote prune origin'
abbr -ag grpod 'git remote prune origin --dry-run'
abbr -ag gco-2 'git checkout @{-2}'

abbr -ag oc  'opencode'

# Reload fish config
abbr -ag sourcefish 'source ~/.config/fish/config.fish'
