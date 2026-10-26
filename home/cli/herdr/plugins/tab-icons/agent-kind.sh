#!/usr/bin/env bash
# Report each agent pane's kind (claude, codex, ...) as the `kind` pane token,
# so sidebar rows can show it next to the agent's name. herdr's `agent` token
# is the name when set and the kind otherwise; there's no built-in kind token.
set -euo pipefail

herdr=${HERDR_BIN_PATH:-herdr}
"$herdr" agent list | jq -r '.result.agents[] | select(.agent) | [.pane_id, .agent] | @tsv' |
  while IFS=$'\t' read -r pane kind; do
    "$herdr" pane report-metadata "$pane" --source tab-icons:kind --token "kind=$kind" >/dev/null
  done
