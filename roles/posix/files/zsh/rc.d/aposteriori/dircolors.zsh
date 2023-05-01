#!/usr/bin/env -S -- bash

#################### ############## ####################
#################### LSCOLOR Region ####################
#################### ############## ####################

zsh_colours() {
  local -- colour="$*"
  local -- colours="$XDG_CACHE_HOME/$colour"

  if [[ ! -f "$colours" ]]; then
    dircolors --bourne-shell -- "$XDG_CONFIG_HOME/zsh/dircolors-solarized/$colour" >"$colours"
  fi

  # shellcheck disable=SC1090
  source -- "$colours"
}

zsh_colours 'dircolors.256dark'
# dircolors.ansi-dark
unset -f zsh_colours
