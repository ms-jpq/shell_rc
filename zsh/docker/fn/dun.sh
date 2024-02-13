#!/usr/bin/env -S -- bash

# shellcheck disable=SC2312
docker ps --all --quiet | xargs -r -- docker rm --force --
