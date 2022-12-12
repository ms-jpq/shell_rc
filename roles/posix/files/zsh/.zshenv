#!/usr/bin/env bash

#################### ########## ####################
#################### ENV Region ####################
#################### ########## ####################

# XDG #
if [[ "$OSTYPE" =~ 'msys' ]]
then
  local cpath=''
  cpath="$(cygpath -- "$LOCALAPPDATA")"

  export XDG_CONFIG_HOME="$cpath"
  export XDG_DATA_HOME="$cpath"

  cpath="$(cygpath -- "$TMP")"

  export XDG_STATE_HOME="$cpath"
  export XDG_CACHE_HOME="$cpath"
else
  export XDG_CONFIG_HOME="$HOME/.config"
  export XDG_DATA_HOME="$HOME/.local/share"
  export XDG_STATE_HOME="$HOME/.local/state"
  export XDG_CACHE_HOME="$HOME/.cache"
fi
# XDG #

export ZDOTDIR="$XDG_CONFIG_HOME/zsh/rc.d"
