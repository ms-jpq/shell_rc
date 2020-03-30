#################### ############# ####################
#################### Python Region ####################
#################### ############# ####################

alias py='python3'

mkvenv() {
  local VENV_PATH=".venv"
  if [[ -d "$VENV_PATH" ]]
  then
    echo "Virtualenv already initialized"
  else
    python3 -m venv "$VENV_PATH"
  fi
}


pip3() {
  if [[ -z "$VIRTUAL_ENV" ]]
  then
    echo "Not in virtualenv - require explicit:"
    echo
    echo "command pip3 $@"
    echo
  else
    command pip3 "$@"
  fi
}
