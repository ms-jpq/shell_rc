#!/usr/bin/env -S -- bash

ipinfo() {
  # shellcheck disable=SC2312
  curl --fail-with-body --no-progress-meter -- 'https://ipinfo.io' | jq --sort-keys
  curl -6 --fail-with-body --no-progress-meter -- 'https://ifconfig.co'
}
