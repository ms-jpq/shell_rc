#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob

set -o pipefail

if [[ -L "$0" ]]; then
  ARG0="$(readlink -- "$0")"
else
  ARG0="$0"
fi

cd -- "${ARG0%/*}/.."

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
  unixpath="/$drive${ntpath//'\'/'/'}"
  printf -- '%s' "$unixpath"
}

RSYNC="${RSYNC:-"rsync"}"
if [[ "$OSTYPE" == msys ]]; then
  RSYNC="$(nt2unix "$RSYNC")"
fi

"${MAKE:-"gmake"}" -- all RSYNC="$RSYNC"

BSH=(bash --norc --noprofile -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar -c)
CONN=(ssh
  -o 'ControlMaster=auto'
  -o "ControlPath=$PWD/var/tmp/%r@%h:%p"
  -o 'ControlPersist=60'
  -p $((PORT))
)
printf -v RSH -- '%q ' "${CONN[@]}"
RSY=(
  "$RSYNC"
  --recursive
  --links
  --perms
  --keep-dirlinks
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
msys)
  OS=nt
  # shellcheck disable=SC2154
  E_HOME="$(nt2unix "$ENV_HOMEDRIVE$ENV_HOME")"
  ENV_MAKE="$(nt2unix "${ENV_MAKE,,}")"
  ;;
*)
  exit 1
  ;;
esac

declare -A -- FFS ROOTS
FFS=([root]=1 [home]=0)
ROOTS=(
  ['root']=/
  ['home']="$ENV_HOME"
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
ENVS=(RSYNC="$RSYNC" HOMEPATH="$ENV_HOME" HOMEDRIVE="$ENV_HOMEDRIVE")
shell "$ENV_MAKE" --directory "$E_HOME/.local/opt/initd" "${ENVS[@]}" "$@"
