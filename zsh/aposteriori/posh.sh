#!/usr/bin/env -S -- bash

# shellcheck disable=SC1091
if [[ -v BASH ]]; then
  sh='bash'
else
  sh='zsh'
fi

# shellcheck disable=SC2154,SC2312
eval -- "$(oh-my-posh init "$sh" --config "$XDG_CONFIG_HOME/posh/config.yml")"
unset -- sh
