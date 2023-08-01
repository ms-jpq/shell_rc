#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

TMP="$1"
SEARCH="$2"
UNPACK="$3"

CURL=(
  curl
  --fail
  --location
  --no-progress-meter
  --output
)

case "$MACHTYPE" in
aarch64*)
  # THEY HAVE NO AARCH64
  ARCH=x86_64
  ;;
x86_64*)
  ARCH=x86_64
  ;;
*)
  exit 1
  ;;
esac

mkdir -v -p -- "$TMP" "$UNPACK"

HTML="$TMP/msys2.html"
REPO="https://repo.msys2.org/msys/$ARCH"

if ! [[ -f "$HTML" ]]; then
  "${CURL[@]}" "$HTML" -- "$REPO"
fi

if ! command -v -- htmlq >/dev/null; then
  HTMLQ="$TMP/htmlq.exe"
  if ! [[ -f "$HTMLQ" ]]; then
    ZIP="$TMP/htmlq.zip"
    "${CURL[@]}" "$ZIP" -- 'https://github.com/mgdm/htmlq/releases/latest/download/htmlq-x86_64-windows.zip'
    unzip -d "$TMP" "$ZIP"
    chmod +x "$HTMLQ"
  fi
else
  HTMLQ=htmlq
fi

REF="$("$HTMLQ" --attribute href -- "html > body > pre > a[href*='$SEARCH']" <"$HTML")"

readarray -t -d $'\n' -- REFS <<<"$REF"
LATEST="${REFS[$((${#REFS[@]} - 2))]}"
ARCHIVE="$TMP/${LATEST##*/}"

printf -- '%s\n' "$LATEST -> $ARCHIVE"

if ! [[ -f "$ARCHIVE" ]]; then
  "${CURL[@]}" "$ARCHIVE" -- "$REPO/$LATEST"
fi

tar -x -C "$UNPACK" -f "$ARCHIVE"