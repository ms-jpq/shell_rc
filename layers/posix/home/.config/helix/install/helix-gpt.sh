#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

URI='https://github.com/leona/helix-gpt/archive/refs/heads/master.tar.gz'

# shellcheck disable=SC2154
get.sh "$URI" | unpack.sh "$RUN"
# shellcheck disable=SC2154
rm -fr -- "$LIB"
mv -v -f -- "$RUN/"* "$LIB"

if ! hash -- bun npm > /dev/null; then
  set -x
  exit
fi

pushd -- "$LIB" > /dev/null
npm run -- build:bin
popd > /dev/null

# shellcheck disable=SC2154
rm -fr -- "$BIN"
# shellcheck disable=SC2154
mv -vf -- "$LIB/dist" "$BIN"
