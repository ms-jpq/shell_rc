#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

DIR="$(dirname -- "$0")"
ROOT="$(realpath -- "$DIR/../../../../../..")"

read -r -d '' -- PY <<- 'PYTHON' || true
from json import dump
from yaml import safe_load
from sys import stdin, stdout

j = safe_load(stdin.buffer)
dump(j, stdout, ensure_ascii=False, sort_keys=True)
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
exec -- python -c "$PY"
