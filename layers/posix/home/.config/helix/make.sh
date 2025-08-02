#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

DIR="${0%/*}"
PAR=1

case "${RECUR:=""}" in
'')
  MANS=(
    composer.php
    gem.rb
    npm.js
    pip.py
  )
  printf -- '%s\0' "${MANS[@]}" | RECUR=1 xargs -r -0 -n 1 -P "$PAR" -- "$0"
  ;;
1)
  read -r -d '' -- JQ <<- 'JQ' || true
.[$man] | to_entries[] | [.key] + .value | join("\n")
JQ
  MAN="$DIR/libexec/$1"
  KEY="${1%%.*}"

  jq --raw-output0 --arg man "$KEY" "$JQ" < "$DIR/procs.json" | RECUR=2 xargs -r -0 -n 1 -P "$PAR" -- "$0" "$MAN"
  ;;
2)
  MAN="$1"
  readarray -t -- PKGS <<< "$2"
  exec -- "$DIR/libexec/cond-exec.sh" "$MAN" "${PKGS[@]}"
  ;;
*)
  set -x
  exit 1
  ;;
esac
