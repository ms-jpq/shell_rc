#!/usr/bin/env -S -- bash

export -- TZ

if ! [[ -v LC_ALL ]]; then
  export -- LC_ALL='zh_CN.UTF-8'
fi
