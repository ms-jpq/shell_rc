#!/usr/bin/env -S -- bash

# shellcheck disable=SC2154
fpath=(
  "$ZDOTDIR/fn"
  /opt/homebrew/share/zsh/site-functions
  "${fpath[@]}"
)
