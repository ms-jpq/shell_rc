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


if (( "$SHLVL" > 1 ))
then
  PATH="$(awk -v 'RS=:' '!seen[$0]++ { if (NR != 1) { printf ":" } printf("%s", $0) }' <<< "$PATH")"
fi

