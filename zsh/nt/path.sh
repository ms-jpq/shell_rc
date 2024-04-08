#!/usr/bin/env -S -- bash

# shellcheck disable=SC2312
path=(
  "$(nt2unix "$PROGRAMFILES/Git/usr/bin")"
  "$(nt2unix "$SYSTEMDRIVE/msys64/usr/bin")"
  "${path[@]}"
)
