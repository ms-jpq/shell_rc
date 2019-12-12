#################### ############# ####################
#################### Python Region ####################
#################### ############# ####################


alias py='python3'


pip3() {
  if [[ -z "$VIRTUAL_ENV" ]]
  then
    echo "Not in virtualenv - require explicit:"
    echo
    echo "command pip3"
    echo
  else
    command pip3 "$@"
  fi
}
