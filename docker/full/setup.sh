#!/usr/bin/env bash

set -eux
set -o pipefail


PYTHON_VER='3.8.2'
NODE_VER='14.4.0'
RUST_VER='1.43.1'


inst() {
  local lang="$1"
  local ver="$2"
  asdf plugin add "$lang"
  asdf install "$lang" "$ver"
  asdf global "$lang" "$ver"
}


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
inst python "$PYTHON_VER"


export NODEJS_CHECK_SIGNATURES=no
inst nodejs "$NODE_VER"


inst rust "$RUST_VER"


asdf-ree "$XDG_CONFIG_HOME/devrc/init.sh"
