#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail
shopt -u failglob

cd -- "${0%/*}/.."

MACHINE="$1"
DST="$2"
export -- MACHINE_NAME PASSWD AUTHORIZED_KEYS IPV6_TOKEN

TMP="$(mktemp -d)"
MACHINE_NAME="$(jq --raw-input <<< "$MACHINE")"
envsubst < ./cloud-init/meta-data.yml > "$TMP/meta-data"

AK=~/.ssh/authorized_keys
KEYS=(~/.ssh/*.pub)
if [[ -f $AK ]]; then
  KEYS+=("$AK")
fi

SALT="$(uuidgen)"
PASSWD="$(openssl passwd -1 -salt "$SALT" root | jq --raw-input)"
AUTHORIZED_KEYS="$(cat -- "${KEYS[@]}" | jq --raw-input --slurp --compact-output 'split("\n") | map(select(. != ""))')"
IPV6_TOKEN="$(./libexec/ip64alloc.sh <<< "$MACHINE.$HOSTNAME")"

for YML in ./cloud-init/*.yml; do
  BASENAME="${YML##*/}"
  STEM="${BASENAME%.*}"
  envsubst < "$YML" > "$TMP/$STEM"
done
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
