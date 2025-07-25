#!/usr/bin/env -S -- bash

path=(
  # shellcheck disable=2154
  "$XDG_CONFIG_HOME/helix/bin"
  "$HOME/.local/opt/qemu/bin"
  "$HOME/.local/opt/ai/bin"
  "${path[@]}"
)
