#!/usr/bin/env -S -- bash

if [[ -t 1 ]]; then
  AWS_DEFAULT_OUTPUT=table command -- aws "$@"
else
  command -- aws "$@"
fi
