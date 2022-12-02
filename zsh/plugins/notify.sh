# NOTE: Only works for kitty terminal

notify() {
  MESSAGE="Process terminated"
  printf "\x1b]99;;$MESSAGE\x1b\\"
}
