#!/usr/bin/env bash
# herdr tab_bar_right command: like the wezterm tabline domain component,
# "<monitor> local", or "<ssh> host" when the focused pane is running ssh.
set -euo pipefail

herdr=${HERDR_BIN_PATH:-herdr}
pane=$("$herdr" api snapshot | jq -r '.result.snapshot.focused_pane_id // empty')

host=""
if [[ -n $pane ]]; then
  # A read loop, not mapfile: macOS's /bin/bash is 3.2.
  argv=()
  while IFS= read -r arg; do argv+=("$arg"); done < <("$herdr" pane process-info --pane "$pane" 2>/dev/null |
    jq -r '.result.process_info.foreground_processes[0] // {} | select(.name == "ssh") | .argv[1:][]')
  skip=0
  for arg in ${argv[@]+"${argv[@]}"}; do
    if ((skip)); then
      skip=0
      continue
    fi
    case $arg in
      -[bcDEeFIiJLlmOoPpQRSWw]) skip=1 ;;
      -*) ;;
      *)
        host=${arg#*@}
        break
        ;;
    esac
  done
fi

if [[ -n $host ]]; then
  echo "󰣀 $host"
else
  echo "󰍹 local"
fi
