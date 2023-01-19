#!/usr/bin/env bash

if [[ -z "$TZ" ]]
then
  export -- TZ='{{ timezone }}'
fi
