#!/usr/bin/env -S -- bash

printf -v MANPAGER -- '%q ' nvim +Man! --
export -- MANPAGER

path=(
  "$(nt2unix "$XDG_CONFIG_HOME/nvim/bin")"
  "${path[@]}"
)
