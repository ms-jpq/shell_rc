#################### ############# ####################
#################### Python Region ####################
#################### ############# ####################

DEFAULT_VENV_PATH=".venv"

alias py='python3'


mkvenv() {
  if [[ -d "$DEFAULT_VENV_PATH" ]]
  then
    echo "Virtualenv already initialized"
  else
    python3 -m venv "$DEFAULT_VENV_PATH"
  fi
}

_venv_off() {
  if [[ ! -z "$VIRTUAL_ENV" ]]
  then
    deactivate
  fi
}

_venv_on() {
  local ACTIVATE="$DEFAULT_VENV_PATH/bin/activate"
  _venv_off
  if [[ -f "$ACTIVATE" ]]
  then
    source "$ACTIVATE"
  fi
}

venv() {
  case "$1" in
  on)
    _venv_on
    ;;
  off)
    _venv_off
    ;;
  *)
    echo "Invalid argument"
    echo "venv - [on | off]"
    ;;
  esac
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
