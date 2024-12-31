if ! command -v nix &> /dev/null; then
  return
fi

ZSH_AUTOSUGGESTIONS_DIR="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
ZSH_SYNTAX_HIGHLIGHTING_DIR="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

mkdir -p "$ZSH_AUTOSUGGESTIONS_DIR"
mkdir -p "$ZSH_SYNTAX_HIGHLIGHTING_DIR"

ZSH_AUTOSUGGESTIONS_PLUGIN="$ZSH_AUTOSUGGESTIONS_DIR/zsh-autosuggestions.plugin.zsh"
ZSH_SYNTAX_HIGHLIGHTING_PLUGIN="$ZSH_SYNTAX_HIGHLIGHTING_DIR/zsh-syntax-highlighting.plugin.zsh"

if [ ! -f "$ZSH_AUTOSUGGESTIONS_PLUGIN" ]; then
  ln -sf /nix/store/*-zsh-autosuggestions-*/share/zsh-autosuggestions/zsh-autosuggestions.zsh "$ZSH_AUTOSUGGESTIONS_PLUGIN"
fi

if [ ! -f "$ZSH_SYNTAX_HIGHLIGHTING_PLUGIN" ]; then
  ln -sf /nix/store/*-zsh-syntax-highlighting-*/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh "$ZSH_SYNTAX_HIGHLIGHTING_PLUGIN"
fi
