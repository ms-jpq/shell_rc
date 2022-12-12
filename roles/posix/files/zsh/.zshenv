#!/usr/bin/env bash

#################### ########## ####################
#################### ENV Region ####################
#################### ########## ####################

if [[ "$OSTYPE" =~ 'msys' ]]
then
  export MSYSTEM='MSYS'
  local cpath=''

  path=('/usr/bin' "${path[@]}")
  cpath="$(cygpath -- "$LOCALAPPDATA")"
  path=("$cpath/bin" '/ucrt64/bin' "${path[@]}")

  export XDG_CONFIG_HOME="$cpath"
  export XDG_DATA_HOME="$cpath"

  cpath="$(cygpath -- "$TMP")"

  export XDG_STATE_HOME="$cpath"
  export XDG_CACHE_HOME="$cpath"
else
  path=("$HOME/.local/bin" "${path[@]}")

  export XDG_CONFIG_HOME="$HOME/.config"
  export XDG_DATA_HOME="$HOME/.local/share"
  export XDG_STATE_HOME="$HOME/.local/state"
  export XDG_CACHE_HOME="$HOME/.cache"
fi


ZDOTDIR="$XDG_CONFIG_HOME/zsh/rc.d"
