#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O globstar

set -o pipefail

cd -- "${0%/*}/.."

LONG_OPTS='out:,os:'
GO="$(getopt --options='' --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval set -- "$GO"

while (($#)); do
  case "$1" in
  --os)
    OS="$2"
    shift -- 2
    ;;
  --out)
    OUT="$2"
    shift -- 2
    ;;
  --)
    shift -- 1
    break
    ;;
  *)
    exit 1
    ;;
  esac
done

rm -fr -- "$OUT"
FUNC="$OUT/fn"
BINS="$OUT/bin"
BLIB="$OUT/libexec"
mkdir -p -- "$FUNC" "$BINS" "$BLIB"

ZZ=(
  ./zsh/apriori/*.zsh
  ./zsh/{shared,tmux}/*.zsh
  ./zsh/"$OS"/*.zsh
  ./zsh/aposteriori/*.zsh
  ./zsh/{fun,docker}/*.zsh
)

ACC=()

for ZSH in "${ZZ[@]}"; do
  read -r -d '' -- Z <<-EOF || true
# $ZSH
$(<"$ZSH")
EOF
  ACC+=("$Z")
done

for FN in ./zsh/*/fn/*.sh; do
  F="${FN%%.sh}"
  read -r -d '' -- Z <<-EOF || true
  autoload -Uz -- "\$ZDOTDIR/"'$F'
EOF
  ACC+=("$Z")
  cp -- "$FN" "$FUNC/${F##*/}"
done

for BIN in ./zsh/*/bin/*; do
  B="${BIN##*/}"
  cp -- "$BIN" "$BINS/${B%%.*}"
done

for BIN in ./zsh/*/libexec/*; do
  B="${BIN##*/}"
  cp -- "$BIN" "$BLIB/$B"
done

printf -- '%s\n' "${ACC[@]}" >"$OUT/.zshrc"
