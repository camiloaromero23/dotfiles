# NOTE: Only works for kitty terminal

notify() {
  if [ "$#" -eq 1 ]; then
    MESSAGE=$1
    printf "\x1b]99;;$MESSAGE\x1b\\"
    return 0
  fi
  printf "\x1b]99;i=1:d=1:p=body;$MESSAGE\x1b\\"
  if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    echo ""
    echo "Usages:"
    echo "\tnotify \$MESSAGE"
    echo "\tnotify \$TITLE \$MESSAGE"
    return 1
  fi
  TITLE=$1
  MESSAGE=$2
  printf "\x1b]99;i=1:d=0;$TITLE\x1b\\"
  printf "\x1b]99;i=1:d=1:p=body;$MESSAGE\x1b\\"
}
