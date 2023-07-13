#!/usr/bin/env -S -- bash

rg --line-buffered --pretty "$@" | less || true
