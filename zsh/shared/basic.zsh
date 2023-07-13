#!/usr/bin/env -S -- bash

_less=(
  --quit-on-intr
  --quit-if-one-screen
  --mouse
  --RAW-CONTROL-CHARS
  --tilde
  --tabs=2
  --QUIET
  --ignore-case
  --no-histdups
)
export -- PAGER='less'
LESS="$(printf -- '%q ' "${_less[@]}")"
unset _less
export -- LESS
export -- LESSHISTFILE="$XDG_STATE_HOME/less-hist"

export -- TIME_STYLE='long-iso'

export -- EDITOR='editor'
export -- MANPAGER='nvim +Man! --'
