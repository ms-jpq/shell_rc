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

if [[ -n ${SSH_CONNECTION:-} ]]; then
  export -- BROWSER="$HOME/.local/libexec/ropen.sh"
else
  export -- BROWSER="${BROWSER:-$_open}"
fi
unset -- _open

# shellcheck disable=2154
export -- INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"
