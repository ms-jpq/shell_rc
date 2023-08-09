#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O globstar

set -o pipefail

cd -- "${0%/*}/.."

OS="$1"
OUT="$2"
shift -- 2

FUNC="$OUT/fn"
BINS="$OUT/bin"
BLIB="$OUT/libexec"

rm -fr -- "$OUT"
mkdir -p -- "$FUNC" "$BINS" "$BLIB"

SH=(
  ./zsh/apriori/*.sh
  ./zsh/{iso,tmux}/*.sh
  ./zsh/"$OS"/*.sh
  ./zsh/aposteriori/*.sh
  ./zsh/{dev,fun,docker}/*.sh
)

ZSH=(./zsh/*.zsh)

for BIN in ./zsh/*/bin/*; do
  B="${BIN##*/}"
  cp -- "$BIN" "$BINS/${B%%.*}"
done

for BIN in ./zsh/*/libexec/*; do
  B="${BIN##*/}"
  cp -- "$BIN" "$BLIB/$B"
done

ACC=("$(cat -- "${SH[@]}")")
ZACC=("${ACC[@]}" "$(cat -- "${ZSH[@]}")")

for FN in ./zsh/*/fn/*.sh; do
  F="${FN%%.sh}"
  F="${F##*/}"
  ZACC+=("autoload -Uz -- \"\$ZDOTDIR/fn/$F\"")
  cp -- "$FN" "$FUNC/${F##*/}"

  PAT="$F() {"
  FF="$(<"$FN")"
  if /usr/bin/grep -F -- "$PAT" "$FN" >/dev/null; then
    ACC+=("$FF")
  else
    ACC+=("$PAT" "$FF" '}')
  fi
done

printf -- '%s\n' "${ZACC[@]}" >"$OUT/.zshrc"
printf -- '%s\n' "${ACC[@]}" >"$OUT/.bashrc"
