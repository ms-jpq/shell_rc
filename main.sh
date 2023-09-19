#!/usr/bin/env -S -- bash

set -Eeu
set -o pipefail
shopt -s dotglob nullglob extglob globstar

cd -- "$(dirname -- "$0")"

LONG_OPTS='port:'
GO="$(getopt --options='' --longoptions="$LONG_OPTS" --name="$0" -- "$@")"
eval -- set -- "$GO"

PORT=22
while (($#)); do
  case "$1" in
  --port)
    PORT="$2"
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

DST="$1"
shift -- 1

nt2unix() {
  local -- drive ntpath
  ntpath="$1"
  drive="${ntpath%%:*}"
  ntpath="${ntpath#*:}"
  # shellcheck disable=SC1003
  unixpath="/${drive,,}${ntpath//'\'/'/'}"
  printf -- '%s' "$unixpath"
}

"${GMAKE:-"gmake"}"

BSH=(bash --norc --noprofile -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar -c)
CONN=(ssh
  -o 'ControlMaster=auto'
  -o "ControlPath=$PWD/var/tmp/%r@%h:%p"
  -o 'ControlPersist=60'
  -p $((PORT))
)
printf -v RSH -- '%q ' "${CONN[@]}"
RSY=(
  "${RSYNC:-"rsync"}"
  --recursive
  --keep-dirlinks
  --links
  --perms
  --times
  --rsh "$RSH"
  --
)

if [[ "$DST" == 'localhost' ]]; then
  LOCAL=1
  RDST=""
else
  LOCAL=0
  RDST="$DST:"
fi

shell() {
  local sh
  if ((LOCAL)); then
    "$@"
  else
    printf -v sh -- '%q ' "$@"
    # shellcheck disable=SC2029
    "${CONN[@]}" "$DST" "$sh"
  fi
}

ENV="$(shell "${BSH[@]}" "$(<'./libexec/env.sh')")"
set -a
eval -- "$ENV"
set +a
printf -- '%s\n' "$ENV"

# shellcheck disable=SC2154
case "$ENV_OSTYPE" in
darwin*)
  OS=darwin
  NT_HOME="$ENV_HOME"
  ;;
linux*)
  OS=ubuntu
  NT_HOME="$ENV_HOME"
  ;;
msys)
  OS=nt
  NT_HOME="$(nt2unix "$ENV_HOME")"
  ;;
*)
  exit 1
  ;;
esac

declare -A -- FFS ROOTS
FFS=([root]=1 [home]=0)
ROOTS=(
  ['root']=/
  ['home']="$NT_HOME"
)

for FS in "${!FFS[@]}"; do
  SUDO="${FFS["$FS"]}"
  ROOT="${ROOTS["$FS"]}"
  SRC="./var/tmp/$OS/$FS/"

  if ((SUDO)) && ((LOCAL)) && [[ "$OS" != nt ]]; then
    EX=(sudo --)
  else
    EX=()
  fi

  LINKS="./layers/$OS/$FS.sh"
  if [[ -x "$LINKS" ]]; then
    shell "${EX[@]}" "${BSH[@]}" "$(<"$LINKS")"
  fi

  F=''
  for F in "$SRC"*; do
    break
  done
  if [[ -z "$F" ]]; then
    continue
  fi

  SINK="$RDST$ROOT/"
  printf -- '%q%s%q\n' "$SRC" ' >>> ' "$SINK"
  "${EX[@]}" "${RSY[@]}" "$SRC" "$SINK"
done

shell "${BSH[@]}" "$(<./libexec/essentials.sh)"
ENVS=(USERPROFILE="$ENV_HOME")
# shellcheck disable=SC2154
shell "$ENV_MAKE" --directory "$NT_HOME/.local/opt/initd" "${ENVS[@]}" "$@"
