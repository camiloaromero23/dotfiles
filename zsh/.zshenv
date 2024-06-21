ZDOTDIR=$HOME/.config/zsh
# TODO: check if can be deleted due to already appending to path in .zshrc
. "$HOME/.cargo/bin"
# TODO: check if exports can be added to .zshrc
export GTK_THEME=Adwaita:dark
export GTK2_RC_FILES=/usr/share/themes/Adwaita-dark/gtk-2.0/gtkrc
export QT_STYLE_OVERRIDE=adwaita-dark

eval "$(ssh-agent -s)" > /dev/null 2>&1
ssh-add ~/.ssh/id_ed25519 > /dev/null 2>&1
ssh-add ~/.ssh/id_ed25519_personal > /dev/null 2>&1

# Added by install-mac-toolchain.sh
. ~/code/developer-setup/mac/.reirc

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

