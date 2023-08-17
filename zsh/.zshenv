ZDOTDIR=~/.config/zsh
. "$HOME/.cargo/bin"
export GTK_THEME=Adwaita:dark
export GTK2_RC_FILES=/usr/share/themes/Adwaita-dark/gtk-2.0/gtkrc
export QT_STYLE_OVERRIDE=adwaita-dark

eval "$(ssh-agent -s)" > /dev/null 2>&1
ssh-add ~/.ssh/id_ed25519 > /dev/null 2>&1
ssh-add ~/.ssh/id_ed25519_devsu > /dev/null 2>&1
ssh-add ~/.ssh/id_ed25519_andes > /dev/null 2>&1
