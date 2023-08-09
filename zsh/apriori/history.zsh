#!/usr/bin/env -S -- bash

setopt -- extended_history       # record timestamp of command in HISTFILE
setopt -- hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt -- hist_ignore_dups       # ignore duplicated commands history list
setopt -- hist_ignore_space      # ignore commands that start with space
setopt -- hist_verify            # show command with history expansion to user before running it
setopt -- append_history         # add commands to HISTFILE in order of execution
setopt -- inc_append_history     # add commands to HISTFILE immediately
setopt -- share_history          # share command history data

# shellcheck disable=SC2154
HISTFILE="$XDG_STATE_HOME/shell_history/zsh"

# shellcheck disable=SC2034
SAVEHIST=10000
