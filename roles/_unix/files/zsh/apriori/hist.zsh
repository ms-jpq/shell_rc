#!/usr/bin/env bash

#################### ############## ####################
#################### History Region ####################
#################### ############## ####################

setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt inc_append_history     # add commands to HISTFILE in order of execution
setopt share_history          # share command history data


export HISTFILE="$XDG_CACHE_HOME/zsh_hist"
export HISTSIZE=50000
export SAVEHIST=10000


alias hist='history'
