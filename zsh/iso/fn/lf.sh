#!/usr/bin/env -S -- bash

if [[ -v LF_LEVEL ]]; then
  exit
else
  command -- lf "$@"
fi
