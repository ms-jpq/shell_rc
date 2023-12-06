#!/usr/bin/env -S -- bash

httpp() {
  local proxy="$1"
  shift
  http_proxy="$proxy" https_proxy="$proxy" HTTP_PROXY="$proxy" HTTPS_PROXY="$proxy" "$@"
}
