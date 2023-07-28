#!/usr/bin/env -S -- bash

# shellcheck disable=SC2154
rlwrap --history-no-dupes 1 --history-filename "$XDG_STATE_HOME/shell_history/perl" -- perl -CASD -w -d -e ''
