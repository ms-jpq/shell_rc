#!/usr/bin/env -S -- bash

fpath=(
  "$ZDOTDIR/fn"
  /opt/homebrew/share/zsh/site-functions
  "${fpath[@]}"
)
