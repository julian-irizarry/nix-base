#!/usr/bin/env bash
# Vim-style jump list over workspaces, like ctrl-o/ctrl-i.
#
#   record   on workspace.focused: append the focused workspace, dropping any
#            forward history, unless the focus came from our own back/forward
#   back     focus the previous workspace in the list
#   forward  focus the next one
#   closed   on workspace.closed: drop that workspace from the list
#
# Closed workspaces are pruned whenever the list is walked.
set -euo pipefail

herdr=${HERDR_BIN_PATH:-herdr}
state=${HERDR_PLUGIN_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/herdr/plugins/workspace-jumps}
mkdir -p "$state"
jumps="$state/jumps.json"
# Workspace we're about to focus ourselves, so its focus event isn't recorded.
pending="$state/pending"
max_jumps=50

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

lock "$state/lock"
[[ -s $jumps ]] || echo '{"jumps":[],"cursor":-1}' >"$jumps"

workspaces=$("$herdr" workspace list)
live=$(jq -c '[.result.workspaces[].workspace_id]' <<<"$workspaces")
event_workspace=$(jq -r 'first(.. | .workspace_id? | strings) // empty' <<<"${HERDR_PLUGIN_EVENT_JSON:-null}")
if [[ ${1:-} == closed ]]; then
  # The list can still include it while the handler runs.
  live=$(jq -c --arg w "$event_workspace" 'map(select(. != $w))' <<<"$live")
  focused=""
else
  # A focus event names the new workspace itself; `workspace list` can still
  # report the old one while the handler runs.
  focused=$event_workspace
  [[ -n $focused ]] || focused=$(jq -r '.result.workspaces[] | select(.focused) | .workspace_id' <<<"$workspaces")
fi

save() { jq -c . >"$jumps.tmp" && mv "$jumps.tmp" "$jumps"; }

# Drop closed workspaces and the consecutive duplicates that leaves, keeping the
# cursor on the same entry (or the nearest earlier one if it was closed).
prune() {
  jq --argjson live "$live" '
    reduce range(0; .jumps | length) as $i ({out: [], cursor: -1, src: .};
      .src.jumps[$i] as $w
      | if ($live | index($w)) and ($w != .out[-1]) then .out += [$w] else . end
      | if $i <= .src.cursor then .cursor = (.out | length) - 1 else . end)
    | {jumps: .out, cursor: (if (.out | length) == 0 then -1 else [.cursor, 0] | max end)}
  ' "$jumps" | save
}

# Record `focused` as a new jump: forward history after the cursor is discarded.
record() {
  [[ -n $focused ]] || return 0
  jq --arg w "$focused" --argjson max "$max_jumps" '
    if .jumps[.cursor] == $w then . else
    .jumps = .jumps[: .cursor + 1]
    | if .jumps[-1] != $w then .jumps += [$w] else . end
    | .jumps = .jumps[-$max:]
    | .cursor = (.jumps | length) - 1
    end
  ' "$jumps" | save
}

move() {
  prune
  # A focus we missed (e.g. right after startup) still counts as a jump.
  if [[ -n $focused && $(jq -r '.jumps[.cursor] // ""' "$jumps") != "$focused" ]]; then
    record
  fi
  local target
  target=$(jq -r --argjson step "$1" '
    (.cursor + $step) as $c
    | if $c >= 0 and $c < (.jumps | length) then .jumps[$c] else "" end
  ' "$jumps")
  [[ -n $target ]] || return 0
  jq --argjson step "$1" '.cursor += $step' "$jumps" | save
  printf '%s' "$target" >"$pending"
  "$herdr" workspace focus "$target" >/dev/null || rm -f "$pending"
}

case ${1:?usage: workspace-jumps.sh record|closed|back|forward} in
  record)
    # Prune first: if the workspace we were on just closed, the cursor falls back
    # to the entry before it, and herdr moving there isn't a new jump.
    prune
    if [[ -f $pending && $(<"$pending") == "$focused" ]]; then
      rm -f "$pending"
    else
      rm -f "$pending"
      record
    fi
    echo "focused=$focused event=${HERDR_PLUGIN_EVENT_JSON:-none} $(<"$jumps")"
    ;;
  closed)
    prune
    echo "closed=$event_workspace $(<"$jumps")"
    ;;
  back) move -1 ;;
  forward) move 1 ;;
  *) echo "workspace-jumps.sh: unknown command: $1" >&2; exit 2 ;;
esac
