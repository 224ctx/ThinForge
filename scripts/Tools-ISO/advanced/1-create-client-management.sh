#!/bin/bash
# ThinForge — 1-create-client-management.sh
#
# Bereitet eine VM für das Klonen vor. Läuft AUSSCHLIESSLICH im ISO-Modus:
#
#   mount /dev/sr1 /mnt && bash /mnt/1-create-client-management.sh
#
# Die Tools-ISO ist die kanonische Provisioning-Quelle und enthält alle
# benötigten Dateien (provisioning_key.pub, server_url, heartbeat_token,
# server.crt, signing-pubkey, agent-binary, alle Apply-Skripte). Der frühere
# curl|bash-Bootstrap-Modus über die öffentliche API wurde entfernt — er
# leakte das geteilte Heartbeat-Token und das Trust-Anchor-Material an
# jeden LAN-Host. Siehe docs/security-audit-2026-04-18.md F-CR-01 + F-CR-05.
#
# Installiert:
#   - SSH Public Key des Servers (für Ansible-Zugriff nach Deployment)
#   - SSH-Server (openssh-server) mit Key-only Auth
#   - ThinForge Agent (Go) + Token + Heartbeat
#   - Delta-Update Scripts (apply-delta, apply-update, manage-snapshots)
#
set -u

# ── ISO-Mount validieren ─────────────────────────────────────────────
# Skript muss von der Tools-ISO ausgeführt werden. Bei curl|bash ist
# $0 = "bash" und SCRIPT_DIR ungültig — fail-fast.

if [ ! -f "$0" ]; then
  echo "[setup] ERROR: Script must be executed as a file, not via curl|bash."
  echo "[setup] Expected usage:"
  echo "[setup]   mount /dev/sr1 /mnt && bash /mnt/1-create-client-management.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -f "${SCRIPT_DIR}/provisioning_key.pub" ] && [ ! -f "${SCRIPT_DIR}/server_url" ]; then
  echo "[setup] ERROR: Tools-ISO files not found in ${SCRIPT_DIR}."
  echo "[setup] Make sure the Tools-ISO is mounted and the script"
  echo "[setup] was called from the mount path, not from the image."
  exit 1
fi

if [ ! -f "${SCRIPT_DIR}/server_url" ]; then
  echo "[setup] ERROR: server_url file is missing from the Tools-ISO."
  echo "[setup] Tools-ISO is incomplete — rebuild and try again."
  exit 1
fi

SERVER_URL=$(tr -d '[:space:]' < "${SCRIPT_DIR}/server_url")

echo "[setup] ThinForge Clone Preparation (Tools-ISO)"
echo "[setup] Server URL: ${SERVER_URL}"

# ── Hilfsfunktion: Datei aus ISO laden (kein API-Fallback) ───────────

get_file() {
  # $1 = lokaler Dateiname auf der ISO
  local local_name="$1"

  # Helfer-Scripts liegen in iso/, dynamische Dateien (Keys etc.) im Root
  if [ -f "${SCRIPT_DIR}/iso/${local_name}" ]; then
    cat "${SCRIPT_DIR}/iso/${local_name}"
    return
  elif [ -f "${SCRIPT_DIR}/${local_name}" ]; then
    cat "${SCRIPT_DIR}/${local_name}"
    return
  fi
  # Datei fehlt in der ISO — Aufrufer muss damit umgehen (z.B. WARNUNG/exit).
  return 1
}

# ── 1. SSH-Key des Servers installieren ──────────────────────────────

echo "[setup] Installing SSH key..."

SSH_KEY=$(get_file "provisioning_key.pub")

if [ -z "${SSH_KEY}" ]; then
  echo "[setup] ERROR: SSH key (provisioning_key.pub) is missing from the Tools-ISO."
  echo "[setup] Rebuild the Tools-ISO."
  exit 1
fi

mkdir -p /root/.ssh
chmod 700 /root/.ssh

# Immer überschreiben (aktuelle Keys vom Server)
echo "${SSH_KEY}" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
echo "[setup] SSH key installed (authorized_keys overwritten)"

# ── 1b. Server TLS-Zertifikat installieren (fuer HTTPS) ──────────────

TLS_CERT=$(get_file "server.crt")

if [ -n "${TLS_CERT}" ]; then
  if [ -d /etc/ca-certificates/trust-source/anchors ]; then
    # Arch / Manjaro
    echo "${TLS_CERT}" > /etc/ca-certificates/trust-source/anchors/thinforge-server.crt
    update-ca-trust 2>/dev/null || true
  elif [ -d /etc/pki/ca-trust/source/anchors ]; then
    # RHEL / Fedora / CentOS
    echo "${TLS_CERT}" > /etc/pki/ca-trust/source/anchors/thinforge-server.crt
    update-ca-trust 2>/dev/null || true
  else
    # Debian / Ubuntu (default)
    mkdir -p /usr/local/share/ca-certificates
    echo "${TLS_CERT}" > /usr/local/share/ca-certificates/thinforge-server.crt
    update-ca-certificates 2>/dev/null || true
  fi

  # Auch direkt an den vom Agent erwarteten Pfad kopieren. Der Go-Agent
  # (agent-go/internal/heartbeat/heartbeat.go::buildHTTPClient) nutzt NICHT
  # den System-CA-Store sondern liest das Zertifikat explizit von
  # /data/thinforge/server.crt als eigenen Trust-Anchor. Ohne diese Datei
  # schlaegt der Heartbeat mit "trusted cert not readable" fehl (F-CR-05
  # hartes Fail-Fast statt silent TOFU-Fallback).
  mkdir -p /data/thinforge
  echo "${TLS_CERT}" > /data/thinforge/server.crt
  chmod 644 /data/thinforge/server.crt

  echo "[setup] TLS certificate installed (system CA + /data/thinforge/server.crt for agent)"
else
  echo "[setup] WARNING: TLS certificate not available — HTTPS connections will fail"
fi

# ── 2. SSH-Server installieren und konfigurieren ─────────────────────

# Zuerst installieren, damit /etc/ssh/sshd_config existiert
if ! command -v sshd &>/dev/null; then
  echo "[setup] Installing openssh-server..."
  if command -v apt-get &>/dev/null; then
    apt-get update -qq && apt-get install -y -qq openssh-server
  elif command -v dnf &>/dev/null; then
    dnf install -y -q openssh-server
  elif command -v pacman &>/dev/null; then
    pacman -Sy --noconfirm openssh
  fi
fi

# SSH Host-Keys generieren falls nicht vorhanden
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
  echo "[setup] Generating SSH host keys..."
  ssh-keygen -A
fi

# Dann konfigurieren
if [ -f /etc/ssh/sshd_config ]; then
  # Root-Login per Key erlauben
  if grep -q "^#\?PermitRootLogin" /etc/ssh/sshd_config; then
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
  else
    echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
  fi
  # PubkeyAuthentication aktivieren
  if grep -q "^#\?PubkeyAuthentication" /etc/ssh/sshd_config; then
    sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
  fi
  # Passwort-Login deaktivieren — nur Server-Key erlaubt
  if grep -q "^#\?PasswordAuthentication" /etc/ssh/sshd_config; then
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
  else
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
  fi
  if grep -q "^#\?KbdInteractiveAuthentication" /etc/ssh/sshd_config; then
    sed -i 's/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config
  fi
  echo "[setup] sshd: key authentication only"
else
  echo "[setup] WARNING: /etc/ssh/sshd_config not found!"
fi

# SSH-Server aktivieren und starten
systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true

# Prüfen ob sshd wirklich läuft
if systemctl is-active ssh &>/dev/null || systemctl is-active sshd &>/dev/null; then
  echo "[setup] sshd is running"
else
  echo "[setup] WARNING: sshd could not be started!"
  echo "[setup] Attempting direct start..."
  /usr/sbin/sshd 2>/dev/null || true
fi

# ── 4. Heartbeat-Token installieren ──────────────────────────────────

echo "[setup] Installing heartbeat token..."

HEARTBEAT_TOKEN=$(get_file "heartbeat_token")

mkdir -p /data/thinforge
if [ -n "${HEARTBEAT_TOKEN}" ]; then
  echo "${HEARTBEAT_TOKEN}" > /data/thinforge/heartbeat.token
  chmod 600 /data/thinforge/heartbeat.token
  echo "[setup] Heartbeat token installed"
else
  echo "[setup] ERROR: Heartbeat token is missing from the Tools-ISO. Rebuild the Tools-ISO."
  exit 1
fi

# ── 4b. Signing Public Key installieren (fuer Delta-Verifikation) ────

echo "[setup] Installing signing key..."

SIGNING_KEY=$(get_file "thinforge.pub")

if [ -n "${SIGNING_KEY}" ]; then
  mkdir -p /data/thinforge
  echo "${SIGNING_KEY}" > /data/thinforge/signing.pub
  chmod 644 /data/thinforge/signing.pub
  echo "[setup] Signing key installed (/data/thinforge/signing.pub)"
else
  echo "[setup] ERROR: Signing key (thinforge.pub) is missing from the Tools-ISO."
  echo "[setup] Without the signing key the agent cannot verify updates."
  echo "[setup] Rebuild the Tools-ISO."
  exit 1
fi

# ── 5. ThinForge Agent installieren ──────────────────────────────────
#
# Bevorzugt das Go-Binary (thinforge-agent), faellt auf Python zurueck.

echo "[setup] Installing ThinForge agent..."

mkdir -p /data/thinforge
rm -rf /opt/thinforge
ln -sf /data/thinforge /opt/thinforge

AGENT_INSTALLED=false

# Go-Agent-Binary aus der Tools-ISO kopieren — via Tempfile + atomic rename,
# weil ein direkter `cp` ueber das laufende Binary mit ETXTBSY ("Text file
# busy") scheitert sobald `thinforge-agent.service` aktiv ist. Das Skript
# kann beliebig oft re-laufen (z.B. nach ISO-Update). Ohne den atomic-
# replace blieb beim ersten Re-Run die alte Binary auf Disk haengen, das
# Skript meldete aber faelschlich Erfolg, weil cp's exit-Code nicht
# geprueft wurde und das nachgelagerte chmod nur die ctime updated.
if [ -f "${SCRIPT_DIR}/thinforge-agent" ]; then
  if ! cp "${SCRIPT_DIR}/thinforge-agent" /data/thinforge/thinforge-agent.new; then
    echo "[setup] ERROR: could not copy agent binary from ISO to /data/thinforge/thinforge-agent.new"
    exit 1
  fi
  chmod +x /data/thinforge/thinforge-agent.new
  if ! mv -f /data/thinforge/thinforge-agent.new /data/thinforge/thinforge-agent; then
    echo "[setup] ERROR: could not atomically replace agent binary (mv .new -> agent)"
    rm -f /data/thinforge/thinforge-agent.new 2>/dev/null
    exit 1
  fi
  # Wenn der Service schon laeuft, restart damit der neue Inhalt aktiv wird.
  # Beim ersten Install ist der Service noch nicht aktiv -> is-active liefert
  # 'inactive' und wir ueberspringen den restart (das Enable + Start kommt
  # weiter unten im Skript).
  if systemctl is-active --quiet thinforge-agent.service 2>/dev/null; then
    systemctl restart thinforge-agent.service \
      && echo "[setup] thinforge-agent.service restarted (new binary active)" \
      || echo "[setup] WARNING: thinforge-agent.service restart failed — check manually"
  fi
  AGENT_INSTALLED=true
  echo "[setup] Go agent installed from ISO"
fi

if [ "$AGENT_INSTALLED" = false ]; then
  echo "[setup] ERROR: thinforge-agent is missing from the Tools-ISO. Rebuild the Tools-ISO."
  exit 1
else
  cat > /data/thinforge/agent.conf <<AGENTCONF
[agent]
server_url = ${SERVER_URL:-https://thinforge-server}
AGENTCONF
  echo "[setup] agent.conf written (server URL: ${SERVER_URL})"

  cat > /etc/systemd/system/thinforge-agent.service <<AGENTSERVICE
[Unit]
Description=ThinForge Agent (Heartbeat + Updates)
After=network-online.target data.mount
Wants=network-online.target
Requires=data.mount

[Service]
Type=simple
ExecStart=/data/thinforge/thinforge-agent
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
AGENTSERVICE

  systemctl daemon-reload
  systemctl enable thinforge-agent.service
  echo "[setup] ThinForge Agent (Go) installed and enabled"
fi

# ── 6b. (entfaellt) Delta-Apply liegt im Go-Agent ──────────────────────────
# Frueher installierte dieser Schritt ein Shell-Skript agent-apply-delta.sh
# von der ISO. Die komplette Delta-Logik steckt seit dem Go-Agent im Binary
# (`thinforge-agent apply-delta` / `apply-update`, internal/applydelta) — der
# 6c-Shutdown-Service unten ruft genau dieses Binary. Die Datei liegt nicht
# mehr auf der ISO; der alte get_file-Aufruf erzeugte daher nur noch eine
# irrefuehrende "agent-apply-delta.sh not available"-WARNING und ist entfernt.

# ── 6c. agent-apply-update (Shutdown-Service) installieren ────────
#
# Ab Agent v2.13.0 ruft das ExecStop= direkt das Agent-Binary auf —
# der frueher dazwischengeschaltete Shim agent-apply-update.sh ist weg.
# Die Unit selbst ist unabhaengig von einer Skript-Datei und wird
# immer installiert (kein Gate mehr).

echo "[setup] Installing shutdown-update service..."

cat > /etc/systemd/system/agent-apply-update.service <<'APPLYSERVICE'
[Unit]
Description=ThinForge Apply Delta Update on Shutdown
After=local-fs.target data.mount
Requires=data.mount

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true
ExecStop=/data/thinforge/thinforge-agent apply-update
TimeoutStopSec=600

[Install]
WantedBy=multi-user.target
APPLYSERVICE

systemctl daemon-reload
systemctl enable agent-apply-update.service
echo "[setup] agent-apply-update installed and enabled"

# ── 6d. manual-manage-snapshots.sh installieren ─────────────────────────────

MANAGE_SNAPS_CONTENT=$(get_file "manual-manage-snapshots.sh")

if [ -n "${MANAGE_SNAPS_CONTENT}" ]; then
  echo "${MANAGE_SNAPS_CONTENT}" > /data/thinforge/manual-manage-snapshots.sh
  chmod +x /data/thinforge/manual-manage-snapshots.sh
  echo "[setup] manual-manage-snapshots.sh installed"
fi

# ── 6e. agent-notify-reboot.sh installieren ────────────────────────────────

NOTIFY_REBOOT_CONTENT=$(get_file "agent-notify-reboot.sh")

if [ -n "${NOTIFY_REBOOT_CONTENT}" ]; then
  echo "${NOTIFY_REBOOT_CONTENT}" > /opt/thinforge/agent-notify-reboot.sh
  chmod +x /opt/thinforge/agent-notify-reboot.sh
  echo "[setup] agent-notify-reboot.sh installed"
fi

# ── 7. Remote Desktop Abhaengigkeiten installieren ─────────────────────

echo "[setup] Remote Desktop dependencies are being installed..."
RD_SCRIPT=$(get_file "provision-remote-desktop.sh")
if [ -n "${RD_SCRIPT}" ]; then
  echo "${RD_SCRIPT}" | bash
else
  echo "[setup] WARNING: provision-remote-desktop.sh not available"
fi

# ── 8. WireGuard-Tools installieren (fuer VPN) ───────────────────────

echo "[setup] Installing WireGuard tools..."

if ! command -v wg &>/dev/null; then
  if command -v pacman &>/dev/null; then
    pacman -Sy --noconfirm wireguard-tools
  elif command -v apt-get &>/dev/null; then
    apt-get install -y -qq wireguard-tools
  elif command -v dnf &>/dev/null; then
    dnf install -y -q wireguard-tools
  fi
fi

if command -v wg &>/dev/null; then
  echo "[setup] WireGuard tools installed ($(wg --version 2>/dev/null || echo 'ok'))"
else
  echo "[setup] WARNING: WireGuard tools could not be installed"
fi

# ── Fertig ───────────────────────────────────────────────────────────

echo ""
echo "[setup] =========================================="
echo "[setup] Clone preparation complete!"
echo "[setup]   TLS cert:     installed (HTTPS)"
echo "[setup]   SSH key:      installed"
echo "[setup]   Hostname:     automatic via MAC"
echo "[setup]   Heartbeat:    every 60s with token"
echo "[setup]   Remote Desktop: x11vnc + zenity (Guacamole)"
echo "[setup]   WireGuard:    pre-installed (VPN)"
echo "[setup]   Server:       ${SERVER_URL}"
echo "[setup] =========================================="
echo "[setup] VM is ready to be cloned."
echo "[setup] After deployment all clients"
echo "[setup] are reachable via SSH/Ansible."
