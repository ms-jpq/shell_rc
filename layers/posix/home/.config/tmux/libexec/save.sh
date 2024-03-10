#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O globstar

set -o pipefail

ENV='TMUX_NO_SAVE'
if tmux show-environment -g -h -- "$ENV" >/dev/null 2>&1; then
  exit 0
fi

if ! [[ -v TMUX_SAVE_LOCK ]]; then
  TMUX_SAVE_LOCK=1 exec -- flock "$0" "$0" "$@"
fi

if ! [[ -v UNDER_THE_DOG ]]; then
  if UNDER_THE_DOG=1 exec -- "$@" "$@"; then
    :
  fi
fi

PROCFS="${0%/*}/procfs.sh"

# shellcheck disable=SC2154
TMUX_SESSIONS="$XDG_STATE_HOME/tmux"

declare -A -- SESSIONS=() WINDOWS=() PANES=() LAYOUTS=() WDS=() CMDS=() ACTIVE=() PS_IDS=() ARGVS=()
WS=()
PS=()

S="$(tmux list-sessions -F '#{session_id} #{session_name}')"
W="$(tmux list-windows -a -F '#{window_id} #{session_id} #{window_active} #{window_layout}')"
P="$(tmux list-panes -a -F '#{pane_id} #{window_id} #{pane_active}')"
P_WD="$(tmux list-panes -a -F '#{pane_id} #{?#{pane_path},#{pane_path},#{pane_current_path}}')"
P_CMD="$(tmux list-panes -a -F '#{pane_id} #{pane_pid} #{pane_current_command}')"

readarray -t -- SL <<<"$S"
for LINE in "${SL[@]}"; do
  SID="${LINE%% *}"
  SNAME="${LINE#* }"
  SESSIONS["$SID"]="$SNAME"
done

readarray -t -- WL <<<"$W"
for LINE in "${WL[@]}"; do
  WID="${LINE%% *}"
  RHS="${LINE#* }"
  SID="${RHS%% *}"
  RHS="${RHS#* }"
  ACT="${RHS%% *}"
  LAYOUT="${RHS#* }"
  WINDOWS["$WID"]="$SID"
  LAYOUTS["$WID"]="$LAYOUT"
  WS+=("$WID")
  if ((ACT)); then
    ACTIVE["$WID"]="$ACT"
  fi
done

readarray -t -- PL <<<"$P"
for LINE in "${PL[@]}"; do
  PID="${LINE%% *}"
  RHS="${LINE#* }"
  WID="${RHS%% *}"
  ACT="${RHS#* }"
  PANES["$PID"]="$WID"
  PS+=("$PID")
  if ((ACT)); then
    ACTIVE["$PID"]="$ACT"
  fi
done

readarray -t -- P_WDL <<<"$P_WD"
for LINE in "${P_WDL[@]}"; do
  PID="${LINE%% *}"
  WD="${LINE#* }"
  WDS["$PID"]="$WD"
done

readarray -t -- P_CMDL <<<"$P_CMD"
for LINE in "${P_CMDL[@]}"; do
  PID="${LINE%% *}"
  RHS="${LINE#* }"
  PS_ID="${RHS%% *}"
  PS_IDS["$PID"]="$PS_ID"
  CMD="${RHS#* }"
  CMDS["$PID"]="$CMD"
done

PROC_LS="$(
  for PID in "${!PS_IDS[@]}"; do
    PS_ID="${PS_IDS["$PID"]}"
    CMD="${CMDS["$PID"]}"
    printf -- '%s\0' "$PID" "$PS_ID" "$CMD"
  done | xargs -r -0 -n 3 -P 0 -- "$PROCFS"
)"

readarray -t -- PROC_LINES < <(printf -- '%s' "$PROC_LS")

for LINE in "${PROC_LINES[@]}"; do
  PID="${LINE%% *}"
  ARGV="${LINE#* }"
  ARGVS["$PID"]="$ARGV"
done

for SID in "${!SESSIONS[@]}"; do
  SNAME="${SESSIONS["$SID"]}"
  FILE="$TMUX_SESSIONS/$SNAME"
  F1="$FILE.1.sh"
  F2="$FILE.2.sh"
  F3="$F1.tmp"
  F4="$F2.tmp"
  I=0
  W_MARK=0

  S_OK=0

  {
    printf -- '%q ' tmux set-environment -g -h -- "$ENV" 1
    printf -- '\n'

    for W_ORD in "${!WS[@]}"; do
      WID="${WS["$W_ORD"]}"
      if [[ "${WINDOWS["$WID"]}" == "$SID" ]]; then
        ((++I))
        J=0

        LAYOUT="${LAYOUTS["$WID"]}"
        if [[ -n "${ACTIVE["$WID"]:-""}" ]]; then
          W_MARK="$I"
        fi

        for PID in "${PS[@]}"; do
          if [[ "${PANES["$PID"]}" == "$WID" ]]; then
            WD="${WDS["$PID"]}"
            ARGV="${ARGVS["$PID"]:-""}"

            printf -- '%q ' mkdir -p -- "$WD"
            printf -- '\n'

            if ((J++)); then
              printf -- '%q ' tmux split-window -c "$WD"
            else
              printf -- '%q ' tmux new-window -c "$WD"
            fi
            printf -- '\n'

            if [[ -n "${ACTIVE["$PID"]:-""}" ]]; then
              printf -- '%q ' tmux select-pane -m
              printf -- '\n'
            fi

            if [[ -n "$ARGV" ]]; then
              printf -- '%q ' tmux set-buffer -- "$ARGV"$'\n'
              printf -- '\n'
              printf -- '%q ' tmux paste-buffer -d -p
              printf -- '\n'
            fi

            S_OK=1
          fi
        done
        printf -- '%q ' tmux select-pane -t '{marked}'
        printf -- '\n'
        printf -- '%q ' tmux select-pane -M
        printf -- '\n'
        printf -- '%q ' tmux select-layout -- "$LAYOUT"
        printf -- '\n'
      fi
    done

    printf -- '%q ' tmux select-window -t ":-$((I - W_MARK))"
    printf -- '\n'

    printf -- '%q ' tmux set-environment -g -h -u -- "$ENV"
    printf -- '\n'
  } >"$F4"

  printf -v A -- '%q ' tmux new-session -A -c "$HOME" -s "$SNAME" -- bash -Eeu "$F2"
  printf -v B -- '%q ' tmux new-session -d -c "$HOME" -s "$SNAME" -- bash -Eeu "$F2"
  printf -v C -- '%q ' tmux switch-client -t "$SNAME"

  read -r -d '' -- SH <<-EOF || true
if [[ -v TMUX ]]; then
  $B
  $C
else
  $A
fi
EOF
  printf -- '%s\n' "$SH" >"$F3"

  if ((S_OK)); then
    mv -f -- "$F4" "$F2"
    mv -f -- "$F3" "$F1"
  fi
done
