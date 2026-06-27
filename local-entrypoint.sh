#!/bin/bash
set -euo pipefail

WEB_VIEW_PORT="${WEB_VIEW_PORT:-10000}"
XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/home/user/.runtime}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/home/user/.config}"
export XDG_RUNTIME_DIR
export XDG_CONFIG_HOME

mkdir -p "${XDG_RUNTIME_DIR}" /home/user/.xpra "${XDG_CONFIG_HOME}/menus"
chmod 700 "${XDG_RUNTIME_DIR}" /home/user/.xpra

cat > "${XDG_CONFIG_HOME}/menus/applications.menu" <<'EOF'
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
 "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
<Menu>
  <Name>Applications</Name>
  <DefaultAppDirs/>
  <DefaultDirectoryDirs/>
  <Include>
    <All/>
  </Include>
</Menu>
EOF

cp "${XDG_CONFIG_HOME}/menus/applications.menu" "${XDG_CONFIG_HOME}/menus/debian-menu.menu"
cp "${XDG_CONFIG_HOME}/menus/applications.menu" "${XDG_CONFIG_HOME}/menus/kde-debian-menu.menu"
update-desktop-database /usr/share/applications >/dev/null 2>&1 || true

if [ "${ENABLE_WEB_VIEW:-no}" = "yes" ]; then
  XPRA_ARGS=(
    start
    "--bind-tcp=0.0.0.0:${WEB_VIEW_PORT}"
    --html=on
    --daemon=no
    --pulseaudio=no
    --notifications=no
    --bell=no
    --mdns=no
    --dbus-launch=no
    --start-child=/usr/bin/openbox
    --start=/usr/local/bin/launch-bitcoin.sh
  )

  if [ -n "${XPRA_USER:-}" ] && [ -n "${XPRA_PASSWORD:-}" ]; then
    python3 -m xpra.auth.sqlite /home/user/auth.sdb create
    python3 -m xpra.auth.sqlite /home/user/auth.sdb add "${XPRA_USER}" "${XPRA_PASSWORD}"
    XPRA_ARGS+=(
      --auth=sqlite:filename=/home/user/auth.sdb
      --ws-auth=sqlite:filename=/home/user/auth.sdb
      --tcp-auth=sqlite:filename=/home/user/auth.sdb
    )
  fi

  exec xpra "${XPRA_ARGS[@]}"
fi

exec /usr/local/bin/launch-bitcoin.sh
