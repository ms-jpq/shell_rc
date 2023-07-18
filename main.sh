#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob

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

gmake all

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

declare -A -- FFS
FFS=([root]=1 [home]=0)

if [[ "$DST" == 'localhost' ]]; then
  RDST=""
else
  RDST="$DST:"
fi

for FS in "${!FFS[@]}"; do
  # SUDO="${FFS["$FS"]}"
  ROOT="${ROOTS["$FS"]}"
  SRC="./tmp/$OS/$FS/"

  LINKS="./layers/$OS/$FS.sh"
  if [[ -x "$LINKS" ]]; then
    shell bash -c "$(<"$LINKS")"
  fi

  FOUND="$(find "$SRC")"
  if [[ -n "$FOUND" ]]; then
    rsync --recursive --links --perms --keep-dirlinks -- "$SRC" "$RDST$ROOT/"
  fi
done

shell "$ENV_HOME/.local/opt/initd/make.sh"
