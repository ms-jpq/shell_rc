#!/usr/bin/env -S -- bash

if [[ -z "$TZ" ]]; then
  export -- TZ='{{ timezone }}'
fi
