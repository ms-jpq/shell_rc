#!/usr/bin/env -S -- bash

systemd-run --expand-environment no --collect --user --scope --property CPUWeight=69 --nice 19 "$@"
