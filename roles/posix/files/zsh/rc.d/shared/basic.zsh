#!/usr/bin/env -S -- bash

#################### ########### ####################
#################### Core Region ####################
#################### ########### ####################

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
LESS="$(join "${_less[@]}")"
unset _less
export -- LESS
export -- LESSHISTFILE="$XDG_CACHE_HOME/less-hist"

export -- TIME_STYLE='long-iso'

export -- EDITOR='nvim'
export -- MANPAGER='nvim +Man!'
