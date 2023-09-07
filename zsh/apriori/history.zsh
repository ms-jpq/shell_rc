#!/usr/bin/env -S -- bash

setopt -- share_history          # Share command history data, turns on `extended_history`
setopt -- append_history         # Add commands to HISTFILE in order of execution
setopt -- hist_expire_dups_first # Delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt -- hist_fcntl_lock        # Modern history locking
setopt -- hist_ignore_dups       # Ignore duplicated commands history list
setopt -- hist_no_functions      # Ignore functions in history
setopt -- hist_reduce_blanks     # Remove unneeded blanks
setopt -- hist_verify            # Show command with history expansion to user before running it
setopt -- inc_append_history     # Add commands to HISTFILE immediately

# shellcheck disable=SC2034
SAVEHIST=10000
