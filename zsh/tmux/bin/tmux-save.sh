#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

declare -A -- SESSIONS=() WINDOWS=() PANES=() N_PANES=() LAYOUTS=() WDS=() CMDS=()

S="$(tmux list-sessions -F '#{session_id} #{session_name}')"
W="$(tmux list-windows -a -F '#{window_id} #{session_id} #{window_panes} #{window_layout}')"
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
  N="${RHS%% *}"
  WINDOWS["$WID"]="$SID"
  N_PANES["$WID"]="$N"
  LAYOUT="${RHS#* }"
  LAYOUTS["$WID"]="$LAYOUT"
done

readarray -t -- PL <<<"$P"
for LINE in "${PL[@]}"; do
  PID="${LINE%% *}"
  WID="${LINE#* }"
  PANES["$PID"]="$WID"
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
  printf -- '%s\n' "${SESSIONS["$SID"]}"
  for WID in "${!WINDOWS[@]}"; do
    if [[ "${WINDOWS["$WID"]}" == "$SID" ]]; then
      printf -- '%s\n' "${N_PANES["$WID"]}"
      printf -- '%s\n' "${LAYOUTS["$WID"]}"
      for PID in "${!PANES[@]}"; do
        if [[ "${PANES["$PID"]}" == "$WID" ]]; then
          printf -- '%s\n' "${WDS["$PID"]}"
          printf -- '%s\n' "${CMDS["$PID"]}"
        fi
      done
    fi
  done
done
