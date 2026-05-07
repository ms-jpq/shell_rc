#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

DIR="$(realpath -- "$0")"
DIR="$(dirname -- "$DIR")"
PAR="${PAR:=0}"
TIMEOUT=$((60 * 15))
read -r -d '' -- PYTHON <<- 'PYTHON' || true
from subprocess import check_call
from sys import argv

_, timeout, *args = argv

check_call(("env", "--", *args), timeout=float(timeout))
PYTHON

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
    [pack]=pack.sh
    [phar]=phar.php
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
  MAN="${1%$'\r'}"
  readarray -t -- PKGS <<< "${2/$'\r'/""}"
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

  case "$OSTYPE" in
  linux* | darwin*)
    TMPDIR="/var/tmp/helix-rt"
    ;;
  msys | cygwin)
    # shellcheck disable=SC2154
    TMPDIR="$TEMP/helix-rt/var"
    ;;
  *)
    set -v
    exit 1
    ;;
  esac
  export -- TMPDIR TMP="$TMPDIR" TEMP="$TMPDIR" PERL_UNICODE=ASD
  mkdir -v -p -- "$TMPDIR"

  LIBEXEC="$DIR/libexec"
  PATH="$LIBEXEC:$HOME/.local/opt/initd/libexec:$PATH"
  ARGV=()
  case "$OSTYPE" in
  linux* | darwin*)
    if ! [[ -v CI ]]; then
      ARGV+=(
        nice
        -n 19
        --
        ~/.local/opt/sandbox/libexec/dispatch.sh
        --auth
        --network
        --dir "$PWD"
        --
      )
    fi
    ;;
  msys | cygwin)
    ARGV+=(
      python
      -c "$PYTHON"
      "$TIMEOUT"
    )
    ;;
  *)
    set -v
    exit 1
    ;;
  esac
  ARGV+=(
    "$LIBEXEC/cond-exec.sh" "$MAN"
    "${PKGS[@]}"
  )
  CODE=0
  "${ARGV[@]}" || CODE="$?"
  if ((CODE)); then
    NOW="$(date -- '+%y-%m-%d %H:%M:%S')"
    RT="$HOME/.cache/helix-rt"
    mkdir -p -- "$RT"
    printf -- '%s\n' "!!! $NOW - $PKG \$?=$CODE" | tee -a -- "$RT/failed.log" >&2
  fi
  exit "$CODE"
  ;;
*)
  set -v
  exit 1
  ;;
esac
