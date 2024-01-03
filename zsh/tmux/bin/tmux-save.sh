#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O globstar

set -o pipefail

WHITELIST=(
  less
  man
  nvim
)
declare -A -- WHITE=()
for CMD in "${WHITELIST[@]}"; do
  WHITE["$CMD"]=1
done

declare -A -- SESSIONS=() WINDOWS=() PANES=() LAYOUTS=() WDS=() CMDS=()
WS=()
PS=()

S="$(tmux list-sessions -F '#{session_id} #{session_name}')"
W="$(tmux list-windows -a -F '#{window_id} #{session_id} #{window_layout}')"
P="$(tmux list-panes -a -F '#{pane_id} #{window_id}')"
P_WD="$(tmux list-panes -a -F '#{pane_id} #{?#{pane_path},#{pane_path},#{pane_current_path}}')"
P_CMD="$(tmux list-panes -a -F '#{pane_id} #{pane_current_command}')"

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
  WINDOWS["$WID"]="$SID"
  LAYOUT="${RHS#* }"
  LAYOUTS["$WID"]="$LAYOUT"
  WS+=("$WID")
done

readarray -t -- PL <<<"$P"
for LINE in "${PL[@]}"; do
  PID="${LINE%% *}"
  WID="${LINE#* }"
  PANES["$PID"]="$WID"
  PS+=("$PID")
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
  CMD="${LINE#* }"
  CMDS["$PID"]="$CMD"
done

for SID in "${!SESSIONS[@]}"; do
  SNAME="${SESSIONS["$SID"]}"
  # shellcheck disable=SC2154
  FILE="$XDG_STATE_HOME/tmux/$SNAME"
  I=0
  rm -fr -- "$FILE".*.sh
  F1="$FILE.1.sh"
  F2="$FILE.2.sh"
  for W_ORD in "${!WS[@]}"; do
    WID="${WS["$W_ORD"]}"
    if [[ "${WINDOWS["$WID"]}" == "$SID" ]]; then
      J=0
      LAYOUT="${LAYOUTS["$WID"]}"

      if ! ((I++)); then
        {
          printf -- '%q ' tmux new-session -s "$(uuidgen)" -- bash -Eeu "$F2"
          printf -- '\n'
        } >"$F1"
      fi

      for PID in "${PS[@]}"; do
        if [[ "${PANES["$PID"]}" == "$WID" ]]; then
          WD="${WDS["$PID"]}"
          CMD="${CMDS["$PID"]}"
          if ! ((J++)); then
            printf -- '%q ' tmux new-window -c "$WD"
          else
            printf -- '%q ' tmux split-window -c "$WD"
          fi
          printf -- '\n'
          if [[ -n "${WHITE["$CMD"]:-""}" ]]; then
            printf -- '%q ' tmux set-buffer -- "$CMD"$'\n'
            printf -- '\n'
            printf -- '%q ' tmux paste-buffer -d -p
            printf -- '\n'
          fi
        fi
      done
      printf -- '%q ' tmux select-layout -- "$LAYOUT"
      printf -- '\n'
    fi
  done >"$F2"
done
