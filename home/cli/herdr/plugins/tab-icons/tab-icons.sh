#!/usr/bin/env bash
# Relabel herdr tabs as "<icon> <dir>" (or "<icon> <ssh host>"), mirroring the
# wezterm tabline: the workspace's active tab shows parent/dir, others dir.
#
# Only tabs still carrying a generated numeric label, or the label this script
# last set, are touched. Rename a tab by hand and it is left alone; rename it
# back to a number to hand it back.
set -euo pipefail

herdr=${HERDR_BIN_PATH:-herdr}
# Same dir herdr passes, so a run outside herdr (by hand) shares its labels.
state=${HERDR_PLUGIN_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/herdr/plugins/tab-icons}
mkdir -p "$state"
labels="$state/labels.json"

# Serialize runs on the state dir. flock(1) where it exists (Linux); macOS has
# none, so fall back to an atomic mkdir lock, taking over one left behind
# by a killed run after ~10s.
lock() {
  if command -v flock >/dev/null; then
    exec 9>"$1"
    flock 9
    return
  fi
  local dir=$1.d tries=0
  until mkdir "$dir" 2>/dev/null; do
    if ((++tries > 100)); then
      rm -rf "$dir"
      tries=0
    fi
    sleep 0.1
  done
  # Expanded now: $dir is local and gone by the time the EXIT trap runs.
  # shellcheck disable=SC2064
  trap "rm -rf $(printf %q "$dir")" EXIT
}

# Events arrive in bursts (focus + created); serialize so runs don't race.
lock "$state/lock"
[[ -s $labels ]] || echo '{}' >"$labels"

icon_for() {
  case $1 in
    nvim | vim) printf '' ;;
    ssh) printf '󰒋' ;;
    zsh | bash | fish | sh) printf '' ;;
    cargo | rustc | bacon) printf '' ;;
    git | lazygit | gh) printf '' ;;
    nix | nh | nom) printf '' ;;
    docker | lazydocker | kubectl) printf '󰡨' ;;
    python | python3 | uv) printf '' ;;
    go) printf '󰟓' ;;
    node | npm | pnpm | npx) printf '󰎙' ;;
    btop | htop | top) printf '󰄧' ;;
    *) printf '󰣆' ;;
  esac
}

# First non-option argument after ssh, minus any user@.
ssh_host() {
  local skip=0 arg
  for arg in "$@"; do
    if ((skip)); then
      skip=0
      continue
    fi
    case $arg in
      -[bcDEeFIiJLlmOoPpQRSWw]) skip=1 ;;
      -*) ;;
      *)
        printf '%s' "${arg#*@}"
        return
        ;;
    esac
  done
}

truncate() {
  local s=$1 max=$2
  if ((${#s} > max)); then
    printf '%s...' "${s:0:max-3}"
  else
    printf '%s' "$s"
  fi
}

snap=$("$herdr" api snapshot | jq -c .result.snapshot)
active_tabs=$(jq -c '[.workspaces[].active_tab_id]' <<<"$snap")
old_labels=$(cat "$labels")
# Rebuilt from managed tabs only, so closed and hand-renamed tabs drop out.
new_labels='{}'

while IFS=$'\t' read -r tab_id label pane_id cwd agent; do
  last=$(jq -r --arg t "$tab_id" '.[$t] // ""' <<<"$old_labels")
  [[ $label =~ ^[0-9]+$ || $label == "$last" ]] || continue

  proc=$("$herdr" pane process-info --pane "$pane_id" 2>/dev/null |
    jq -c '.result.process_info.foreground_processes[0] // {}')
  name=$(jq -r '.name // ""' <<<"$proc")
  name=${name#.}
  name=${name%-wrapped}

  host=""
  if [[ $name == ssh ]]; then
    # A read loop, not mapfile: macOS's /bin/bash is 3.2.
    argv=()
    while IFS= read -r arg; do argv+=("$arg"); done < <(jq -r '.argv[1:][]?' <<<"$proc")
    host=$(ssh_host ${argv[@]+"${argv[@]}"})
  fi

  if [[ $agent == claude ]]; then
    icon=$'✳'
  else
    icon=$(icon_for "$name")
  fi

  if jq -e --arg t "$tab_id" 'index($t)' <<<"$active_tabs" >/dev/null; then
    max=27
    dir=$(basename "$cwd")
    parent=$(basename "$(dirname "$cwd")")
    [[ $parent == / || $parent == . ]] || dir="$parent/$dir"
  else
    max=18
    dir=$(basename "$cwd")
  fi
  text=${host:-$dir}
  want="$icon $(truncate "$text" "$max")"

  if [[ $want != "$label" ]]; then
    "$herdr" tab rename "$tab_id" "$want" >/dev/null
  fi
  new_labels=$(jq -c --arg t "$tab_id" --arg l "$want" '.[$t] = $l' <<<"$new_labels")
done < <(jq -r '
  . as $s
  | .tabs[]
  | . as $tab
  | ($s.layouts[] | select(.tab_id == $tab.tab_id) | .focused_pane_id) as $pid
  | ($s.panes[] | select(.pane_id == $pid)) as $p
  | [$tab.tab_id, $tab.label, $pid, ($p.foreground_cwd // $p.cwd // ""), ($p.agent // "")]
  | @tsv' <<<"$snap")

printf '%s\n' "$new_labels" >"$labels"
