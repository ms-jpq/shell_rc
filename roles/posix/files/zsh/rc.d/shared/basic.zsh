#!/usr/bin/env bash

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
export PAGER='less'
export LESS="${_less[*]}"
export LESSHISTFILE="$XDG_CACHE_HOME/less-hist"
unset _less

export TIME_STYLE='long-iso'

export EDITOR='nvim'
export MANPAGER='nvim +Man!'
