#!/usr/bin/env -S -- bash

# shellcheck disable=SC2312
rg --line-buffered --pretty "$@" | less
