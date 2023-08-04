#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob

set -o pipefail

ARG0="$(realpath -- "$0")"
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

CTL="$PWD/var/tmp"
mkdir -p -- "$CTL"
CONN=(ssh
  -o 'ControlMaster=auto'
  -o "ControlPath=$CTL/%r@%h:%p"
  -o 'ControlPersist=60'
  -p $((PORT))
)
printf -v RSH -- '%q ' "${CONN[@]}"

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

gmake all

BSH=(bash --norc --noprofile -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar -c)
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
msys*)
  OS=nt
  DRIVE="${ENV_HOME%%:*}"
  ENV_HOME="${ENV_HOME#*:}"
  # shellcheck disable=SC1003
  ENV_HOME="/$DRIVE/${ENV_HOME//'\'/'/'}"
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

for FS in "${!FFS[@]}"; do
  SUDO="${FFS["$FS"]}"
  ROOT="${ROOTS["$FS"]}"
  SRC="./var/tmp/$OS/$FS/"

  if ((SUDO)) && ((LOCAL)); then
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

  if [[ -n "$F" ]]; then
    SINK="$RDST$ROOT/"
    printf -- '%q%s%q\n' "$SRC" ' >>> ' "$SINK"
    "${EX[@]}" rsync --recursive --links --perms --keep-dirlinks --rsh "$RSH" -- "$SRC" "$SINK"
  fi
done

shell "$ENV_HOME/.local/opt/initd/make.sh" "$@"
