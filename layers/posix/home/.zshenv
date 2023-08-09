#!/usr/bin/env -S -- bash

case "$OSTYPE" in
msys)
  nt2unix() {
    local -- drive ntpath
    ntpath="$1"
    drive="${ntpath%%:*}"
    ntpath="${ntpath#*:}"
    # shellcheck disable=SC1003
    unixpath="/${drive,,}${ntpath//'\'/'/'}"
    printf -- '%s' "$unixpath"
  }

  export -- MSYSTEM='MSYS'

  # shellcheck disable=2154
  cpath="$(nt2unix "$LOCALAPPDATA")"
  path=("${cpath%/*}/bin" "${path[@]}")

  export -- XDG_CONFIG_HOME="$cpath"
  export -- XDG_DATA_HOME="$cpath"

  # shellcheck disable=2154
  cpath="$(nt2unix "$TMP")"

  export -- XDG_STATE_HOME="$cpath"
  export -- XDG_CACHE_HOME="$cpath"

  unset -- cpath
  unset -f -- nt2unix
  ;;
*)
  export -- XDG_CONFIG_HOME="$HOME/.config"
  export -- XDG_DATA_HOME="$HOME/.local/share"
  export -- XDG_STATE_HOME="$HOME/.local/state"
  export -- XDG_CACHE_HOME="$HOME/.cache"
  ;;
esac

export -- ZDOTDIR="$XDG_CONFIG_HOME/zsh"
