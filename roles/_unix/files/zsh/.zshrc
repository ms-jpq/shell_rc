#!/usr/bin/env bash

setopt nullglob

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
  local os=''
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

  pathprepend "$HOME/.local/bin"

  for target in "${zrc_targets[@]}"
  do
    local rcs="$ZDOTDIR/$target"
    local fns="$rcs/fn"

    if [[ -d "$fns" ]]
    then
      fpath=("$fns" "${fpath[@]}")

      for fn in "$fns"/**/*
      do
        autoload -Uz "$fn"
      done
    fi

    for rc in "$rcs"/**/*.zsh
    do
      source "$rc"
    done

    pathprepend "$rcs/bin"
  done
}

zsh_main
unset -f zsh_main


if (( SHLVL > 1 ))
then
  PATH="$(printf '%s' "$PATH" | awk -v 'RS=:' -v 'ORS=:' '!seen[$0]++ { if (NR != 1) { print ":" } print }')"
fi
