#!/usr/bin/env -S -- bash

# if (($# > 1)); then
command -- ssh "$@"
# else
#   autossh -M 0 "$@"
# fi
