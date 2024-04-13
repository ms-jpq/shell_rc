#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

TXT="${1:-"$TXT"}"
COMMENT="${2:-"${COMMENT:-"^#"}"}"
PORT="${3:-8888}"
ADDR="${4:-"127.0.0.1"}"

if [[ -t 0 ]]; then
  export -- TXT COMMENT
  printf -- '%q ' curl -- "http://$ADDR":"$PORT"
  printf -- '\n'
  printf -- '%s%q\n' "body comment: " "$COMMENT"
  exec -- socat TCP-LISTEN:"$PORT,bind=$ADDR",reuseaddr,fork EXEC:"$0" 2>&1
fi

TX='>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
RX='<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'
EF='.....................................................................'

{
  printf -- '%s\n' "$RX"

  BYTES=0
  while read -r LINE; do
    LINE="${LINE%$'\r'}"
    printf -- '%s\n' "$LINE"
    if [[ -z "$LINE" ]]; then
      break
    fi

    LHS="${LINE%%:*}"
    case "${LHS,,}" in
    content-length)
      BYTES="${LINE##*: }"
      ;;
    *) ;;
    esac
  done
  head -c "$BYTES"
  if ((BYTES)); then
    printf -- '\n'
  fi
  printf -- '%s\n' "$TX"
} | cat -v >&2

read -r -d '' -- AWK <<-'AWK' || true
BEGIN { CMT="^#" }
/^$/ { CMT=COMMENT }
$0 !~ CMT { print $0 }
AWK

awk -v "COMMENT=$COMMENT" "$AWK" <"$TXT" | tee -- /dev/stderr
printf -- '%s\n' "$EF" >&2
