#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPT="$HOME/.local/opt"
PYRADIO="$OPT/pyradio"
VENV="$PYRADIO/venv"

case "$OSTYPE" in
msys)
  BIN="$VENV/Scripts"
  ;;
*)
  BIN="$VENV/bin"
  ;;
esac

PY="$BIN/python"

if ! [[ -d $PYRADIO ]]; then
  REPO='coderholic/pyradio'
  TMP="$(mktemp -d)"
  LATEST="$("$OPT/initd/libexec/gh-latest.sh" "$TMP" "$REPO")"
  URI="https://github.com/coderholic/pyradio/archive/refs/tags/$LATEST.tar.gz"
  curl --fail-with-body --no-progress-meter -- "$URI" | tar -x -z -C "$TMP"
  mv -f -- "$TMP/pyradio-"* "$PYRADIO"
fi

if ! [[ -d $VENV ]]; then
  python3 -m venv --upgrade -- "$VENV"
  mkdir -v -p -- "$PYRADIO/pyradio/__pycache__"
  "$PY" -m pip install --require-virtualenv --upgrade --requirement "$PYRADIO/requirements_pipx.txt" -- "$PYRADIO"
fi

PYTHONSAFEPATH=1 exec -- "$PY" -m pyradio.main "$@"
