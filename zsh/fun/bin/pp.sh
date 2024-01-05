#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ARGV=(
  pipes.sh
)

for ((i = 0; i < 10; i++)); do
  ARGV+=(-t "$i")
done

if (($#)); then
  ARGV+=("$@")
else
  ARGV+=(
    -r 9999
    -p 9
  )
fi

exec -- "${ARGV[@]}"
