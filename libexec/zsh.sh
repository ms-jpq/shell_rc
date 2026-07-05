#!/usr/bin/env -S -- bash

set -Eeu -o pipefail
shopt -s dotglob nullglob extglob globstar

OS="$1"
Z_OUT="$2"
B_OUT="$3"
shift -- 3

FUNC="$Z_OUT/fn"
BINS="$Z_OUT/bin"
BLIB="$Z_OUT/libexec"

rm -fr -- "$Z_OUT"
mkdir -p -- "$FUNC" "$BINS" "$BLIB" "$B_OUT"

DIRS=(
  ./zsh/apriori
  ./zsh/{iso,tmux}
  ./zsh/"$OS"
  ./zsh/aposteriori
  ./zsh/{fun,dev,docker}
)

ZSH=(./zsh/apriori.{sh,zsh})
BSH=(./zsh/apriori.{sh,bash} ./layers/posix/home/.zshenv)

for DIR in "${DIRS[@]}"; do
  ZSH+=("$DIR"/*.{sh,zsh})
  BSH+=("$DIR"/*.{sh,bash})
done

SH=(./zsh/_*.sh)

# TODO: this somehow blows up gnu-tar on windows?
if [[ $OS != 'nt' ]]; then
  BSH+=(./zsh/aposteriori.{bash,sh} "${SH[@]}")
  ZSH+=(./zsh/aposteriori.{zsh,sh} "${SH[@]}")
fi

ZACC=("$(cat -- /dev/null "${ZSH[@]}")")
BACC=("$(cat -- /dev/null "${BSH[@]}")")

for DIR in "${DIRS[@]}"; do
  for BIN in "$DIR/bin"/*; do
    B="${BIN##*/}"
    B="${B%%.*}"
    # shellcheck disable=SC2016
    BS='"$XDG_CONFIG_HOME/zsh/bin/"'"$B"' "$@"'

    ZACC+=("autoload -Uz -- \"\$ZDOTDIR/fn/$B\"")
    BACC+=("$B() {" "$BS" '}')
    printf -- '%s\n' "$BS" > "$FUNC/$B"
    cp -f -- "$BIN" "$BINS/$B"
  done
done

for DIR in "${DIRS[@]}"; do
  for BIN in "$DIR/libexec"/*; do
    B="${BIN##*/}"
    cp -f -- "$BIN" "$BLIB/$B"
  done
done

for DIR in "${DIRS[@]}"; do
  for FN in "$DIR/fn"/*.sh; do
    F="${FN%.sh}"
    F="${F##*/}"
    ZACC+=("autoload -Uz -- \"\$ZDOTDIR/fn/$F\"")
    cp -f -- "$FN" "$FUNC/${F##*/}"

    PAT="$F() {"
    FF="$(< "$FN")"
    if grep -q -F -- "$PAT" "$FN"; then
      BACC+=("$FF")
    else
      BACC+=("$PAT" "$FF" '}')
    fi
  done
done

printf -- '%s\n' "${ZACC[@]}" > "$Z_OUT/.zshrc"
printf -- '%s\n' "${BACC[@]}" > "$B_OUT/.bashrc"
