# Generated from oh-my-zsh git plugin aliases
# Source: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git
# File: plugins/git/git.plugin.zsh

function git_current_branch
  command git symbolic-ref --quiet --short HEAD 2>/dev/null; or command git rev-parse --short HEAD 2>/dev/null
end

function _git_log_prettily
  if test (count $argv) -ge 1
    command git log --pretty=$argv[1]
  end
end

function git_develop_branch
  command git rev-parse --git-dir >/dev/null 2>&1; or return 1
  for branch in dev devel develop development
    command git show-ref -q --verify refs/heads/$branch; and echo $branch; and return 0
  end
  echo develop
  return 1
end

function git_main_branch
  command git rev-parse --git-dir >/dev/null 2>&1; or return 1
  set -l refs refs/heads/main refs/heads/trunk refs/heads/mainline refs/heads/default refs/heads/stable refs/heads/master
  set -a refs refs/remotes/origin/main refs/remotes/origin/trunk refs/remotes/origin/mainline refs/remotes/origin/default refs/remotes/origin/stable refs/remotes/origin/master
  set -a refs refs/remotes/upstream/main refs/remotes/upstream/trunk refs/remotes/upstream/mainline refs/remotes/upstream/default refs/remotes/upstream/stable refs/remotes/upstream/master
  for ref in $refs
    if command git show-ref -q --verify $ref
      echo (string split -r -m1 / -- $ref)[-1]
      return 0
    end
  end
  for remote in origin upstream
    set -l ref (command git rev-parse --abbrev-ref $remote/HEAD 2>/dev/null)
    if string match -qr "^$remote/" -- $ref
      echo (string replace "$remote/" "" -- $ref)
      return 0
    end
  end
  echo master
  return 1
end

function gtl
  set -l prefix ""
  if test (count $argv) -ge 1
    set prefix "$argv[1]*"
  end
  command git tag --sort=-v:refname -n --list $prefix
end

function ggu
  set -l branch (git_current_branch)
  if test (count $argv) -eq 1
    set branch $argv[1]
  end
  command git pull --rebase origin $branch
end

status is-interactive; or return

abbr -ag -- g 'git'
abbr -ag -- ga 'git add'
abbr -ag -- gaa 'git add --all'
abbr -ag -- gam 'git am'
abbr -ag -- gama 'git am --abort'
abbr -ag -- gamc 'git am --continue'
abbr -ag -- gams 'git am --skip'
abbr -ag -- gamscp 'git am --show-current-patch'
abbr -ag -- gap 'git apply'
abbr -ag -- gapa 'git add --patch'
abbr -ag -- gapt 'git apply --3way'
abbr -ag -- gau 'git add --update'
abbr -ag -- gav 'git add --verbose'
abbr -ag -- gb 'git branch'
abbr -ag -- gbD 'git branch --delete --force'
abbr -ag -- gba 'git branch --all'
abbr -ag -- gbd 'git branch --delete'
abbr -ag -- gbg 'LANG=C git branch -vv | grep ": gone\]"'
abbr -ag -- gbgD 'LANG=C git branch --no-color -vv | grep ": gone]" | cut -c 3- | awk \'{print $1}\' | xargs git branch -D'
abbr -ag -- gbgd 'LANG=C git branch --no-color -vv | grep ": gone]" | cut -c 3- | awk \'{print $1}\' | xargs git branch -d'
abbr -ag -- gbl 'git blame -w'
abbr -ag -- gbm 'git branch --move'
abbr -ag -- gbnm 'git branch --no-merged'
abbr -ag -- gbr 'git branch --remote'
abbr -ag -- gbs 'git bisect'
abbr -ag -- gbsb 'git bisect bad'
abbr -ag -- gbsg 'git bisect good'
abbr -ag -- gbsn 'git bisect new'
abbr -ag -- gbso 'git bisect old'
abbr -ag -- gbsr 'git bisect reset'
abbr -ag -- gbss 'git bisect start'
abbr -ag -- gc 'git commit --verbose'
abbr -ag -- gc! 'git commit --verbose --amend'
abbr -ag -- gcB 'git checkout -B'
abbr -ag -- gca 'git commit --verbose --all'
abbr -ag -- gca! 'git commit --verbose --all --amend'
abbr -ag -- gcam 'git commit --all --message'
abbr -ag -- gcan! 'git commit --verbose --all --no-edit --amend'
abbr -ag -- gcann! 'git commit --verbose --all --date=now --no-edit --amend'
abbr -ag -- gcans! 'git commit --verbose --all --signoff --no-edit --amend'
abbr -ag -- gcas 'git commit --all --signoff'
abbr -ag -- gcasm 'git commit --all --signoff --message'
abbr -ag -- gcb 'git checkout -b'
abbr -ag -- gcd 'git checkout (git_develop_branch)'
abbr -ag -- gcf 'git config --list'
abbr -ag -- gcfu 'git commit --fixup'
abbr -ag -- gcl 'git clone --recurse-submodules'
abbr -ag -- gclean 'git clean --interactive -d'
abbr -ag -- gclf 'git clone --recursive --shallow-submodules --filter=blob:none --also-filter-submodules'
abbr -ag -- gcm 'git checkout (git_main_branch)'
abbr -ag -- gcmsg 'git commit --message'
abbr -ag -- gcn 'git commit --verbose --no-edit'
abbr -ag -- gcn! 'git commit --verbose --no-edit --amend'
abbr -ag -- gco 'git checkout'
abbr -ag -- gcor 'git checkout --recurse-submodules'
abbr -ag -- gcount 'git shortlog --summary --numbered'
abbr -ag -- gcp 'git cherry-pick'
abbr -ag -- gcpa 'git cherry-pick --abort'
abbr -ag -- gcpc 'git cherry-pick --continue'
abbr -ag -- gcs 'git commit --gpg-sign'
abbr -ag -- gcsm 'git commit --signoff --message'
abbr -ag -- gcss 'git commit --gpg-sign --signoff'
abbr -ag -- gcssm 'git commit --gpg-sign --signoff --message'
abbr -ag -- gd 'git diff'
abbr -ag -- gdca 'git diff --cached'
abbr -ag -- gdct 'git describe --tags (git rev-list --tags --max-count=1)'
abbr -ag -- gdcw 'git diff --cached --word-diff'
abbr -ag -- gds 'git diff --staged'
abbr -ag -- gdt 'git diff-tree --no-commit-id --name-only -r'
abbr -ag -- gdup 'git diff @{upstream}'
abbr -ag -- gdw 'git diff --word-diff'
abbr -ag -- gf 'git fetch'
abbr -ag -- gfa 'git fetch --all --tags --prune --jobs=10; or git fetch --all --tags --prune'
abbr -ag -- gfg 'git ls-files | grep'
abbr -ag -- gfo 'git fetch origin'
abbr -ag -- gg 'git gui citool'
abbr -ag -- gga 'git gui citool --amend'
abbr -ag -- ggpull 'git pull origin (git_current_branch)'
abbr -ag -- ggpur 'git pull --rebase origin (git_current_branch)'
abbr -ag -- ggpush 'git push origin (git_current_branch)'
abbr -ag -- ggsup 'git branch --set-upstream-to=origin/(git_current_branch)'
abbr -ag -- ghh 'git help'
abbr -ag -- gignore 'git update-index --assume-unchanged'
abbr -ag -- gignored 'git ls-files -v | grep "^[[:lower:]]"'
abbr -ag -- git-svn-dcommit-push 'git svn dcommit && git push github (git_main_branch):svntrunk'
abbr -ag -- gk 'command gitk --all --branches & disown'
abbr -ag -- gke 'command gitk --all (git log --walk-reflogs --pretty=%h) & disown'
abbr -ag -- gl 'git pull'
abbr -ag -- glg 'git log --stat'
abbr -ag -- glgg 'git log --graph'
abbr -ag -- glgga 'git log --graph --decorate --all'
abbr -ag -- glgm 'git log --graph --max-count=10'
abbr -ag -- glgp 'git log --stat --patch'
abbr -ag -- glo 'git log --oneline --decorate'
abbr -ag -- glod 'git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"'
abbr -ag -- glods 'git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset" --date=short'
abbr -ag -- glog 'git log --oneline --decorate --graph'
abbr -ag -- gloga 'git log --oneline --decorate --graph --all'
abbr -ag -- glol 'git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
abbr -ag -- glola 'git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
abbr -ag -- glols 'git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'
abbr -ag -- glp '_git_log_prettily'
abbr -ag -- gluc 'git pull upstream (git_current_branch)'
abbr -ag -- glum 'git pull upstream (git_main_branch)'
abbr -ag -- gm 'git merge'
abbr -ag -- gma 'git merge --abort'
abbr -ag -- gmc 'git merge --continue'
abbr -ag -- gmff 'git merge --ff-only'
abbr -ag -- gmom 'git merge origin/(git_main_branch)'
abbr -ag -- gms 'git merge --squash'
abbr -ag -- gmtl 'git mergetool --no-prompt'
abbr -ag -- gmtlvim 'git mergetool --no-prompt --tool=vimdiff'
abbr -ag -- gmum 'git merge upstream/(git_main_branch)'
abbr -ag -- gp 'git push'
abbr -ag -- gpd 'git push --dry-run'
abbr -ag -- gpf 'git push --force-with-lease --force-if-includes; or git push --force-with-lease'
abbr -ag -- gpf! 'git push --force'
abbr -ag -- gpoat 'git push origin --all && git push origin --tags'
abbr -ag -- gpod 'git push origin --delete'
abbr -ag -- gpr 'git pull --rebase'
abbr -ag -- gpra 'git pull --rebase --autostash'
abbr -ag -- gprav 'git pull --rebase --autostash -v'
abbr -ag -- gpristine 'git reset --hard && git clean --force -dfx'
abbr -ag -- gprom 'git pull --rebase origin (git_main_branch)'
abbr -ag -- gpromi 'git pull --rebase=interactive origin (git_main_branch)'
abbr -ag -- gprum 'git pull --rebase upstream (git_main_branch)'
abbr -ag -- gprumi 'git pull --rebase=interactive upstream (git_main_branch)'
abbr -ag -- gprv 'git pull --rebase -v'
abbr -ag -- gpsup 'git push --set-upstream origin (git_current_branch)'
abbr -ag -- gpsupf 'git push --set-upstream origin (git_current_branch) --force-with-lease --force-if-includes; or git push --set-upstream origin (git_current_branch) --force-with-lease'
abbr -ag -- gpu 'git push upstream'
abbr -ag -- gpv 'git push --verbose'
abbr -ag -- gr 'git remote'
abbr -ag -- gra 'git remote add'
abbr -ag -- grb 'git rebase'
abbr -ag -- grba 'git rebase --abort'
abbr -ag -- grbc 'git rebase --continue'
abbr -ag -- grbd 'git rebase (git_develop_branch)'
abbr -ag -- grbi 'git rebase --interactive'
abbr -ag -- grbm 'git rebase (git_main_branch)'
abbr -ag -- grbo 'git rebase --onto'
abbr -ag -- grbom 'git rebase origin/(git_main_branch)'
abbr -ag -- grbs 'git rebase --skip'
abbr -ag -- grbum 'git rebase upstream/(git_main_branch)'
abbr -ag -- grev 'git revert'
abbr -ag -- greva 'git revert --abort'
abbr -ag -- grevc 'git revert --continue'
abbr -ag -- grf 'git reflog'
abbr -ag -- grh 'git reset'
abbr -ag -- grhh 'git reset --hard'
abbr -ag -- grhk 'git reset --keep'
abbr -ag -- grhs 'git reset --soft'
abbr -ag -- grm 'git rm'
abbr -ag -- grmc 'git rm --cached'
abbr -ag -- grmv 'git remote rename'
abbr -ag -- groh 'git reset origin/(git_current_branch) --hard'
abbr -ag -- grrm 'git remote remove'
abbr -ag -- grs 'git restore'
abbr -ag -- grset 'git remote set-url'
abbr -ag -- grss 'git restore --source'
abbr -ag -- grst 'git restore --staged'
abbr -ag -- grt 'cd (git rev-parse --show-toplevel; or echo .)'
abbr -ag -- gru 'git reset --'
abbr -ag -- grup 'git remote update'
abbr -ag -- grv 'git remote --verbose'
abbr -ag -- gsb 'git status --short --branch'
abbr -ag -- gsd 'git svn dcommit'
abbr -ag -- gsh 'git show'
abbr -ag -- gsi 'git submodule init'
abbr -ag -- gsps 'git show --pretty=short --show-signature'
abbr -ag -- gsr 'git svn rebase'
abbr -ag -- gss 'git status --short'
abbr -ag -- gst 'git status'
abbr -ag -- gsta 'git stash push; or git stash save'
abbr -ag -- gstaa 'git stash apply'
abbr -ag -- gstall 'git stash --all'
abbr -ag -- gstc 'git stash clear'
abbr -ag -- gstd 'git stash drop'
abbr -ag -- gstl 'git stash list'
abbr -ag -- gstp 'git stash pop'
abbr -ag -- gsts 'git stash show --patch'
abbr -ag -- gstu 'git stash push --include-untracked; or git stash save --include-untracked'
abbr -ag -- gsu 'git submodule update'
abbr -ag -- gsw 'git switch'
abbr -ag -- gswc 'git switch --create'
abbr -ag -- gswd 'git switch (git_develop_branch)'
abbr -ag -- gswm 'git switch (git_main_branch)'
abbr -ag -- gta 'git tag --annotate'
abbr -ag -- gts 'git tag --sign'
abbr -ag -- gtv 'git tag | sort -V'
abbr -ag -- gunignore 'git update-index --no-assume-unchanged'
abbr -ag -- gunwip 'git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1'
abbr -ag -- gwch 'git log --patch --abbrev-commit --pretty=medium --raw'
abbr -ag -- gwip 'git add -A; git rm (git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'
abbr -ag -- gwipe 'git reset --hard && git clean --force -df'
abbr -ag -- gwt 'git worktree'
abbr -ag -- gwta 'git worktree add'
abbr -ag -- gwtls 'git worktree list'
abbr -ag -- gwtmv 'git worktree move'
abbr -ag -- gwtrm 'git worktree remove'
