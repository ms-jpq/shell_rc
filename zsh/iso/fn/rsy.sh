#!/usr/bin/env -S -- bash

rsync --mkpath --recursive --links --keep-dirlinks --executability --times --human-readable --info progress2 -- "$@"
