#!/usr/bin/env bash

set -eux
set -o pipefail
shopt -s nullglob globstar

cd "$(dirname -- "$0")" || exit 1


XDG_CACHE_HOME="$HOME/.cache"
mkdir --parent -- "$XDG_CACHE_HOME/gitstatus"
wget -- https://github.com/romkatv/gitstatus/releases/latest/download/gitstatusd-linux-x86_64.tar.gz
tar xzvf gitstatusd-linux-x86_64.tar.gz
mv -- gitstatusd-linux-x86_64 "$XDG_CACHE_HOME/gitstatus/"
