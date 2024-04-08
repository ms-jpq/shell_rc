#!/usr/bin/env -S -- bash

# shellcheck disable=SC2154
printf -v EDITOR -- '%q' "$XDG_CONFIG_HOME/zsh/libexec/edit.sh"
export -- EDITOR
printf -v MANPAGER -- '%q ' nvim +Man! --
export -- MANPAGER

path=(
  "$(nt2unix "$XDG_CONFIG_HOME/nvim/bin")"
  "${path[@]}"
)
