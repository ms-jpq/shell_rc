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

  case "$OSTYPE" in
  msys)
    make
    ;;
  *)
    gmake
    ;;
  esac

  cd -- "$(dirname -- "$0")"
  printf -- '%s\0' "${HOSTS[@]}" | UNDER=1 xargs -r -0 -I % -P 0 -- "$0" % "$@"
  exit
fi

DST_AND_PORT="$1"
shift -- 1

DST="${DST_AND_PORT%:*}"
if [[ "$DST_AND_PORT" =~ :(.+)$ ]]; then
  PORT="${BASH_REMATCH[1]}"
else
  PORT=22
fi

PREFIX=''
if [[ "$0" == *macos.sh ]]; then
  PREFIX='/opt/homebrew/bin'
fi

BSH=(bash --norc --noprofile -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar)
CONN=(
  ssh
  -o 'ClearAllForwardings=yes'
  -o 'ControlMaster=auto'
  -o "ControlPath=$PWD/var/tmp/%C"
  -o 'ControlPersist=60'
  -p $((PORT))
)
printf -v RSH -- '%q ' "${CONN[@]}"
RSY=(
  rsync
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
    if [[ "$0" == *win.sh ]] && [[ "$sh" == bash* ]]; then
      sh='"%PROGRAMFILES%\Git\usr\bin\"'"$sh"
    fi
    # shellcheck disable=SC2029
    "${CONN[@]}" "$DST" "$sh"
  fi
}

ENV="$(cat -- ./libexec/{die,env}.sh | shell "${BSH[@]}")"
set -a
eval -- "$ENV"
set +a
printf -- '%s\n' "$ENV"

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
  RSY=(./libexec/rsync.sh "$RSH")
  if ((LOCAL)); then
    RDST='localhost:'
  fi
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
  SRC="var/tmp/$OS/$FS/"

  if ((SUDO)) && ((LOCAL)) && [[ "$OS" != nt ]]; then
    EX=(sudo --)
  else
    EX=()
  fi

  LINKS="./layers/$OS/$FS.sh"
  if [[ -x "$LINKS" ]]; then
    shell "${EX[@]}" "${BSH[@]}" <<<"$(<"$LINKS")"
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

shell "${BSH[@]}" <<<"$(<./libexec/essentials.sh)"
ENVS=(USERPROFILE="$ENV_HOME")
# shellcheck disable=SC2154
shell "${BSH[@]}" "$ENV_HOME/.local/opt/initd/make.sh" "${ENVS[@]}" "$@"
