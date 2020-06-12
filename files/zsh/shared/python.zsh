#################### ################# ####################
#################### Python Env Region ####################
#################### ################# ####################

export PYTHONSTARTUP="$XDG_CONFIG_HOME/pythonrc.py"

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
      printf '%s\n' "Virtualenv already initialized"
    else
      python3 -m venv "$DEFAULT_VENV_PATH"
      printf '%s\n' "Initialized Virtualenv"
      venv on
    fi
    ;;
  on)
    if [[ -f "$ACTIVATE" ]]
    then
      venv off
      source "$ACTIVATE"
      printf '%s\n' "Activated - $VIRTUAL_ENV"
    else
      printf '%s\n' "No Virtualenv found at - $ACTIVATE"
    fi
    ;;
  off)
    if [[ -n "$VIRTUAL_ENV" ]]
    then
      local VENV="$VIRTUAL_ENV"
      if deactivate
      then
        printf '%s\n' "Deactivated - $VENV"
      else
        printf '%s\n' "Failed to deactivate - $VENV"
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
      printf '%s\n' "Removed - $DEFAULT_VENV_PATH"
    fi
    ;;
  *)
    printf '%s\n' "Invalid argument"
    printf '%s\n' "venv - [init | on | off]"
    ;;
  esac
}

