#!/usr/bin/env -S -- bash

HISTFILE="$XDG_CACHE_HOME/bash_hist" command -- bash -O dotglob -O nullglob -O extglob -O globstar "$@"