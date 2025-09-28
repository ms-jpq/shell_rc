#!/usr/bin/env -S -- bash

ipinfo() {
  # shellcheck disable=SC2312
  curl --connect-timeout 6 --fail --no-progress-meter -- 'https://ipinfo.io' 'https://v6.ipinfo.io' | jq --sort-keys
}
