#!/usr/bin/env -S -- bash

# shellcheck disable=SC2154
HISTFILE="$XDG_STATE_HOME/bash_hist" command -- bash -O dotglob -O nullglob -O extglob -O globstar "$@"
