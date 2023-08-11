#!/usr/bin/env -S -- bash

setopt -- append_history         # Add commands to HISTFILE in order of execution
setopt -- extended_history       # Record timestamp of command in HISTFILE
setopt -- hist_expire_dups_first # Delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt -- hist_fcntl_lock        # Modern history locking
setopt -- hist_ignore_dups       # Ignore duplicated commands history list
setopt -- hist_no_functions      # Ignore functions in history
setopt -- hist_reduce_blanks     # Remove unneeded blanks
setopt -- hist_verify            # Show command with history expansion to user before running it
setopt -- inc_append_history     # Add commands to HISTFILE immediately
setopt -- share_history          # Share command history data

# shellcheck disable=SC2154
HISTFILE="$XDG_STATE_HOME/shell_history/zsh"

# shellcheck disable=SC2034
SAVEHIST=10000
