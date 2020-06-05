#################### ########### ####################
#################### Path Region ####################
#################### ########### ####################

export PATH="$XDG_CONFIG_HOME/zsh/rc/bin:$PATH"
export PATH="$XDG_CONFIG_HOME/scripts:$PATH"
export PATH="$HOME/.local/bin:$PATH"


paths() {
  export PATH="$(command paths "$1" "$2")"
}
