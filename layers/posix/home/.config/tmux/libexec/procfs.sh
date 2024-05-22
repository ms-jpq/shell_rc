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

    # shellcheck disable=SC1003
    for A in "${ARGV[@]}"; do
      case "$A" in
      *^* | *'\'*)
        exit
        ;;
      *) ;;
      esac
    done
  fi
  ;;
linux*)
  if PS_ID="$(pgrep -P "$PPS_ID")"; then
    if readarray -t -d '' -- ARGV < "/proc/$PS_ID/cmdline"; then
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
  AV="$FALLBACK"
fi

if "${0%/*}/whitelist.sh" "${ARGV[@]}"; then
  printf -- '%s\n' "$PID $AV"
fi
