#!/usr/bin/env bash

setopt nullglob

#################### ##################### ####################
#################### Instant Prompt Region ####################
#################### ##################### ####################

if [[ -r "$XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh" ]]
then
  source "$XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh"
fi


#################### ############## ####################
#################### Loading Region ####################
#################### ############## ####################

pathprepend() {
  for arg in "$@"
  do
    if [[ -d "$arg" ]]
    then
      export PATH="$arg:$PATH"
    fi
  done
}


zsh_main() {
  local os=""
  if [[ -d /Volumes ]]
  then
    os='darwin'
  else
    os='linux'
  fi
  local zrc_targets=(
    apriori
    "$os"
    shared
    paths
    aposteriori
    fun
    docker
  )

  for target in "${zrc_targets[@]}"
  do
    local rcs="$ZDOTDIR/$target"
    local fns="$rcs/fn"

    fpath=("$fns" "${fpath[@]}")
    pathprepend "$rcs/bin"

    for fn in "$fns"/**/*
    do
      autoload -Uz "$fn"
    done

    for rc in "$rcs"/**/*.zsh
    do
      source "$rc"
    done

  done

  pathprepend "$HOME/.local/bin"
}

zsh_main
unset -f zsh_main
