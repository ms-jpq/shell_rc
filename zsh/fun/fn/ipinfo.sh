#!/usr/bin/env -S -- bash

ipinfo() {
  local -- ip
  ip="$(curl --fail-with-body --no-progress-meter -- 'https://ipinfo.io')"
  jq --sort-keys <<<"$ip"
}
