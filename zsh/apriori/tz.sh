#!/usr/bin/env -S -- bash

if ! [[ -v TZ ]]; then
  export -- TZ='America/Vancouver'
fi
