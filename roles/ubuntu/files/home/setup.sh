#!/usr/bin/env bash

set -eux
set -o pipefail


apt-install() {
  DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends --yes -- "$@"
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
apt-install "${PYTHON_DEPS[@]}"
asdf-inst python


RUBY_DEPS=(
 libssl-dev
)
apt-install  "${RUBY_DEPS[@]}"
asdf-inst python


NODEJS_CHECK_SIGNATURES=no asdf-inst nodejs


asdf-inst golang


asdf-inst rust
