#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

PID="$1"
PPS_ID="$2"
FALLBACK="$3"

ARGV=()

case "$OSTYPE" in
darwin*)
  if LINE="$(pgrep -lf -P "$PPS_ID")"; then
    CMD="${LINE#* }"
    readarray -t -d ' ' -- ARGV < <(printf -- '%s' "$CMD")
  fi
  ;;
linux*)
  if PS_ID="$(pgrep -P "$PPS_ID")"; then
    if readarray -t -d $'\0' -- ARGV <"/proc/$PS_ID/cmdline"; then
      :
    fi
  fi
  ;;
*)
  exit 1
  ;;
esac

if ((${#ARGV[@]})); then
  printf -v AV -- '%q ' "${ARGV[@]}"
else
  AV=''
fi
printf -- '%s\n' "$PID ${AV:-"$FALLBACK"}"
