#!/usr/bin/env -S -- bash

unpack() {
  local -- FILE="$*"

  case "$FILE" in
  *.tar.bz | *.tar.bz2 | *.tbz | *.tbz2 | *.tar.gz | *.tgz | *.tar.xz | *.txz | *.tar.zst)
    tar --extract --auto-compress --no-same-owner --file "$FILE"
    ;;
  *.7z | *.zip)
    7zz x -- "$FILE"
    ;;
  *.gz)
    gzip --decompress --keep -- "$FILE"
    ;;
  *.rar)
    unrar -x -- "$FILE"
    ;;
  *)
    printf -- '%s\n' "Unknown format :: $FILE"
    ;;
  esac
}
