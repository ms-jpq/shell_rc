#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- "${0%/*}"

DST="$1"
shift -- 1

shell() {
  local sh
  if [[ "$DST" == 'localhost' ]]; then
    "$@"
  else
    sh="$(printf -- '%q ' "$@")"
    # shellcheck disable=SC2029
    ssh "$DST" "$sh"
  fi
}

make all

ENV="$(shell bash -c "$(<'./libexec/env.sh')")"
printf -- '%s\n' "$ENV"

set -a
eval -- "$ENV"
set +a

# shellcheck disable=SC2154
case "$ENV_OSTYPE" in
darwin*)
  OS=darwin
  ;;
linux*)
  OS=ubuntu
  ;;
msys*)
  OS=nt
  ;;
*)
  exit 1
  ;;
esac

declare -A -- ROOTS
ROOTS=(
  ['root']=/
  ['home']="$ENV_HOME"
)

FFS=(root home)

for FS in "${FFS[@]}"; do
  ROOT="${ROOTS["$FS"]}"
  SRC="./tmp/$OS.$FS.tar"
  UNTAR=(
    tar -x
    -p -o -m
    -C "$ROOT"
    -f -
    -v
  )
  shell "${UNTAR[@]}" <"$SRC"
done

shell "$ENV_HOME/.local/opt/initd/make.sh"
