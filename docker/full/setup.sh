#!/usr/bin/env bash

set -eux
set -o pipefail


PYTHON_VER='3.8.3'
NODE_VER='14.4.0'


PYTHON_DEPS=(
  make
  build-essential
  libssl-dev
  zlib1g-dev
  libbz2-dev
  libreadline-dev
  libsqlite3-dev
  wget
  curl
  llvm
  libncurses5-dev
  xz-utils
  tk-dev
  libxml2-dev
  libxmlsec1-dev
  libffi-dev
  liblzma-dev
)
apt install --no-install-recommends -y "${PYTHON_DEPS[@]}"
asdf plugin add python
asdf install python "$PYTHON_VER"
asdf global python "$PYTHON_VER"


export NODEJS_CHECK_SIGNATURES=no
asdf plugin add nodejs
asdf install nodejs "$NODE_VER"
asdf global nodejs "$NODE_VER"


"$XDG_CONFIG_HOME/nvim/bin/nvim-pip"
"$XDG_CONFIG_HOME/nvim/bin/nvim-npm"

asdf-ree "$XDG_CONFIG_HOME/devrc/init.sh"
