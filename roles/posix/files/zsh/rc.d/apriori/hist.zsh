#!/usr/bin/env -S -- bash

#################### ############## ####################
#################### History Region ####################
#################### ############## ####################

setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt append_history         # add commands to HISTFILE in order of execution
setopt inc_append_history     # add commands to HISTFILE immediately
setopt share_history          # share command history data


HISTFILE="$XDG_CACHE_HOME/zsh_hist"
HISTSIZE=50000

# shellcheck disable=SC2034
SAVEHIST=10000
