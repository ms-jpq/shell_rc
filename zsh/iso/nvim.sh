#!/usr/bin/env -S -- bash

printf -v MANPAGER -- '%q ' nvim +Man! --
export -- MANPAGER

# shellcheck disable=SC2154
path=(
  "$(nt2unix "$XDG_CONFIG_HOME/nvim/bin")"
  "${path[@]}"
)
