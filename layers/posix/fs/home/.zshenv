#!/usr/bin/env -S -- bash

case "$OSTYPE" in
*msys*)
  export -- MSYSTEM='MSYS'

  cpath="$(/usr/bin/cygpath -- "$LOCALAPPDATA")"
  path=("$(/usr/bin/dirname -- "$cpath")/bin" "${path[@]}" '/ucrt64/bin' '/usr/bin')

  export -- XDG_CONFIG_HOME="$cpath"
  export -- XDG_DATA_HOME="$cpath"

  cpath="$(cygpath -- "$TMP")"

  export -- XDG_STATE_HOME="$cpath"
  export -- XDG_CACHE_HOME="$cpath"

  export -- SHELL="$(command -v -- zsh)"
  unset -- cpath
  ;;
*)
  export -- XDG_CONFIG_HOME="$HOME/.config"
  export -- XDG_DATA_HOME="$HOME/.local/share"
  export -- XDG_STATE_HOME="$HOME/.local/state"
  export -- XDG_CACHE_HOME="$HOME/.cache"
  ;;
esac

ZDOTDIR="$XDG_CONFIG_HOME/zsh"
