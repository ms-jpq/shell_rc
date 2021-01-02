#!/usr/bin/env bash

set -eux
set -o pipefail


"$XDG_CONFIG_HOME/tmux/bin/tmux-init"


"$XDG_CONFIG_HOME/nvim/init.py" --install-runtime --install-packages
nvim --headless


touch "$XDG_CACHE_HOME/zz"


mkdir -p "$XDG_CACHE_HOME/gitstatus"
cd /_install
wget https://github.com/romkatv/gitstatus/releases/download/v1.0.0/gitstatusd-linux-x86_64.tar.gz
tar xzvf gitstatusd-linux-x86_64.tar.gz
mv gitstatusd-linux-x86_64 "$XDG_CACHE_HOME/gitstatus/"
