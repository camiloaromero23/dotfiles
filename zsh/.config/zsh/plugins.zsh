# Starship
eval "$(starship init zsh)"

# Directory jumping
eval "$(zoxide init zsh)"

# FNM
eval "$(fnm env --use-on-cd)"
# eval "$(fnm env)"

# bun completions
[ -s "$BASE_PATH/$USER/.bun/_bun" ] && source "$BASE_PATH/$USER/.bun/_bun"
