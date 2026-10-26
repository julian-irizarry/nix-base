#!/usr/bin/env bash
# Repo + worktree picker for a herdr popup ([[keys.command]] type = "popup").
# Lists every main checkout under $HERDR_SOURCES_ROOT (default ~/sources) with
# its git worktrees nested beneath, wherever they live. Enter focuses the open
# workspace or opens one; worktrees first make sure their repo's workspace is
# open, since herdr only nests a worktree under its repo while both are open.
# ctrl-n creates a new worktree on the highlighted repo; ctrl-x deletes the
# highlighted worktree checkout (git keeps its branch). ctrl-o swaps the root
# for this popup, picked from the dirs that hold repos or typed as a path.
set -uo pipefail

root="${HERDR_SOURCES_ROOT:-$HOME/sources}"
# The fzf binds rerun this script, so the ctrl-o choice lives in a file.
if [ -n "${SOURCES_ROOT_FILE:-}" ] && [ -s "$SOURCES_ROOT_FILE" ]; then
  root=$(<"$SOURCES_ROOT_FILE")
fi

if [ "${1:-}" = --prompt ]; then
  printf '%s > ' "${root/#$HOME/\~}"
  exit 0
fi

fail() {
  printf '\n%s\npress any key' "$*" >&2
  read -rsn1
  exit 1
}

self=$(realpath "$0")

# ctrl-x: delete a worktree checkout. Through herdr when it has a workspace
# (herdr ends its panes and closes it), plain git otherwise. Dirty checkouts
# ask again before forcing.
if [ "${1:-}" = --remove ]; then
  kind=$2 path=$3 main=$4 ws=$5
  [ "$kind" = w ] || exit 0
  read -rn1 -p "delete worktree $path? the branch is kept [y/N] " answer
  echo
  [ "$answer" = y ] || exit 0
  remove() {
    if [ "$ws" != - ]; then
      herdr worktree remove --workspace "$ws" "$@" >/dev/null
    else
      git -C "$main" worktree remove "$@" "$path"
    fi
  }
  remove 2>/dev/null && exit 0
  read -rn1 -p "it has uncommitted or untracked changes. delete anyway? [y/N] " answer
  echo
  [ "$answer" = y ] || exit 0
  remove --force || fail "could not delete $path"
  exit 0
fi

# ctrl-o: candidates are the parents of every git repo under $HOME (hidden
# dirs skipped). A query that matches nothing is taken as a path.
if [ "${1:-}" = --pick-root ]; then
  picked=$(
    fd -H -t d '^\.git$' "$HOME" --max-depth 5 --prune \
      -E .cache -E .local -E .cargo -E .rustup -E go -E node_modules -E .npm -E snap 2>/dev/null \
      | sed -e 's|/\.git/$||' -e 's|/[^/]*$||' | rg -v '/\.' | sort -u \
      | sed "s|^$HOME|~|" \
      | fzf --layout=reverse --info=inline-right --prompt 'root > ' \
          --header 'enter picks a dir, or type a path' \
          --bind 'enter:accept-or-print-query'
  ) || exit 0
  [ -n "$picked" ] || exit 0
  picked="${picked/#\~/$HOME}"
  [ -d "$picked" ] || { printf 'not a directory: %s\npress any key' "$picked" >&2; read -rsn1; exit 0; }
  realpath "$picked" >"$SOURCES_ROOT_FILE"
  exit 0
fi

agent_workspaces=$(herdr api snapshot | jq -c '[.result.snapshot.panes[] | select(.agent != null) | .workspace_id] | unique')

# One `herdr worktree list` per repo, in parallel. Each prints a JSON object
# with the source repo, its worktrees, and any open_workspace_id.
listings=$(
  # The root itself too, for a root that is a repo rather than a parent.
  for d in "$root"/ "$root"/*/; do
    [ -d "$d.git" ] && printf '%s\0' "${d%/}"
  done | xargs -0 -P 8 -I{} sh -c 'herdr worktree list --cwd "$1" 2>/dev/null || true' _ {}
)

# Tab-separated rows: kind, path, main path, workspace id, main workspace id,
# tree display (empty query), flat display (while searching: worktree rows
# carry their repo name so a repo search keeps the whole subtree).
rows=$(
  jq -rs --argjson agents "$agent_workspaces" '
    def esc: "\u001b[";
    def marks($ws):
      (if $ws != "" then "  " + esc + "38;2;255;157;164m●" + esc + "0m" else "" end)
      + (if $ws != "" and ($agents | index($ws)) then " " + esc + "38;2;232;136;92m✳" + esc + "0m" else "" end);
    map(.result | select(.type == "worktree_list"))
    | sort_by(.source.repo_name | ascii_downcase)
    | .[]
    | .source as $src
    | (.worktrees | map(select(.is_linked_worktree | not)) | first // {}) as $main
    | ($main.open_workspace_id // "") as $mainws
    | (.worktrees | map(select(.is_linked_worktree and (.is_prunable | not)))) as $kids
    | (
        ["r", $src.repo_root, $src.repo_root, ($mainws | if . == "" then "-" end), ($mainws | if . == "" then "-" end),
         esc + "1m" + $src.repo_name + esc + "0m" + marks($mainws),
         esc + "1m" + $src.repo_name + esc + "0m" + marks($mainws)],
        ($kids | to_entries[] | .key as $i | .value
          | (.open_workspace_id // "") as $ws
          | (.branch // (.path | split("/") | last)) as $name
          | ["w", .path, $src.repo_root, ($ws | if . == "" then "-" end), ($mainws | if . == "" then "-" end),
             "  " + (if $i == ($kids | length) - 1 then "└" else "├" end) + " " + $name + marks($ws),
             "  └ " + $name + marks($ws) + "  " + esc + "2m" + $src.repo_name + esc + "0m"])
      )
    | @tsv
  ' <<<"$listings"
)

if [ "${1:-}" = --list ]; then
  printf '%s\n' "$rows"
  exit 0
fi

[ -n "$rows" ] || fail "no git repos found under $root"

SOURCES_ROOT_FILE=$(mktemp)
export SOURCES_ROOT_FILE
trap 'rm -f "$SOURCES_ROOT_FILE"' EXIT
printf '%s' "$root" >"$SOURCES_ROOT_FILE"

out=$(
  fzf <<<"$rows" \
    --ansi --no-sort --layout=reverse --info=inline-right \
    --delimiter=$'\t' --with-nth=6 \
    --bind 'change:transform:[ -n "$FZF_QUERY" ] && echo change-with-nth:7 || echo change-with-nth:6' \
    --bind "ctrl-x:execute(\"$self\" --remove {1} {2} {3} {4})+reload(\"$self\" --list)" \
    --bind "ctrl-o:execute(\"$self\" --pick-root)+reload(\"$self\" --list)+transform-prompt(\"$self\" --prompt)" \
    --expect=ctrl-n \
    --footer $' \e[38;2;255;157;164menter\e[0m  open     \e[38;2;255;157;164mctrl-n\e[0m  new worktree     \e[38;2;255;157;164mctrl-x\e[0m  delete worktree     \e[38;2;255;157;164mctrl-o\e[0m  root' \
    --footer-border=line \
    --prompt "$("$self" --prompt)"
) || exit 0

key=$(sed -n 1p <<<"$out")
row=$(sed -n 2p <<<"$out")
[ -n "$row" ] || exit 0
# Empty ids are "-": read collapses adjacent tabs.
IFS=$'\t' read -r kind path main ws mainws _ <<<"$row"
[ "$ws" = - ] && ws=
[ "$mainws" = - ] && mainws=
repo_name=$(basename "$main")

ensure_main() {
  [ -n "$mainws" ] && return
  herdr workspace create --cwd "$main" --label "$repo_name" --no-focus >/dev/null \
    || fail "could not open a workspace for $main"
}

if [ "$key" = ctrl-n ]; then
  read -rp "new worktree branch for $repo_name: " branch
  [ -n "$branch" ] || exit 0
  ensure_main
  herdr worktree create --cwd "$main" --branch "$branch" --focus >/dev/null \
    || fail "could not create worktree $branch"
  exit 0
fi

if [ -n "$ws" ]; then
  herdr workspace focus "$ws" >/dev/null || fail "could not focus $ws"
elif [ "$kind" = r ]; then
  herdr workspace create --cwd "$path" --label "$repo_name" --focus >/dev/null \
    || fail "could not open a workspace for $path"
else
  ensure_main
  herdr worktree open --cwd "$main" --path "$path" --focus >/dev/null \
    || fail "could not open worktree $path"
fi
