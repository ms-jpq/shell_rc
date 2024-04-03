#!/usr/bin/env -S -- bash

case "$OSTYPE" in
msys)
  export -- MSYSTEM="${MSYSTEM:-"MSYS"}" MSYS="${MSYS:-"winsymlinks:nativestrict"}"
  path=(/usr/bin "${path[@]}")

  export -- XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-"$LOCALAPPDATA"}"
  export -- XDG_DATA_HOME="${XDG_DATA_HOME:-"$LOCALAPPDATA"}"
  export -- XDG_STATE_HOME="${XDG_STATE_HOME:-"$LOCALAPPDATA/Temp"}"
  export -- XDG_CACHE_HOME="${XDG_CACHE_HOME:-"$LOCALAPPDATA/Temp"}"

  if [[ "$TERM" == 'tmux-256color' ]]; then
    TERM='xterm-256color'
  fi
  ;;
*)
  export -- XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-"$HOME/.config"}"
  export -- XDG_DATA_HOME="${XDG_DATA_HOME:-"$HOME/.local/share"}"
  export -- XDG_STATE_HOME="${XDG_STATE_HOME:-"$HOME/.local/state"}"
  export -- XDG_CACHE_HOME="${XDG_CACHE_HOME:-"$HOME/.cache"}"
  ;;
esac

# shellcheck disable=2034
ZDOTDIR="$XDG_CONFIG_HOME/zsh"
