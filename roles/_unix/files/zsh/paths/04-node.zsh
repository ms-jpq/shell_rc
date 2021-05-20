#!/usr/bin/env bash

#################### ########### ####################
#################### Node Region ####################
#################### ########### ####################

pathprepend "$NPM_GLOBAL_HOME/node_modules/.bin"
export NPM_GLOBAL_HOME="$XDG_DATA_HOME/npm_global"


np() {
  local modules='node_modules/.bin'
  if [[ -d "$modules" ]]
  then
    paths toggle -r "$modules"
  else
    printf '%s\n' 'RESET  -- npm PATH'
  fi
}
