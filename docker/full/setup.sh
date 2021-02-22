#!/usr/bin/env bash

set -eux
set -o pipefail


export DEBIAN_FRONTEND=noninteractive


inst() {
  local lang="$1"
  asdf plugin add "$lang"
  local ver="$(asdf latest "$lang")"
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
inst python


export NODEJS_CHECK_SIGNATURES=no
inst nodejs

inst golang
inst rust
