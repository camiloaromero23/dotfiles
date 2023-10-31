if [ -x "$(command -v fzf)" ]
then
  fzf_dir=$([ "$(uname)" = "Darwin" ] && echo "/opt/homebrew/opt/fzf/shell" || echo "/usr/share/fzf/")
  source $fzf_dir/key-bindings.zsh
  source $fzf_dir/completion.zsh
fi
