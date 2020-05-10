#################### ################# ####################
#################### Python Env Region ####################
#################### ################# ####################

export PYENV_ROOT="$XDG_CONFIG_HOME/pyenv"
if [[ "$SHLVL" -eq 1 ]]
then
  export PATH="$PYENV_ROOT/bin:$PATH"
fi
eval "$(pyenv init - --no-rehash)"


#################### ########### ####################
#################### Venv Region ####################
#################### ########### ####################

DEFAULT_VENV_PATH=".venv"

_venv_off() {
  if [[ -n "$VIRTUAL_ENV" ]]
  then
    local VENV="$VIRTUAL_ENV"
    if deactivate
    then
      echo "Deactivated - $VENV"
    else
      echo "Failed to deactivate - $VENV"
      return 1
    fi
  fi
}

_venv_on() {
  local ACTIVATE="$DEFAULT_VENV_PATH/bin/activate"
  _venv_off
  if [[ -f "$ACTIVATE" ]]
  then
    source "$ACTIVATE"
    echo "Activated - $VIRTUAL_ENV"
  else
    echo "No Virtualenv found at - $ACTIVATE"
    return 1
  fi
}

_mkvenv() {
  if [[ -d "$DEFAULT_VENV_PATH" ]]
  then
    echo "Virtualenv already initialized"
    return 1
  else
    python3 -m venv "$DEFAULT_VENV_PATH"
    echo "Initialized Virtualenv"
    _venv_on
  fi
}

venv() {
  case "$1" in
  init)
    _mkvenv
    ;;
  on)
    _venv_on
    ;;
  off)
    _venv_off
    ;;
  *)
    echo "Invalid argument"
    echo "venv - [init | on | off]"
    ;;
  esac
}


pip3() {
  if [[ -z "$VIRTUAL_ENV" ]]
  then
    echo "Not in virtualenv - require explicit:"
    echo
    echo "command pip $*"
    echo
  else
    command pip3 "$@"
  fi
}
alias pip='pip3'


#################### ############# ####################
#################### Python Region ####################
#################### ############# ####################

alias py='python3'
alias srv='python3 -m http.server'
