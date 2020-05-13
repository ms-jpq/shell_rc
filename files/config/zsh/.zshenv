#################### ########## ####################
#################### ENV Region ####################
#################### ########## ####################

# XDG #
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
# XDG #

if [[ -z "$XDG_RUNTIME_DIR" ]]
then
  export XDG_RUNTIME_DIR="/tmp/$(id -u)-runtime"
  mkdir -p "$XDG_RUNTIME_DIR"
  chmod 700 "$XDG_RUNTIME_DIR"
fi


export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export PROMPT_EOL_MARK=""
