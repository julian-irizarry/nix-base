#!/usr/bin/env bash
# herdr popup command for prefix+t: attach to a long-lived shell session kept
# by shpool. The popup only holds the shpool client. prefix+t inside detaches
# (see shpool.toml) and herdr closes the popup, while the shell keeps running in
# the shpool daemon. `exit` ends the session; the next prefix+t starts
# a fresh one in ~/sources.
set -euo pipefail

here=$(dirname "$(realpath "$0")")
session=orchestrator

# shpool comes from the nix-base herdr module.
# --force: if the last popup was closed some other way and left a stale client
# attached, take the session over instead of failing with "already attached".
exec shpool -c "$here/shpool.toml" attach --force --dir "$HOME/sources" "$session"
