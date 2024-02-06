#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O globstar

set -o pipefail

cd -- "${0%/*}/.."

BUCKET='s3://chumbucket-home'
S5="$PWD/var/bin/s5cmd"
TMP="./var/gpg"
GPG="$TMP/backup.gpg"

dir() (
  rm -v -fr -- "$TMP"
  mkdir -v -p -- "$TMP"
  chmod -v g-rwx,o-rwx "$TMP"
)

RSY=(
  rsync
  --mkpath
  --recursive
  --keep-dirlinks
  --links
  --keep-dirlinks
  --perms
  --times
)

case "${1:-""}" in
'')
  "$S5" ls --humanize -- "$BUCKET" | awk '{ gsub("%2F", "/", $NF); print }' | column -t
  ;;
push)
  FILES=(
    "$HOME/.config/aws/credentials"
    "$HOME/.local/share/it2/"
    "$HOME/.local/share/ssh/"
    "$HOME/.netrc"
    "$HOME/.ssh/"
  )

  dir
  for F in "${FILES[@]}"; do
    "${RSY[@]}" -- "$F" "$TMP/${F#"$HOME"}"
  done

  SECRETS=()
  for F in "$TMP"/**/*; do
    if [[ -f "$F" ]]; then
      SECRETS+=("$F")
    fi
  done
  gpg -v --batch --yes --encrypt-files -- "${SECRETS[@]}"

  for F in "${SECRETS[@]}"; do
    F="$F.gpg"
    NAME="$(jq --raw-input --raw-output '@uri' <<<"~${F#"$TMP"}")"
    mv -v -- "$F" "$TMP/$NAME"
  done
  rm -v -fr -- "${TMP:?}"/*/ "${TMP:?}"/!(*.gpg)

  gpg -v --export-secret-keys --export-options export-backup | gpg -v --batch --encrypt --output "$GPG"
  "$S5" sync --delete -- "$TMP/" "$BUCKET"
  ;;
pull)
  dir
  "$S5" cp -- "$BUCKET/*" "$TMP"
  FILES=("$TMP"/~*.gpg)
  gpg -v --batch --decrypt-files -- "${FILES[@]}"

  for F in "${FILES[@]}"; do
    F="${F%.gpg}"
    F2="${F#"$TMP/"}"
    NAME="$HOME${F2#'~'}"
    NAME="${NAME//'%2F'/'/'}"
    mv -v -f -- "$F" "$NAME"
  done

  gpg -v --batch --decrypt -- "$GPG" | gpg -v --import
  ;;
rmfr)
  read -r -p '>>> (yes/no)?' -- DIE
  if [[ "$DIE" == 'yes' ]]; then
    "$S5" rm --all-versions -- "$BUCKET/*"
  else
    exit 130
  fi
  ;;
*)
  set -x
  exit 2
  ;;
esac
