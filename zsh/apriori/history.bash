#!/usr/bin/env -S -- bash

HISTCONTROL=ignoredups

shopt -s -- cmdhist    # Save multiline commands as one entry
shopt -s -- histappend # Append instead of replace history
shopt -s -- histverify # Verify history edits
shopt -s -- lithist    # Do not replace $'\n' with ';'
