#!/usr/bin/env -S -- bash

unpack() {
  local -- FILE="$*"

  case "$FILE" in
  *.tar.bz | *.tar.bz2 | *.tbz | *.tbz2 | *.tar.gz | *.tgz | *.tar.xz | *.txz | *.tar.zst)
    tar --extract --no-same-owner --file "$FILE"
    ;;
  *.7z | *.zip | *.vsix | *.jar)
    7zz x -- "$FILE"
    ;;
  *.gz | *.xz)
    gzip --decompress --keep -- "$FILE"
    ;;
  *.rar)
    unar -- "$FILE"
    ;;
  *.deb)
    dpkg --extract "$FILE" .
    ;;
  *)
    printf -- '%s\n' "Unknown format :: $FILE"
    return 127
    ;;
  esac
}
