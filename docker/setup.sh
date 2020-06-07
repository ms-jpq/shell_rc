#!/usr/bin/env bash

set -eux
set -o pipefail


bash "$XDG_CONFIG_HOME/tmux/bin/tmux-init"
touch "$XDG_CACHE_HOME/zz"


pip3 install ranger-fm pynvim
python3 "$XDG_CONFIG_HOME/ranger/bin/plug.py"
VIM_INIT=1 nvim --headless
nvim --headless +UpdateRemotePlugins +quit


mkdir "$XDG_CACHE_HOME/gitstatus"
cd /_install
wget https://github.com/romkatv/gitstatus/releases/download/v1.0.0/gitstatusd-linux-x86_64.tar.gz
tar xzvf gitstatusd-linux-x86_64.tar.gz
mv gitstatusd-linux-x86_64 "$XDG_CACHE_HOME/gitstatus/"

