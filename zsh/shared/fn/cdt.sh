#!/usr/bin/env -S -- bash

cd -- "$(mktemp --directory)" || return 1
if (($#)); then
  "$EDITOR" "$*"
fi