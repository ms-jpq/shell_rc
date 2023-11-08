#!/usr/bin/env -S -- bash

if ! [[ -v LC_ALL ]]; then
  export -- LC_ALL='zh_CN.UTF-8'
fi

if ! [[ -v TZ ]] && [[ -v SSH ]]; then
  export -- TZ='America/Vancouver'
fi
