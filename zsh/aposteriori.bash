#!/usr/bin/env -S -- bash

IFS=':'
# shellcheck disable=SC2154
PATH="${path[*]}"
unset -- IFS path

if [[ -f /etc/bash_completion ]]; then
  # shellcheck disable=1091
  source -- /etc/bash_completion
fi
