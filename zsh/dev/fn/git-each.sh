#!/usr/bin/env -S -- bash

command -- git submodule foreach --recursive "$@"
