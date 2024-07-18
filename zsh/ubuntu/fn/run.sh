#!/usr/bin/env -S -- bash

systemd-run --expand-environment no --user --scope --property LogLevelMax=notice --nice 19 "$@"
