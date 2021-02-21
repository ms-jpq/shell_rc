#!/usr/bin/env bash

set -eu
set -o pipefail


cd "$(dirname "$0")" || exit 1


if [[ "$(uname)" = 'Darwin' ]]
then
  export LDFLAGS='-L/usr/local/opt/openssl@1.1/lib'
  export CPPFLAGS='-I/usr/local/opt/openssl@1.1/include'
fi

./.venv/bin/pip3 install -U -r requirements.txt
./.venv/bin/ansible-galaxy collection install community.general

