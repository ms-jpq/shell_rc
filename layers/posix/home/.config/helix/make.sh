#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

DIR="$(dirname -- "$0")"
PAR=0

case "${RECUR:=""}" in
'')
  declare -A -- MANS
  MANS=(
    [$]=install.sh
    [composer]=composer.php
    [dotnet]=dotnet-tools.fsx
    [gem]=gem.rb
    [go]=go.go
    [npm]=npm.js
    [pip]=pip.py
  )
  for KEY in "${!MANS[@]}"; do
    printf -- '%s\0' "$KEY" "${MANS["$KEY"]}"
  done | RECUR=1 xargs -r -0 -n 2 -P "$PAR" -- "$0"
  ;;
1)
  read -r -d '' -- JQ <<- 'JQ' || true
.[$man] | to_entries[] | [.key] + .value | join("\n")
JQ
  KEY="$1"
  MAN="$DIR/libexec/$2"

  jq --raw-output0 --arg man "$KEY" "$JQ" < "$DIR/procs.json" | RECUR=2 xargs -r -0 -n 1 -P "$PAR" -- "$0" "$MAN"
  ;;
2)
  MAN="$1"
  readarray -t -- PKGS <<< "$2"
  PKG="${PKGS[0]:=""}"

  if [[ -n ${PATCH:=""} ]]; then
    # shellcheck disable=SC2254
    case "$PKG" in
    $PATCH) ;;
    *)
      exit
      ;;
    esac
  fi

  exec -- "$DIR/libexec/cond-exec.sh" "$MAN" "${PKGS[@]}"
  ;;
*)
  set -x
  exit 1
  ;;
esac
