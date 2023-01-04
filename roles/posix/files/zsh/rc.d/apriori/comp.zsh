#!/usr/bin/env bash

#################### ################## ####################
#################### Completions Region ####################
#################### ################## ####################


setopt always_to_end     # move cursor to end of word
setopt auto_menu         # show completion menu on successive tab press
setopt auto_param_slash  # add trailing / to folder names

setopt noflowcontrol

setopt complete_in_word  # comp both ends of words
setopt glob_complete     # do not aggressively expand glob

setopt no_menu_complete  # do not autoselect the first completion entry


# shellcheck disable=SC2034
WORDCHARS=''


# INIT
autoload -Uz compinit
# INIT


# Case insensitive matches
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# Cache completions:
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "$XDG_CACHE_HOME/zsh_comp"


__init_zcompdump() {
  local dump="$XDG_CACHE_HOME/zcompdump-$ZSH_VERSION"
  # # zsh extended glob, based on file mod time
  local globbed=("$dump"(Nmh-6))
  if (( $#globbed ))
  then
    # found comp < 6 hours
    compinit -i -C -d "$dump"
  else
    # rebuild
    compinit -i -d "$dump"
  fi
}
__init_zcompdump
unset -f __init_zcompdump
