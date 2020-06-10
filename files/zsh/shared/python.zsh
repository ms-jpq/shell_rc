#################### ################# ####################
#################### Python Env Region ####################
#################### ################# ####################

export PYTHONSTARTUP="$XDG_CONFIG_HOME/pythonrc.py"


pip3() {
  if [[ -z "$VIRTUAL_ENV" ]]
  then
    echo 'Not in virtualenv - require explicit:'
    echo
    echo "command pip $*"
    echo
  else
    command pip3 "$@"
  fi
}
alias pip='pip3'


alias python='python3'
alias py='python3'
alias pd='pydoc'
alias srv='python3 -m http.server'


#################### ########### ####################
#################### Venv Region ####################
#################### ########### ####################

venv() {
  local DEFAULT_VENV_PATH=".venv"
  local ACTIVATE="$DEFAULT_VENV_PATH/bin/activate"
  case "$1" in
  init)
    if [[ -d "$DEFAULT_VENV_PATH" ]]
    then
      echo "Virtualenv already initialized"
    else
      python3 -m venv "$DEFAULT_VENV_PATH"
      echo "Initialized Virtualenv"
      venv on
    fi
    ;;
  on)
    if [[ -f "$ACTIVATE" ]]
    then
      venv off
      source "$ACTIVATE"
      echo "Activated - $VIRTUAL_ENV"
    else
      echo "No Virtualenv found at - $ACTIVATE"
    fi
    ;;
  off)
    if [[ -n "$VIRTUAL_ENV" ]]
    then
      local VENV="$VIRTUAL_ENV"
      if deactivate
      then
        echo "Deactivated - $VENV"
      else
        echo "Failed to deactivate - $VENV"
      fi
    fi
    ;;
  rm)
    if [[ -d "$DEFAULT_VENV_PATH" ]]
    then
      if [[ "$VIRTUAL_ENV" = "$DEFAULT_VENV_PATH" ]]
      then
        venv off
      fi
      command rm -rf "$DEFAULT_VENV_PATH"
      echo "Removed - $DEFAULT_VENV_PATH"
    fi
    ;;
  *)
    echo "Invalid argument"
    echo "venv - [init | on | off]"
    ;;
  esac
}

