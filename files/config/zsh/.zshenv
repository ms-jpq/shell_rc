#################### ########## ####################
#################### ENV Region ####################
#################### ########## ####################

# XDG #
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_RUNTIME_DIR="/tmp/$(id -u)-runtime"
mkdir -p "$XDG_RUNTIME_DIR"
# XDG #


export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export PROMPT_EOL_MARK=""
