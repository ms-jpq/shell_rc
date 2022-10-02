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
  for p in "$@"
  do
    if [[ -d "$p" ]]
    then
      path=("$p" "${path[@]}")
    fi
  done
}


zsh_main() {
  local os=""
  if [[ "$OSTYPE" =~ 'darwin' ]]
  then
    os='darwin'
  else
    os='linux'
  fi
  local zrc_targets=(
    apriori
    "$os"
    shared
    tmux
    aposteriori
    fun
    docker
  )

  for target in "${zrc_targets[@]}"
  do
    local rcs="$ZDOTDIR/$target"
    local fns="$rcs/fn"

    if [[ -d "$fns" ]]
    then
      fpath=("$fns" "${fpath[@]}")
    fi

    for fn in "$fns"/**/*
    do
      autoload -Uz "$fn"
    done

    for rc in "$rcs"/**/*.zsh
    do
      source "$rc"
    done

    pathprepend "$rcs/bin"
  done

  pathprepend "$HOME/.local/bin"
}

zsh_main
unset -f zsh_main


if (( SHLVL > 1 ))
then
  PATH="$(printf '%s' "$PATH" | awk -v 'RS=:' -v 'ORS=:' '!seen[$0]++ { if (NR != 1) { print ":" } print }')"
fi
