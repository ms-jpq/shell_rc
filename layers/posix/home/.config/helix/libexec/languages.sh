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

read -r -d '' -- PY <<- 'PYTHON' || true
from json import load
from tomli_w import dump
from sys import stdin, stdout

j = load(stdin)
dump(j, stdout.buffer)
PYTHON

PY_BIN='bin'
if [[ $OSTYPE == msys ]]; then
  PY_BIN='Scripts'
fi

PATH="$ROOT/.venv/$PY_BIN:$PATH"
export -- PYTHONIOENCODING=utf-8
tomlq -- '.' "$TOML" | "${JQ[@]}" | python -c "$PY" > "$DST"
