#!/usr/bin/env -S -- bash

export -- LC_ALL TZ

if [[ -z "${LC_ALL:-""}" ]]; then
  case "$OSTYPE" in
  darwin*)
    case "$(defaults read -g AppleLocale)" in
    zh*)
      LC_ALL='zh_CN.UTF-8'
      ;;
    *)
      LC_ALL='en_CA.UTF-8'
      ;;
    esac
    ;;
  *)
    LC_ALL='zh_CN.UTF-8'
    ;;
  esac
fi

if [[ -z "${TZ:-""}" ]]; then
  case "$OSTYPE" in
  darwin*)
    TZ="$(readlink -- /etc/localtime)"
    TZ="${TZ#'/var/db/timezone/zoneinfo/'}"
    ;;
  linux*)
    TZ="$(readlink -- /etc/localtime)"
    TZ="${TZ#'/usr/share/zoneinfo/'}"
    ;;
  msys)
    :
    ;;
  *) ;;
  esac
fi
