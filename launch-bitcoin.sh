#!/bin/bash
set -euo pipefail

/home/user/bitcoin-core/bin/bitcoin-qt "$@" &
bitcoin_pid=$!

cleanup() {
  if ps -p "${bitcoin_pid}" > /dev/null 2>&1; then
    kill "${bitcoin_pid}" >/dev/null 2>&1 || true
  fi
}
trap cleanup INT TERM

move_window() {
  for _ in $(seq 1 60); do
    sleep 1
    window_id=$(wmctrl -lx | awk 'tolower($0) ~ /bitcoin-qt/ {print $1; exit}')
    if [ -n "${window_id:-}" ]; then
      local display_width=1600
      local display_height=1200
      if command -v xdotool >/dev/null 2>&1; then
        read -r display_width display_height < <(xdotool getdisplaygeometry)
        if geometry=$(xdotool getwindowgeometry --shell "$window_id" 2>/dev/null); then
          eval "$geometry"
        fi
      fi

      local window_width=${WIDTH:-1024}
      local window_height=${HEIGHT:-768}

      local target_x=$(( (display_width - window_width) / 2 ))
      local target_y=$(( (display_height - window_height) / 2 ))

      if (( target_x < 0 )); then target_x=0; fi
      if (( target_y < 0 )); then target_y=0; fi

      wmctrl -i -r "$window_id" -e 0,"$target_x","$target_y",-1,-1
      wmctrl -i -a "$window_id" || true
      return 0
    fi
  done
  return 1
}

move_window || echo "Bitcoin Core window not repositioned within timeout." >&2

wait "${bitcoin_pid}"
