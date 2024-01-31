#!/usr/bin/env -S -- bash

if (($#)); then
  networksetup "$@"
else
  networksetup -listallhardwareports
  # shellcheck disable=SC2154
  "$XDG_CONFIG_HOME/zsh/libexec/hr.sh"
  networksetup -listnetworkserviceorder
  "$XDG_CONFIG_HOME/zsh/libexec/hr.sh"
  scutil --nwi
fi
