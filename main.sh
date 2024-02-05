#!/usr/bin/env -S -- bash

set -Eeu
set -o pipefail
shopt -s dotglob nullglob extglob globstar

if ! [[ -v UNDER ]]; then
  HOSTS=()
  while (($#)); do
    case "$1" in
    --)
      shift
      break
      ;;
    *)
      HOSTS+=("$1")
      shift
      ;;
    esac
  done

  "${GMAKE:-"gmake"}"
  printf -- '%s\0' "${HOSTS[@]}" | UNDER=1 xargs -0 -I % -P 0 -- "$0" % "$@"
  exit
fi

cd -- "$(dirname -- "$0")"

DST_AND_PORT="$1"
shift -- 1

DST="${DST_AND_PORT%:*}"
if [[ "$DST_AND_PORT" =~ :(.+)$ ]]; then
  PORT="${BASH_REMATCH[1]}"
else
  PORT=22
fi

nt2unix() {
  local -- drive ntpath
  ntpath="$1"
  drive="${ntpath%%:*}"
  ntpath="${ntpath#*:}"
  # shellcheck disable=SC1003
  unixpath="/${drive,,}${ntpath//'\'/'/'}"
  printf -- '%s' "$unixpath"
}

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

ENVSH="$(cat -- ./libexec/{die,env}.sh)"
ENV="$(shell "${BSH[@]}" "$ENVSH")"
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
