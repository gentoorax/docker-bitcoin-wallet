#!/bin/bash
set -euo pipefail

/home/user/bitcoin-core/bin/bitcoin-qt "$@" &
bitcoin_pid=$!
maintain_pid=

cleanup() {
  if [ -n "${maintain_pid:-}" ] && ps -p "${maintain_pid}" > /dev/null 2>&1; then
    kill "${maintain_pid}" >/dev/null 2>&1 || true
  fi
  if ps -p "${bitcoin_pid}" > /dev/null 2>&1; then
    kill "${bitcoin_pid}" >/dev/null 2>&1 || true
  fi
}
trap cleanup INT TERM

find_window() {
  wmctrl -lx | awk 'tolower($0) ~ /(bitcoin|bitcoin-qt)/ {print $1; exit}'
}

center_window() {
  window_id=$(find_window || true)
  if [ -z "${window_id:-}" ]; then
    return 1
  fi

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

  wmctrl -i -r "$window_id" -e 0,"$target_x","$target_y",-1,-1 || true
  if command -v xdotool >/dev/null 2>&1; then
    xdotool windowmove "$window_id" "$target_x" "$target_y" || true
    xdotool windowraise "$window_id" || true
  fi
  echo "Repositioned Bitcoin Core window to ${target_x},${target_y} on ${display_width}x${display_height} display." >&2
  wmctrl -i -a "$window_id" || true
  return 0
}

maintain_position() {
  local attempts=0
  while kill -0 "${bitcoin_pid}" >/dev/null 2>&1; do
    center_window && attempts=0 || ((attempts++))
    if (( attempts > 60 )); then
      echo "Bitcoin Core window not found for repositioning." >&2
      attempts=0
    fi
    sleep 2
  done
}

maintain_position &
maintain_pid=$!

wait "${bitcoin_pid}"
wait "${maintain_pid}" 2>/dev/null || true
