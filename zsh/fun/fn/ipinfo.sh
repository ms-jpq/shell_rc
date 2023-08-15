#!/usr/bin/env -S -- bash

ipinfo() {
  local -- ip
  ip="$(curl --fail --no-progress-meter -- 'https://ipinfo.io')"
  jq --sort-keys <<<"$ip"
}
