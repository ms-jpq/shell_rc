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

declare -A -- SESSIONS=() WINDOWS=() PANES=() LAYOUTS=() WDS=() CMDS=() ACTIVE=()
WS=()
PS=()

S="$(tmux list-sessions -F '#{session_id} #{session_name}')"
W="$(tmux list-windows -a -F '#{window_id} #{session_id} #{window_active} #{window_layout}')"
P="$(tmux list-panes -a -F '#{pane_id} #{window_id} #{pane_active}')"
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
  CMD="${LINE#* }"
  CMDS["$PID"]="$CMD"
done

for SID in "${!SESSIONS[@]}"; do
  SNAME="${SESSIONS["$SID"]}"
  # shellcheck disable=SC2154
  FILE="$XDG_STATE_HOME/tmux/$SNAME"
  I=0
  F1="$FILE.1.sh"
  F2="$FILE.2.sh"
  W_MARK=0

  rm -fr -- "$FILE".*.sh
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
          CMD="${CMDS["$PID"]}"

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

          if [[ -n "${WHITE["$CMD"]:-""}" ]]; then
            printf -- '%q ' tmux set-buffer -- "$CMD"$'\n'
            printf -- '\n'
            printf -- '%q ' tmux paste-buffer -d -p
            printf -- '\n'
          fi
        fi
      done
      printf -- '%q ' tmux select-pane -t '{marked}'
      printf -- '\n'
      printf -- '%q ' tmux select-pane -M
      printf -- '\n'
      printf -- '%q ' tmux select-layout -- "$LAYOUT"
      printf -- '\n'
    fi
  done >"$F2"

  {
    printf -- '%q ' tmux select-window -t ":-$((I - W_MARK))"
    printf -- '\n'
  } >>"$F2"

  {
    printf -- '%q ' tmux new-session -d -c "$HOME" -s "$SNAME" -- bash -Eeu "$F2"
    printf -- '\n'
    printf -- '%q ' tmux switch-client -t "$SNAME"
    printf -- '\n'
  } >"$F1"
done
