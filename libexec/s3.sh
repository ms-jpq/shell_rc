#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O globstar

set -o pipefail

BASE="${0%/*}/.."
BUCKET='s3://chumbucket-home'
S5="$BASE/var/bin/s5cmd"
TMP="$BASE/var/gpg"
GPG="$TMP/backup.gpg"

dir() (
  rm -v -fr -- "$TMP"
  mkdir -v -p -- "$TMP"
  chmod -v g-rwx,o-rwx "$TMP"
)

S5=(
  "$BASE/var/bin/s5cmd"
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
  "${S5[@]}" ls --humanize -- "$BUCKET" | awk '{ gsub("%2F", "/", $NF); print }' | column -t
  ;;
push)
  FILES=(
    .config/aws/credentials
    .config/gnupg/sshcontrol
    .local/lbin/
    .local/share/it2/
    .local/share/ssh/
    .local/share/zsh/
    .netrc
    .ssh/
  )

  dir
  for F in "${FILES[@]}"; do
    "${RSY[@]}" -- "$HOME/$F" "$TMP/$F"
  done

  SECRETS=()
  for F in "$TMP"/**/*; do
    if [[ -f "$F" ]] && ! [[ "$F" =~ \.gitignore$ ]]; then
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

  BW="$BASE/node_modules/.bin/bw"
  chmod +x "$BW"
  "$BW" export --format json --raw | gpg -v --batch --encrypt --output "$TMP/bitwarden.json.gpg"
  gpg -v --export-secret-keys --export-options export-backup | gpg -v --batch --encrypt --output "$GPG"
  "${S5[@]}" sync --delete -- "$TMP/" "$BUCKET"
  ;;
pull)
  dir
  "${S5[@]}" cp -- "$BUCKET/*" "$TMP"
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
