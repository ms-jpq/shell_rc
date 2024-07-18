#!/usr/bin/env -S -- bash

systemd-run --user --scope --property LogLevelMax=notice --nice 19 "$@"
