#!/usr/bin/env -S -- bash

# shellcheck disable=SC2154
cd -- "$XDG_DATA_HOME/zsh" || return 1
$EDITOR
