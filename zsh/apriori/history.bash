#!/usr/bin/env -S -- bash

# shellcheck disable=SC2154
HISTFILE="$XDG_STATE_HOME/shell_history/bash"
HISTCONTROL=ignoredups

shopt -s -- histappend
