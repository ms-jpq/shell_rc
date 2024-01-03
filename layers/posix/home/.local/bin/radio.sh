#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OPT="$HOME/.local/opt"
PYRADIO="$OPT/pyradio"
VENV="$PYRADIO/venv"
PY="$VENV/bin/python"

if ! [[ -d "$PYRADIO" ]]; then
  REPO='coderholic/pyradio'
  TMP="$(mktemp -d)"
  LATEST="$("$OPT/initd/libexec/gh-latest.sh" "$TMP" "$REPO")"
  URI="https://github.com/coderholic/pyradio/archive/refs/tags/$LATEST.tar.gz"
  curl --fail --no-progress-meter -- "$URI" | tar -x -z -C "$TMP"
  mv -f -- "$TMP/pyradio-"* "$PYRADIO"
fi

if ! [[ -d "$VENV" ]]; then
  python3 -m venv --upgrade -- "$VENV"
  "$PY" -m pip install --require-virtualenv --upgrade --requirement "$PYRADIO/requirements_pipx.txt"
fi

PYTHONSAFEPATH=1 PYTHONPATH="$PYRADIO" exec -- "$PY" -m pyradio.main "$@"
