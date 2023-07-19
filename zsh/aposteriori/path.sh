#!/usr/bin/env -S -- bash

path=("$HOME/.local/bin" "$ZDOTDIR/bin" "${path[@]}")

if ((SHLVL > 1)); then
  PATH="$(printf -- '%s' "$PATH" | awk -v 'RS=:' -v 'ORS=' '!seen[$0]++ { if (NR != 1) { print ":"  } print $0 }')"
fi
