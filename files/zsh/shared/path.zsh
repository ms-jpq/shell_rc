#################### ########### ####################
#################### Path Region ####################
#################### ########### ####################

export PATH="$XDG_CONFIG_HOME/zsh/rc/bin:$PATH"
export PATH="$XDG_CONFIG_HOME/scripts:$PATH"
export PATH="$HOME/.local/bin:$PATH"


paths() {
  if [[ "$1" = "show" ]]
  then
    echo "$PATH" | tr ':' '\n' | awk '!seen[$0]++'
  else
    export PATH="$(command paths "$1" "$2")"
  fi
}

