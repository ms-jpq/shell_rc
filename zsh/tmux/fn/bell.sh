#!/usr/bin/env -S -- bash

# OSC 9 -> Notification
# shellcheck disable=SC1003
printf -- '\e]9;%s\e\' "$*" | "${0%/*}/tmux-esc.sh"
