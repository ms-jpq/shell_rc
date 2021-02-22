#!/usr/bin/env bash

set -eux
set -o pipefail

cd /_install || exit 1

XDG_CACHE_HOME="$HOME/.cache"
mkdir -p "$XDG_CACHE_HOME/gitstatus"
wget https://github.com/romkatv/gitstatus/releases/download/v1.0.0/gitstatusd-linux-x86_64.tar.gz
tar xzvf gitstatusd-linux-x86_64.tar.gz
mv gitstatusd-linux-x86_64 "$XDG_CACHE_HOME/gitstatus/"
