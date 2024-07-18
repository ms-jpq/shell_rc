#!/usr/bin/env -S -- bash

systemd-run --user --scope --nice 19 "$@"
