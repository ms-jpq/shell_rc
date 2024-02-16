#!/usr/bin/env -S -- bash

rclone --config /dev/null --copy-links serve http --addr '[::]:8080' "$@"
