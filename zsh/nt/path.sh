#!/usr/bin/env -S -- bash

path=(
  "$(nt2unix "$SYSTEMDRIVE/msys64/usr/bin")"
  "${path[@]}"
)
