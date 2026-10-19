#!/usr/bin/env -S -- bash

command -- mosh --family=prefer-inet6 --experimental-remote-ip=remote "$@"
