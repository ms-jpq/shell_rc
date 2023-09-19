#!/usr/bin/env -S -- bash

rsync --mkpath --recursive --keep-dirlinks --links --keep-dirlinks --perms --times --human-readable --info progress2 -- "$@"
