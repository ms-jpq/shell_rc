#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail
shopt -u failglob

SELF="${0%/*}"
BASE="$SELF/.."
BUCKET='s3://kfc-home'
TMP="$BASE/var/gpg"
GPG="$TMP/backup.gpg"

S3HOST='s3.ca-west-1.amazonaws.com'
export -- AWS_SHARED_CREDENTIALS_FILE="$HOME/.config/aws/credentials"
S3=(
  "$(realpath -- "$BASE/.venv/bin/s3cmd")"
  --no-guess-mime-type
  --no-mime-magic
  --delete-after
  --host "$S3HOST"
  --host-bucket "%(bucket).$S3HOST"
)

dir() {
  rm -fr -- "$TMP"
  mkdir -v -p -- "$TMP"
  chmod -v g-rwx,o-rwx "$TMP"
}

FILES=(
  ~/.config/aerc/accounts.conf
  ~/.config/git/config
  ~/.config/isyncrc
  ~/.gnupg/sshcontrol
  ~/.local/secrets
  ~/.ssh/!(known_hosts|agent)
)

case "${1:-}" in
'' | s3 | ls)
  "${S3[@]}" ls --recursive --human-readable-sizes -- "$BUCKET"
  ;;
push)

  dir
  "$SELF/s3-prep.sh" push "$TMP" "${FILES[@]}"

  BW="bw"
  "$BW" export --format json --raw | gpg --batch --encrypt --output "$TMP/bitwarden.json.gpg"
  gpg --export-secret-keys --export-options export-backup | gpg --batch --encrypt --output "$GPG"

  pushd -- "$TMP"
  "${S3[@]}" sync --delete-removed -- ./ "$BUCKET"
  ;;
pull)
  dir
  pushd -- "$TMP"
  "${S3[@]}" sync -- "$BUCKET/" ./
  popd
  "$SELF/s3-prep.sh" pull "$TMP" "${FILES[@]}"

  gpg --batch --decrypt -- "$GPG" | gpg --import
  ;;
rmfr)
  read -r -p '>>> (yes/no)?' -- DIE
  if [[ $DIE == 'yes' ]]; then
    "${S3[@]}" rm --all-versions -- "$BUCKET/*"
  else
    exit 130
  fi
  ;;
*)
  set -x
  exit 2
  ;;
esac
