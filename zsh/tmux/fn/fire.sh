#!/usr/bin/env -S -- bash

# OSC 1337 -> iTerm Exts
# shellcheck disable=SC1003
printf -- '\e]1337;RequestAttention=fireworks\e\' | tmux-esc
