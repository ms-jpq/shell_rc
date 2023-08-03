#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "$OSTYPE" in
msys*)
  printf -v HOMIE -- '%s' ~
  printf -- '%s' "${HOMIE#"$SYSTEMDRIVE"}"
  ;;
*)
  printf -- '%s' ~
  ;;
esac
