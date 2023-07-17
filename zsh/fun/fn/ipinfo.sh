#!/usr/bin/env -S -- bash

ipinfo() {
  local -- ip
  ip="$(curl --fail --location --no-progress-meter -- 'https://ipinfo.io')"
  jq <<<"$ip"
}
