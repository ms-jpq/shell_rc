#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O globstar

set -o pipefail

cd -- "${0%/*}/.."

HOSTNAME="$1"
DST="$2"
export -- HOSTNAME PASSWD AUTHORIZED_KEYS

TMP="$(mktemp -d)"
HOSTNAME="$(jq --raw-input <<<"$HOSTNAME")"
envsubst <./cloud-init/meta-data.yml >"$TMP/meta-data"

AK=~/.ssh/authorized_keys
KEYS=(~/.ssh/*.pub)
if [[ -f "$AK" ]]; then
  KEYS+=("$AK")
fi

SALT="$(uuidgen)"
PASSWD="$(openssl passwd -1 -salt "$SALT" root | jq --raw-input)"
AUTHORIZED_KEYS="$(cat -- "${KEYS[@]}" | jq --raw-input --slurp --compact-output 'split("\n") | map(select(. != ""))')"
envsubst ./cloud-init/user-data.yml >"$TMP/user-data"
cp -a -R -f -- ./cloud-init/scripts "$TMP/scripts"

rm -v -fr -- "$DST"
case "$OSTYPE" in
darwin*)
  hdiutil makehybrid -iso -joliet -default-volume-name cidata -o "$DST" "$TMP"
  ;;
linux*)
  genisoimage -volid cidata -joliet -rock -output "$DST" -- "$TMP"/*
  ;;
*)
  exit 1
  ;;
esac
rm -fr -- "$TMP"
