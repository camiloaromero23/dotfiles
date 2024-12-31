if [ -x "$(command -v fzf)" ]
then
  if [ -n "${commands[fzf-share]}" ]; then
    source "$(fzf-share)/key-bindings.zsh"
    source "$(fzf-share)/completion.zsh"
    return
  fi
  fzf_dir=$([ "$(uname)" = "Darwin" ] && echo "/opt/homebrew/opt/fzf/shell" || echo "/usr/share/fzf")
  if [ -d "/usr/share/doc/fzf/examples" ]
  then
    fzf_dir="/usr/share/doc/fzf/examples"
  fi
  source $fzf_dir/key-bindings.zsh
  source $fzf_dir/completion.zsh
fi

