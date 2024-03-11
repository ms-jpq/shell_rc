#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O globstar

set -o pipefail

SELF="${0%/*}"
BASE="$SELF/.."
BUCKET='s3://kfc-home'
S5="$BASE/var/bin/s5cmd"
TMP="$BASE/var/gpg"
GPG="$TMP/backup.gpg"

S5=("$BASE/var/bin/s5cmd")

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
    ~/.local/share/ssh
    ~/.ssh
  )

  dir
  "$SELF/s3-prep.sh" push "$TMP" "${FILES[@]}"

  BW="$BASE/node_modules/.bin/bw"
  chmod +x "$BW"
  "$BW" export --format json --raw | gpg --batch --encrypt --output "$TMP/bitwarden.json.gpg"
  gpg --export-secret-keys --export-options export-backup | gpg --batch --encrypt --output "$GPG"

  "${S5[@]}" sync --delete -- "$TMP/" "$BUCKET" | column -t
  ;;
pull)
  dir
  "${S5[@]}" cp -- "$BUCKET/*" "$TMP" | column -t
  "$SELF/s3-prep.sh" pull "$TMP" "${FILES[@]}"

  gpg --batch --decrypt -- "$GPG" | gpg --import
  ;;
rmfr)
  read -r -p '>>> (yes/no)?' -- DIE
  if [[ "$DIE" == 'yes' ]]; then
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
