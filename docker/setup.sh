#!/usr/bin/env bash

set -eux
set -o pipefail


bash "$XDG_CONFIG_HOME/tmux/bin/tmux-init"
python3 "$XDG_CONFIG_HOME/ranger/bin/ranger-init"
bash "$XDG_CONFIG_HOME/nvim/bin/nvim-init"

touch "$XDG_CACHE_HOME/zz"

mkdir "$XDG_CACHE_HOME/gitstatus"
cd /_install
wget https://github.com/romkatv/gitstatus/releases/download/v1.0.0/gitstatusd-linux-x86_64.tar.gz
tar xzvf gitstatusd-linux-x86_64.tar.gz
mv gitstatusd-linux-x86_64 "$XDG_CACHE_HOME/gitstatus/"

