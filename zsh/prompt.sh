#Prompt config
setopt PROMPT_SUBST

autoload colors && colors

typeset +H return_code="%(?..%F{red}%?↵%f)"

# Git configuration
autoload -Uz vcs_info

parse_git_dirty() {
  [[ -n $(git status --porcelain --untracked-files=no 2> /dev/null) ]] && echo '%F{214}*%f'
}

update_git_prompt_info () {
  git_prompt_info='%F{075}(%f%F{078}%b%f'
  git_prompt_info+=$(parse_git_dirty)
  git_prompt_info+='%F{075})%f'

  zstyle ':vcs_info:git:*' formats ${git_prompt_info}
}

# Prompt configuration
update_prompt () {
  # Dashes
  PS1='%F{237}'${(l:$COLUMNS::-:):-}'%f'
  # Actual prompt
  PS1+='%F{032}%~%f${vcs_info_msg_0_} %F{105}»%f '
  # Right prompt
  RPS1='${return_code}%F{237}%n@%m%f'
}


# Reload prompt on window resize
TRAPWINCH () {
  update_prompt
}

precmd () {
  update_git_prompt_info

  vcs_info

  update_prompt
}

