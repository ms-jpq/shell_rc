#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "$OSTYPE" in
darwin*)
  if ! hash -- gmake jq; then
    brew install -- make jq
  fi
  ;;
linux*)
  if ! hash -- gmake curl jq gpg git unzip || ! [[ -d /usr/share/doc/python3-venv ]] || ! [[ -f /etc/ssl/certs/ca-certificates.crt ]]; then
    PKG=(ca-certificates make curl jq gnupg git unzip python3-venv)
    sudo -- apt-get update
    sudo -- env -- DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --yes -- "${PKG[@]}"
  fi
  ;;
msys)
  PATH="/usr/bin:$PATH"
  LOCALAPPDATA="$(cygpath -- "$LOCALAPPDATA")"
  PATH="$LOCALAPPDATA/Local/Microsoft/WinGet/Links:$PATH"

  WINGET=(
    winget install
    --disable-interactivity
    --accept-source-agreements --accept-package-agreements
  )
  if ! hash -- make jq; then
    PKG=(ezwinports.make jqlang.jq)
    for PKG in "${PKG[@]}"; do
      "${WINGET[@]}" --exact --id "$PKG"
    done
  fi

  if ! python --help > /dev/null; then
    "${WINGET[@]}" python3
  fi
  ;;
*)
  exit 1
  ;;
esac
