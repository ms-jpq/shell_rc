#!/usr/bin/env -S -- bash

rsync --mkpath --recursive --links --keep-dirlinks --perms --times --human-readable --info progress2 -- "$@"
