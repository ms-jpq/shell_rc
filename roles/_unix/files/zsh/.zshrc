#!/usr/bin/env bash

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
    # && [[ ":$PATH:" != *":$arg:"* ]]
    if [[ -d "$arg" ]]
    then
      export PATH="$arg:$PATH"
    fi
  done
}


zsh_main() {
  local zrc_targets=(
    apriori
    "$(uname | tr '[:upper:]' '[:lower:]')"
    shared
    paths
    fun
    aposteriori
  )

  for target in "${zrc_targets[@]}"
  do
    local rcs="$XDG_CONFIG_HOME/zsh/rc/$target"
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
