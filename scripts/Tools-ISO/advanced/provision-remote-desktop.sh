#!/bin/bash
# ThinForge — provision-remote-desktop.sh
#
# Installs the runtime dependencies for the Guacamole-based remote-desktop
# feature on a client image. Replaces the previous ffmpeg/xdotool pipeline.
#
# Packages:
#   x11vnc    VNC server, mirror mode against display :0
#   xdg-utils loginctl / who fallbacks
#   sudo      required for the agent's rdp-indicator subcommand to drop
#             into the logged-in user's session
#
# Note: yad is the runtime dependency of `thinforge-agent rdp-indicator`
# and is installed via install-*.sh EXTRA_PKGS — we do not install it
# defensively here anymore. The agent owns the indicator UI; this
# script only handles x11vnc + script-shim deployment.
#
# Also installs the helper scripts:
#   /usr/local/bin/tf-remote-desktop-start.sh
#   /usr/local/bin/tf-remote-desktop-stop.sh
#   /usr/local/bin/tf-remote-desktop-probe.sh
set -u

echo "[provision-remote-desktop] Installing packages..."

if command -v apt-get &>/dev/null; then
  apt-get update -qq
  apt-get install -y -qq x11vnc xdg-utils sudo
elif command -v dnf &>/dev/null; then
  dnf install -y -q x11vnc xdg-utils sudo
elif command -v pacman &>/dev/null; then
  pacman -Sy --noconfirm x11vnc xdg-utils sudo
else
  echo "[provision-remote-desktop] WARNING: no known package manager"
  exit 1
fi

echo "[provision-remote-desktop] Packages installed."

cat > /usr/local/bin/tf-remote-desktop-start.sh << 'START_EOF'
#!/bin/bash
# tf-remote-desktop-start.sh — backend-facing shim.
#
# The on-screen indicator (yad overlay) used to live here as a multi-page
# heredoc; it now delegates to the ThinForge agent binary, which owns
# the indicator logic in Go (testable, ships via self-update).
#
# x11vnc is still spawned here — it runs as root and has no need for
# the user-session context the agent provides.
set -u

AGENT=/data/thinforge/thinforge-agent
[ -x "$AGENT" ] || AGENT=/opt/thinforge/thinforge-agent
if [ ! -x "$AGENT" ]; then
  echo '{"error":"thinforge-agent binary not found"}'
  exit 1
fi

# --- x11vnc lifecycle (root-only, unchanged) ---------------------------------
XAUTH=""
[ -f /run/lightdm/root/:0 ] && XAUTH=/run/lightdm/root/:0
[ -z "$XAUTH" ] && XAUTH=$(find /home -maxdepth 2 -name .Xauthority -print -quit 2>/dev/null)

XAUTHORITY="${XAUTH:-}" DISPLAY=:0 xset dpms force on 2>/dev/null || true
XAUTHORITY="${XAUTH:-}" DISPLAY=:0 xset s reset 2>/dev/null || true

VNC_PID=$(pgrep -f 'x11vnc -display :0' | head -1)
if [ -z "$VNC_PID" ]; then
  x11vnc -display :0 -auth "${XAUTH:-guess}" \
         -localhost -nopw -shared -forever \
         -rfbport 5900 -quiet \
         >>/var/log/tf-remote-desktop.log 2>&1 &
  VNC_PID=$!
  sleep 0.25
fi

# --- on-screen indicator (delegated to agent) --------------------------------
# Token: random hex. Backend doesn't have to know it — we report the
# token in notify_pid so stop.sh can find the PID file via the agent.
TOKEN=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')

INDICATOR_JSON=$("$AGENT" rdp-indicator start "$TOKEN" 2>>/var/log/tf-remote-desktop.log)
INDICATOR_RC=$?

if [ $INDICATOR_RC -eq 0 ]; then
  NOTIFY_FIELD="$TOKEN"
  SESSION_TYPE=$(echo "$INDICATOR_JSON" | sed -n 's/.*"session_type":"\([^"]*\)".*/\1/p')
  [ -z "$SESSION_TYPE" ] && SESSION_TYPE=x11
else
  NOTIFY_FIELD=""
  SESSION_TYPE=$(echo "$INDICATOR_JSON" | sed -n 's/.*"session_type":"\([^"]*\)".*/\1/p')
  [ -z "$SESSION_TYPE" ] && SESSION_TYPE=unknown
fi

echo "{\"x11vnc_pid\":$VNC_PID,\"notify_pid\":\"$NOTIFY_FIELD\",\"session_type\":\"$SESSION_TYPE\"}"
START_EOF
chmod 755 /usr/local/bin/tf-remote-desktop-start.sh
echo "[provision-remote-desktop] tf-remote-desktop-start.sh installed"

cat > /usr/local/bin/tf-remote-desktop-stop.sh << 'STOP_EOF'
#!/bin/bash
# tf-remote-desktop-stop.sh — backend-facing shim.
# Args: $1 = x11vnc PID (ignored, kept for backward compat),
#       $2 = token previously returned in notify_pid.
AGENT=/data/thinforge/thinforge-agent
[ -x "$AGENT" ] || AGENT=/opt/thinforge/thinforge-agent
[ -x "$AGENT" ] && [ -n "${2:-}" ] && "$AGENT" rdp-indicator stop "$2"
exit 0
STOP_EOF
chmod 755 /usr/local/bin/tf-remote-desktop-stop.sh
echo "[provision-remote-desktop] tf-remote-desktop-stop.sh installed"

cat > /usr/local/bin/tf-remote-desktop-probe.sh << 'PROBE_EOF'
#!/bin/bash
# tf-remote-desktop-probe.sh
# Pre-flight check. Prints JSON: { "session_type": "x11"|"wayland"|"none",
# "x11vnc": true|false, "display_ok": true|false }
set -u

SESSION_TYPE="none"
SESSION_ID=$(loginctl list-sessions --no-legend 2>/dev/null \
             | awk '$4 ~ /^seat/ {print $1; exit}')
if [ -n "$SESSION_ID" ]; then
  SESSION_TYPE=$(loginctl show-session "$SESSION_ID" -p Type --value 2>/dev/null || echo "none")
fi

X11VNC=false
command -v x11vnc &>/dev/null && X11VNC=true

DISPLAY_OK=false
if [ "$SESSION_TYPE" = "x11" ]; then
  XAUTH=""
  [ -f /run/lightdm/root/:0 ] && XAUTH=/run/lightdm/root/:0
  [ -z "$XAUTH" ] && XAUTH=$(find /home -maxdepth 2 -name .Xauthority -print -quit 2>/dev/null)
  if XAUTHORITY="${XAUTH:-}" DISPLAY=:0 xdpyinfo &>/dev/null; then
    DISPLAY_OK=true
  fi
fi

printf '{"session_type":"%s","x11vnc":%s,"display_ok":%s}\n' \
       "$SESSION_TYPE" "$X11VNC" "$DISPLAY_OK"
PROBE_EOF
chmod 755 /usr/local/bin/tf-remote-desktop-probe.sh
echo "[provision-remote-desktop] tf-remote-desktop-probe.sh installed"
echo "[provision-remote-desktop] Done."
