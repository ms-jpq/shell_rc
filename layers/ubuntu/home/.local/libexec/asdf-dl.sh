#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

apt-install() {
  DEBIAN_FRONTEND=noninteractive sudo --preserve-env -- apt-get install --yes -- "$@"
}

asdf-install() {
  "$HOME/.config/zsh/bin/asdf-install" "$@"
}

touch -- "$HOME/.tool-versions"

##
##
##

PYTHON_DEPS=(
  build-essential
  curl
  libbz2-dev
  libffi-dev
  liblzma-dev
  libncurses5-dev
  libreadline-dev
  libsqlite3-dev
  libssl-dev
  libxml2-dev
  libxmlsec1-dev
  llvm
  tk-dev
  wget
  xz-utils
  zlib1g-dev
)
apt-install "${PYTHON_DEPS[@]}"
asdf-install --global -- python

# shellcheck disable=SC2154
mkdir --verbose --parent -- "$XDG_DATA_HOME/gnupg"
NODEJS_CHECK_SIGNATURES=no asdf-install --global -- nodejs

asdf-install --global -- rust

asdf-install --global -- golang

RUBY_DEPS=(
  libyaml-dev
  libssl-dev
)
apt-install "${RUBY_DEPS[@]}"
asdf-install --global -- ruby

# R_DEPS=(
#   build-essential
#   gfortran
#   libbz2-1.0
#   libbz2-dev
#   libbz2-dev
#   libcurl3-dev
#   liblzma-dev
#   liblzma-dev
#   liblzma5
#   libpcre2-dev
#   libreadline-dev
#   xorg-dev
# )
# R_OPTS=(
#   --enable-R-shlib
#   --with-cairo
#   --with-x=no
# )
# apt-install "${R_DEPS[@]}"
# asdf plugin-add r https://github.com/asdf-community/asdf-r.git
# R_EXTRA_CONFIGURE_OPTIONS="${R_OPTS[*]}" asdf-install --global -- r

# PHP_DEPS=(
#   autoconf
#   bison
#   libcurl4-openssl-dev
#   libgd-dev
#   libonig-dev
#   libzip-dev
#   re2c
# )
# apt-install "${PHP_DEPS[@]}"
# asdf-install --global -- php

# PROLOG_DEPS=(
#   cmake
#   libarchive-dev
#   libgmp-dev
#   libreadline-dev
#   libunwind-dev
# )
# apt-install "${PROLOG_DEPS[@]}"
# asdf-install --global -- swiprolog

PLUGINS="$(asdf plugin list)"
JPLUGIN='java'
HAS_JPLUGIN=0
while read -r -- line; do
  if [[ $line == "$JPLUGIN" ]]; then
    HAS_JPLUGIN=1
    break
  fi
done <<< "$PLUGINS"

if ((HAS_JPLUGIN)); then
  asdf plugin update "$JPLUGIN"
else
  asdf plugin add "$JPLUGIN"
fi

JPLUGIN_VER="$(asdf list-all "$JPLUGIN" | grep --fixed-strings -- 'openjdk' | tail --lines 1)"
asdf install "$JPLUGIN" "$JPLUGIN_VER"
asdf global "$JPLUGIN" "$JPLUGIN_VER"

asdf-install --global -- awscli
asdf-install --global -- opentofu

asdf reshim
