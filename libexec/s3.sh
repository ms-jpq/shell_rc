#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail
shopt -u failglob

SELF="${0%/*}"
BASE="$SELF/.."
BUCKET='s3://kfc-home'
S5="$BASE/var/bin/s5cmd"
TMP="$BASE/var/gpg"
GPG="$TMP/backup.gpg"

S5=(
  "$(realpath -- "$BASE/var/bin/s5cmd")"
)

dir() {
  rm -fr -- "$TMP"
  mkdir -v -p -- "$TMP"
  chmod -v g-rwx,o-rwx "$TMP"
}

case "${1:-""}" in
'' | s3)
  "${S5[@]}" ls --humanize -- "$BUCKET/**"
  ;;
push)
  FILES=(
    ~/.config/git/config
    ~/.config/gnupg/sshcontrol
    ~/.local/secrets
    ~/.ssh
  )

  dir
  "$SELF/s3-prep.sh" push "$TMP" "${FILES[@]}"

  # BW="$BASE/node_modules/.bin/bw"
  # chmod +x "$BW"
  BW='bw'
  "$BW" export --format json --raw | gpg --batch --encrypt --output "$TMP/bitwarden.json.gpg"
  gpg --export-secret-keys --export-options export-backup | gpg --batch --encrypt --output "$GPG"

  pushd -- "$TMP"
  "${S5[@]}" sync --delete -- ./ "$BUCKET" | cut -d ' ' -f -2
  ;;
pull)
  dir
  pushd -- "$TMP"
  "${S5[@]}" cp -- "$BUCKET/*" . | cut -d ' ' -f -2
  popd
  "$SELF/s3-prep.sh" pull "$TMP" "${FILES[@]}"

  gpg --batch --decrypt -- "$GPG" | gpg --import
  ;;
rmfr)
  read -r -p '>>> (yes/no)?' -- DIE
  if [[ $DIE == 'yes' ]]; then
    "${S5[@]}" rm --all-versions -- "$BUCKET/*"
  else
    exit 130
  fi
  ;;
*)
  set -x
  exit 2
  ;;
esac
