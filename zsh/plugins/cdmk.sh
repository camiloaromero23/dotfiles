cdmk() {
  if [ $# -ne 1 ]
  then
    echo "Usage: $0 <path to cdmk>"
    return 1
  fi

  DIRECTORY="$1"

  [ -d $DIRECTORY ] || mkdir $DIRECTORY
  cd $DIRECTORY
}
