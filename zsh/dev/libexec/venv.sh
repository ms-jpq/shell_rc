#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

VIRTUAL_ENV="${VIRTUAL_ENV:-""}"

export -- DEFAULT_VENV_PATH="${DEFAULT_VENV_PATH:-"${2:-"$PWD/.venv"}"}"

case "$OSTYPE" in
msys)
  PY_EXE="$DEFAULT_VENV_PATH/Scripts/python.exe"
  ;;
*)
  PY_EXE="$DEFAULT_VENV_PATH/bin/python3"
  ;;
esac

ACTIVATE="$DEFAULT_VENV_PATH/bin/activate"

OP="$1"
shift -- 1

read -r -d '' -- PYPROJ <<-'PYTHON' || true
from collections.abc import Iterator
from itertools import chain
from os import execl
from os.path import normcase
from pathlib import Path
from shlex import quote
from sys import executable, stderr
from tomllib import load


def _argv() -> Iterator[str | Path]:
    cwd = Path.cwd()
    pyproject = cwd / "pyproject.toml"

    for path in cwd.glob("requirements*.txt"):
        yield from ("--requirement", path)
    yield "--"

    if pyproject.is_file():
        with pyproject.open("rb") as fd:
            toml = load(fd)
        project = toml.get("project", {})
        yield from project.get("dependencies", ())
        yield from chain.from_iterable(
            project.get("optional-dependencies", {}).values()
        )


argv = tuple(_argv())
print(*map(lambda s: quote(normcase(s)), argv), file=stderr)

execl(
    executable,
    executable,
    "-m",
    "pip",
    "install",
    "--upgrade",
    "--require-virtualenv",
    *argv,
)
PYTHON

case "$OP" in
on)
  if [[ -f "$ACTIVATE" ]]; then
    "$0" off
    printf -- '\n'
  else
    if ! [[ -d "$DEFAULT_VENV_PATH" ]]; then
      python3 -m venv -- "$DEFAULT_VENV_PATH" >&2
      "$PY_EXE" <<<"$PYPROJ" >&2
    fi
  fi
  printf -- '%q ' 'source' '--' "$ACTIVATE"
  printf -- '%s\n' "[x] - $DEFAULT_VENV_PATH" >&2
  ;;
off)
  if [[ -n "$VIRTUAL_ENV" ]]; then
    printf -- '%q ' 'deactivate'
    printf -- '%s\n' "[ ] - $VIRTUAL_ENV" >&2
  fi
  ;;
rm)
  if [[ -d "$DEFAULT_VENV_PATH" ]]; then
    if [[ "{VIRTUAL_ENV" == "$DEFAULT_VENV_PATH" ]]; then
      "$0" off
    fi
    printf -- '%q ' 'rm' '-rf' '--' "$DEFAULT_VENV_PATH"
  fi
  printf -- '%s\n' "[-] - $DEFAULT_VENV_PATH" >&2
  ;;
*)
  printf -- '%s\n' "${0##*/} - [on | off | rm]" >&2
  ;;
esac
