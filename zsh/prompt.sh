#TODO: Fix dirty repo prompt
#Prompt config
setopt PROMPT_SUBST

autoload colors && colors

# Git configuration
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git svn
git_prompt_info='%F{075}(%f%F{078}%b%f'
git_prompt_info+=${parse_git_dirty}
git_prompt_info+='%F{075})%f'
zstyle ':vcs_info:git:*' formats ${git_prompt_info}

precmd () { vcs_info }

parse_git_dirty() {
  [[ -n $(git status --porcelain --untracked-files=no 2> /dev/null) ]] && echo '%F{214}*%f'
}

typeset +H return_code="%(?..%{$fg[red]%}%?↵%{$reset_color%})"

# Dashes
PS1='%F{237}'$(printf '-%.0s' {1..${COLUMNS}})'%f'
# Actual prompt
PS1+='%F{032}%~%f${vcs_info_msg_0_} %F{105}»%f '
# Right prompt
RPS1='${return_code}%F{237}%n@%m%f'
