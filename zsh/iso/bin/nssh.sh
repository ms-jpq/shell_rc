#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

SNI="$1"
shift

printf -v PROXY -- '%q ' exec openssl s_client -quiet -connect '%h:%p' -servername "$SNI"
exec -- ssh -o ProxyCommand="$PROXY" "$@"
