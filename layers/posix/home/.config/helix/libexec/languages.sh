#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

DIR="$(realpath -- "$0")"
DIR="$(dirname -- "$DIR")"
PARENT="$(dirname -- "$DIR")"

DST="$PARENT/languages.toml"
ROOT="$(realpath -- "$PARENT/../../../../..")"
TOML="$ROOT/var/helix.lang.toml"

JQ=(
  jq
  --exit-status
  --from-file "$DIR/languages.jq"
  --slurpfile user "$PARENT/languages.json"
)

read -r -d '' -- PY1 <<- 'PYTHON' || true
from json import dump
from tomli import load
from sys import stdin, stdout

j = load(stdin.buffer)
dump(j, stdout, ensure_ascii=False, sort_keys=True)
PYTHON

read -r -d '' -- PY2 <<- 'PYTHON' || true
from json import load
from tomli_w import dump
from sys import stdin, stdout

j = load(stdin)
dump(j, stdout.buffer)
PYTHON

PY_BIN='bin'
case "$OSTYPE" in
msys | cygwin)
  PY_BIN='Scripts'
  ;;
*) ;;
esac

export -- PYTHONIOENCODING=utf-8
PATH="$ROOT/.venv/$PY_BIN:$PATH"
python -c "$PY1" < "$TOML" | "${JQ[@]}" | python -c "$PY2" > "$DST"
