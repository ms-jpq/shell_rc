#!/usr/bin/env -S -- bash

if [[ -t 1 ]]; then
  command -- aws --output table "$@"
else
  command -- aws "$@"
fi
