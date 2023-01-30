#!/usr/bin/env -S -- bash

if [[ -z "$LANG" ]] || [[ -z "$LC_ALL" ]]; then
  export -- LANG='{{ locale }}.UTF-8'
  export -- LC_ALL='{{ locale }}.UTF-8'
fi
