#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ARGV=(
  "$HOME/.local/opt/pipes.sh/pipes.sh"
)

for ((i = 0; i < 10; i++)); do
  ARGV+=(-t "$i")
done

if (($#)); then
  ARGV+=("$@")
else
  ARGV+=(
    -p 9
    -f 99
    -r 9999
    -R
    # -K
  )
fi

exec -- "${ARGV[@]}"
