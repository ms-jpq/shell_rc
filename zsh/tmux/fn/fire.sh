#!/usr/bin/env -S -- bash

# OSC 1337 -> iTerm Exts
# shellcheck disable=SC1003
printf -- '\e]1337;RequestAttention=fireworks\e\' | "${0%/*}/tmux-esc.sh"
