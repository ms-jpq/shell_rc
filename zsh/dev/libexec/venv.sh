#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

VIRTUAL_ENV="${VIRTUAL_ENV:-}"

export -- DEFAULT_VENV_PATH="${DEFAULT_VENV_PATH:-"${2:-"$PWD/.venv"}"}"

PY_EXE="$DEFAULT_VENV_PATH/bin/python3"
ACTIVATE="$DEFAULT_VENV_PATH/bin/activate"

OP="$1"
shift

read -r -d '' -- PYPROJ <<-'PYTHON' || true
from itertools import chain
from pathlib import Path
from subprocess import check_call
from sys import executable
from typing import Union

from tomllib import load

pyproject = Path("pyproject.toml")


def pip(*argv: Union[str, Path]) -> None:
    check_call(
        (executable, "-m", "pip", "install", "--upgrade", "--require-virtualenv", *argv)
    )


if pyproject.is_file():
    with pyproject.open("rb") as fd:
        toml = load(fd)

    if project := toml.get("project"):
        deps = tuple(
            chain(
                project.get("dependencies", ()),
                chain.from_iterable(project.get("optional-dependencies", {}).values()),
            )
        )
        if deps:
            pip("--", *deps)

for path in Path.cwd().glob("requirements*.txt"):
    pip("--requirement", path)
PYTHON

case "$OP" in
init)
  if [[ -d "$DEFAULT_VENV_PATH" ]]; then
    printf >&2 -- '%s\n' "Virtualenv already initialized"
  else
    python3 -m venv -- "$DEFAULT_VENV_PATH" >&2
    "$PY_EXE" <<<"$PYPROJ" >&2
    printf -- '%s\n' "Initialized Virtualenv" >&2
  fi
  "$0" on
  ;;
on)
  if [[ -f "$ACTIVATE" ]]; then
    "$0" off
    printf -- '\n'
  else
    "$0" init
  fi
  printf -- '%q ' 'source' '--' "$ACTIVATE"
  printf -- '%s\n' "Activated - $DEFAULT_VENV_PATH" >&2
  ;;
off)
  if [[ -z "$VIRTUAL_ENV" ]]; then
    true
  else
    printf -- '%q ' 'deactivate'
  fi
  printf -- '%s\n' "Deactivating - $VIRTUAL_ENV" >&2
  ;;
rm)
  if [[ -d "$DEFAULT_VENV_PATH" ]]; then
    if [[ "$VIRTUAL_ENV" = "$DEFAULT_VENV_PATH" ]]; then
      "$0" off
    fi
    printf -- '%q ' 'rm' '-rf' '--' "$DEFAULT_VENV_PATH"
  fi
  printf -- '%s\n' "Removed - $DEFAULT_VENV_PATH" >&2
  ;;
*)
  printf -- '%s\n' "Invalid argument" >&2
  printf -- '%s\n' "venv - [on | off | rm]" >&2
  ;;
esac