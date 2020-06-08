#!/usr/bin/env bash

set -eux
set -o pipefail


bash "$XDG_CONFIG_HOME/tmux/bin/tmux-init"
python3 "$XDG_CONFIG_HOME/ranger/bin/ranger-init"
bash "$XDG_CONFIG_HOME/nvim/bin/nvim-init"

touch "$XDG_CACHE_HOME/zz"

