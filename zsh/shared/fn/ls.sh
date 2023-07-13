#!/usr/bin/env -S -- bash

if command -v -- exa >/dev/null; then
  exa --all --group-directories-first --classify --header --icons "$@"
else
  command -- ls --almost-all --group-directories-first --classify --human-readable --si --color=auto "$@"
fi