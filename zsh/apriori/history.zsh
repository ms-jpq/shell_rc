#!/usr/bin/env -S -- bash

setopt -- extended_history       # Save timestamps of command
setopt -- share_history          # Share command history data, turns on `extended_history`
setopt -- hist_expire_dups_first # Delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt -- hist_fcntl_lock        # Modern history locking
setopt -- hist_ignore_dups       # Ignore duplicated commands history list
setopt -- hist_no_functions      # Ignore functions in history
setopt -- hist_no_store          # Ignore history calls from history
setopt -- hist_reduce_blanks     # Remove unneeded blanks
setopt -- hist_verify            # Show command with history expansion to user before running it

# shellcheck disable=SC2034
SAVEHIST="$HISTSIZE"

# shellcheck disable=SC2154
HISTFILE="$XDG_STATE_HOME/shell_history/zsh"
