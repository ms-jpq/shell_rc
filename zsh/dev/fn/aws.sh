#!/usr/bin/env -S -- bash

if [[ -t 1 ]]; then
  # shellcheck disable=SC2312
  AWS_DEFAULT_OUTPUT=yaml command -- aws "$@" | bat --language yaml
else
  command -- aws "$@"
fi
