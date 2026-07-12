#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SH=(
  bash
  -c
  "$(< /dev/stdin)"
)

printf -- '%s' "${SH[*]@Q}"
