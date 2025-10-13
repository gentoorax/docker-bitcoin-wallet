#!/bin/bash
set -euo pipefail

# Launch Bitcoin Core GUI in the background so we can adjust the window position.
/home/user/bitcoin-core/bin/bitcoin-qt "$@" &
bitcoin_pid=$!

move_window() {
  # Try to locate the Bitcoin Core window and move it to a visible area.
  for _ in {1..30}; do
    sleep 1
    # Look for the Bitcoin Core window by class or title.
    window_id=$(wmctrl -lx | awk 'tolower($0) ~ /bitcoin/ {print $1; exit}')
    if [ -n "${window_id:-}" ]; then
      wmctrl -i -r "$window_id" -e 0,100,100,-1,-1
      return 0
    fi
  done
  return 1
}

move_window || echo "Bitcoin Core window not repositioned within timeout." >&2

wait $bitcoin_pid
