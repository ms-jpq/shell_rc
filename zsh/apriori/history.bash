#!/usr/bin/env -S -- bash

shopt -s -- cmdhist    # Save multiline commands as one entry
shopt -s -- histappend # Append instead of replace history
shopt -s -- histverify # Verify history edits
shopt -s -- lithist    # Do not replace $'\n' with ';'

HISTCONTROL=ignoredups
HISTTIMEFORMAT='%F %T '

# shellcheck disable=SC2154
HISTFILE="$(nt2unix "$XDG_STATE_HOME/shell_history/bash")"
