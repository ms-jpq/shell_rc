#!/usr/bin/env -S -- bash

ipinfo() {
  local -- ip
  ip="$(curl --no-progress-meter --location -- 'https://ipinfo.io')"
  jq <<<"$ip"
}
