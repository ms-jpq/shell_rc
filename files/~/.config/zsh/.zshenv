#################### ########## ####################
#################### ENV Region ####################
#################### ########## ####################

# XDG #
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
# XDG #

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-"/tmp/$(id -u)-runtime"}"
if [[ ! -f "$XDG_RUNTIME_DIR" ]]
then
  mkdir -p "$XDG_RUNTIME_DIR"
  chmod 700 "$XDG_RUNTIME_DIR"
fi


export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
