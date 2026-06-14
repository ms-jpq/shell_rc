#!/usr/bin/env -S -- bash

if (($#)); then
  networksetup "$@"
else
  networksetup -listallhardwareports
  ~/.local/libexec/hr.sh
  networksetup -listnetworkserviceorder
  ~/.local/libexec/hr.sh
  scutil --nwi
fi
