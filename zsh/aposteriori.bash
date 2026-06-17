#!/usr/bin/env -S -- bash

for _sh in ~/.local/lprofile.d/*.bash; do
  # shellcheck disable=SC1090
  source -- "$_sh"
done

IFS=':'
# shellcheck disable=SC2154
PATH="${path[*]}"
unset -- IFS path

if [[ -f /etc/bash_completion ]]; then
  # shellcheck disable=1091
  source -- /etc/bash_completion
fi
