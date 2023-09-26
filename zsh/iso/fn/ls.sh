#!/usr/bin/env -S -- bash

if command -v -- eza >/dev/null; then
  eza --all --group-directories-first --classify --header --icons "$@"
else
  command -- ls --almost-all --group-directories-first --classify --human-readable --si --color=auto "$@"
fi
