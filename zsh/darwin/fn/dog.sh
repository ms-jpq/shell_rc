#!/usr/bin/env -S -- bash

# dns-sd -G v4v6 "$@" will honour `scutil --dns`, but will not exit automatically
dscacheutil -q host -a name "$@"
