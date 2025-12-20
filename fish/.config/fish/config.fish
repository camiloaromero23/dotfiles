set -g fish_greeting
set -g fish_key_bindings fish_vi_key_bindings

# Load SSH keys from Keychain asynchronously
ssh-add --apple-load-keychain &>/dev/null &
disown

bind --mode default l forward-char

# Ensure Nix profiles are on PATH before everything else
for p in $HOME/.nix-profile /etc/profiles/per-user/$USER /run/current-system/sw /nix/var/nix/profiles/default
    if test -d "$p/bin"
        fish_add_path $p/bin
    end
end

fish_add_path /opt/homebrew/bin
fish_add_path /opt/local/bin
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/.fnm
fish_add_path $HOME/go/bin
fish_add_path $HOME/Library/pnpm
fish_add_path $HOME/.cargo/bin
set -gx BUN_INSTALL $HOME/.bun
fish_add_path $BUN_INSTALL/bin

set -gx XDG_CONFIG_HOME $HOME/.config

set -gx EDITOR nvim

set -gx SHELL /opt/homebrew/bin/fish

# Keybinds retained for future additions
bind --mode insert --sets-mode default j,k cancel repaint-mode
bind --mode insert --sets-mode default k,j cancel repaint-mode
bind --mode insert --sets-mode insert \cs tmux-session-manager
bind --mode insert --sets-mode insert \ck 'tmux-session-manager -k\n'
bind --mode default --sets-mode insert \cs tmux-session-manager
bind --mode default --sets-mode insert \ck 'tmux-session-manager -k\n'

starship init fish | source
zoxide init fish | source
fnm env --use-on-cd --shell fish | source

set -gx ATUIN_NOBIND "true"
atuin init fish | source

bind \cr --sets-mode insert _atuin_search
bind up --sets-mode insert _atuin_bind_up
bind --mode insert --sets-mode insert \cr _atuin_search
bind --mode insert --sets-mode insert up _atuin_bind_up
bind --mode default k _atuin_bind_up

# Set up fzf
set -Ux FZF_DEFAULT_OPTS "\
--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"

# name: 'Catppuccin Mocha'
# url: 'https://github.com/catppuccin/fish'
# preferred_background: 1e1e2e

set fish_color_normal cdd6f4
set fish_color_command a6e3a1
set fish_color_param f2cdcd
set fish_color_keyword cba6f7
set fish_color_quote a6e3a1
set fish_color_redirection f5c2e7
set fish_color_end fab387
set fish_color_comment 7f849c
set fish_color_error f38ba8
set fish_color_gray 6c7086
set fish_color_selection --background=313244
set fish_color_search_match --background=313244
set fish_color_option a6e3a1
set fish_color_operator f5c2e7
set fish_color_escape eba0ac
set fish_color_autosuggestion 6c7086
set fish_color_cancel f38ba8
set fish_color_cwd f9e2af
set fish_color_user 94e2d5
set fish_color_host 89b4fa
set fish_color_host_remote a6e3a1
set fish_color_status f38ba8
set fish_pager_color_progress 6c7086
set fish_pager_color_prefix f5c2e7
set fish_pager_color_completion cdd6f4
set fish_pager_color_description 6c7086
