#!/usr/bin/env -S -- bash

export -- EDITOR="${EDITOR:-nvim}"
export -- VISUAL="$EDITOR"

case "$OSTYPE" in
darwin*)
  _open=open
  ;;
msys | cygwin)
  _open=cygstart
  ;;
*)
  _open=xdg-open
  ;;
esac
export -- BROWSER="${BROWSER:-$_open}"
unset -- _open

# shellcheck disable=2154
export -- INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"
