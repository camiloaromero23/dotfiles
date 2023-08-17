chtsh() {
  CHTSH_LANG=$1
  shift

  CHTSH_ARGS=""
  if [ $# -gt 0 ]
  then
    CHTSH_ARGS=/$1
    shift
  fi

  for arg in $@
  do
    CHTSH_ARGS=$CHTSH_ARGS+$arg
  done
  CHEAT_SHEET="$CHTSH_LANG$CHTSH_ARGS"
  echo cht.sh/$CHEAT_SHEET
  if command -v bat &> /dev/null
  then
    curl -s cht.sh/$CHEAT_SHEET | bat --paging always
  else
    echo "Install bat for better output"
    curl -s cht.sh/$CHEAT_SHEET | cat
  fi
}
