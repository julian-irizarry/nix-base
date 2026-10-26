#!/usr/bin/env bash
# herdr tab_bar_right command: current CPU load.
#
# Linux: averaged from /proc/stat over the time since the previous run (the
# refresh interval) so it doesn't jump on short spikes; the first run after
# boot or a cleared cache uses a short sample instead.
# macOS: no /proc, so sum every process's %cpu from ps and divide by the core
# count. ps already reports a decaying average, which smooths it the same way.
set -euo pipefail

# Nerd font oct_cpu (U+F4BC), the wezterm tabline cpu icon. Written as an
# escape so an editor or paste can't drop it.
icon=$'\357\222\274'
report() { LC_NUMERIC=C awk -v icon="$icon" -v pct="$1" 'BEGIN { printf "%s %.2f%%\n", icon, pct }'; }

if [[ ! -r /proc/stat ]]; then
  cores=$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu)
  report "$(ps -A -o %cpu= | LC_NUMERIC=C awk -v n="$cores" '{ s += $1 } END { print (n > 0 ? s / n : 0) }')"
  exit 0
fi

state=${XDG_CACHE_HOME:-$HOME/.cache}/herdr-tab-icons
mkdir -p "$state"
prev_file="$state/cpu-prev"

read_stat() {
  local _ user nice system idle iowait irq softirq steal
  read -r _ user nice system idle iowait irq softirq steal _ </proc/stat
  echo "$((idle + iowait)) $((user + nice + system + idle + iowait + irq + softirq + steal))"
}

if [[ -s $prev_file ]]; then
  read -r idle1 total1 <"$prev_file"
else
  read -r idle1 total1 < <(read_stat)
  sleep 0.5
fi
read -r idle2 total2 < <(read_stat)
echo "$idle2 $total2" >"$prev_file"

report "$(LC_NUMERIC=C awk -v di=$((idle2 - idle1)) -v dt=$((total2 - total1)) \
  'BEGIN { print (dt > 0 ? 100 * (dt - di) / dt : 0) }')"
