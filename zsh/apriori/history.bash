#!/usr/bin/env -S -- bash

# shellcheck disable=SC2154
HISTFILE="$XDG_STATE_HOME/shell_history/bash"
HISTCONTROL=ignoredups

shopt -s -- histappend # Append instead of replace history
shopt -s -- cmdhist    # Save multiline commands as one entry
shopt -s -- lithist    # Do not replace $'\n' with ';'
