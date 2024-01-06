#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O globstar

set -o pipefail

SOCKS=("${0%/*}/../var/lib"/*/qmp.sock)
BOTTOM=60022
PORT=$((BOTTOM + ${#SOCKS[@]}))
printf -- '%s' $((PORT))
