#!/bin/bash
#
# ThinForge — SSH aktivieren + Server-Key installieren
#
# Schnellzugriff per SSH auf die VM, ohne den vollen Agent zu installieren.
# Liest den Provisioning-Key von der Tools-ISO oder vom Server.
#
# Verwendung (in der VM):
#   sudo mount /dev/sr1 /mnt
#   sudo bash /mnt/enable-ssh.sh
#

set -euo pipefail

echo "[ssh] ThinForge SSH-Schnellzugriff einrichten..."

# ── Modus erkennen (ISO oder curl) ───────────────────────────────────
SCRIPT_DIR=""
MODE="standalone"
if [ -f "$0" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    if [ -f "${SCRIPT_DIR}/provisioning_key.pub" ]; then
        MODE="iso"
    fi
fi

# ── SSH-Key laden ────────────────────────────────────────────────────
SSH_KEY=""

if [ "$MODE" = "iso" ]; then
    SSH_KEY=$(cat "${SCRIPT_DIR}/provisioning_key.pub")
    echo "[ssh] Key von ISO geladen"
fi

# Curl-Bootstrap-Modus wurde aus Sicherheitsgruenden entfernt
# (siehe docs/security/security-audit-2026-04-18.md F-CR-01). Tools-ISO ist die
# einzige SSH-Key-Quelle.

if [ -z "$SSH_KEY" ]; then
    echo "[ssh] FEHLER: No SSH key found (provisioning_key.pub is missing from ISO)!"
    echo "[ssh] Starte von der Tools-ISO."
    exit 1
fi

# ── SSH installieren (falls noetig) ──────────────────────────────────
if ! command -v sshd &>/dev/null; then
    echo "[ssh] SSH-Server installieren..."
    if command -v pacman &>/dev/null; then
        pacman -Sy --noconfirm openssh
    elif command -v apt-get &>/dev/null; then
        apt-get update -qq && apt-get install -y -qq openssh-server
    fi
fi

# ── SSH-Key installieren ─────────────────────────────────────────────
mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo "$SSH_KEY" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
echo "[ssh] Key installiert: /root/.ssh/authorized_keys"

# ── SSH konfigurieren ────────────────────────────────────────────────
if [ -f /etc/ssh/sshd_config ]; then
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    # Passwort-Login deaktivieren — nur Server-Key erlaubt. Ohne diese beiden
    # Zeilen bleibt Debians Default `PasswordAuthentication yes` stehen: das
    # Skript haerteter nur root, waehrend das Desktop-/Autologin-Konto (das
    # install-debian-minimal.sh in die Gruppe sudo steckt) per Passwort aus
    # dem LAN erreichbar bleibt — und das LAN ist in diesem Modell der
    # Angreifer. Gleiche Behandlung wie in 1-create-client-management.sh,
    # install-debian.sh, install-debian-minimal.sh und install-arch.sh; wird
    # das Skript nie gefolgt von 1-create-client-management.sh ausgefuehrt,
    # wird das Abbild sonst in diesem Zustand geklont.
    if grep -q "^#\?PasswordAuthentication" /etc/ssh/sshd_config; then
        sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    else
        echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
    fi
    if grep -q "^#\?KbdInteractiveAuthentication" /etc/ssh/sshd_config; then
        sed -i 's/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config
    else
        echo "KbdInteractiveAuthentication no" >> /etc/ssh/sshd_config
    fi
    echo "[ssh] sshd: nur Key-Authentifizierung (Passwort-Login aus)"
else
    echo "[ssh] WARNUNG: /etc/ssh/sshd_config nicht gefunden — Passwort-Login NICHT deaktiviert!"
fi

# Host-Keys generieren falls noetig
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    ssh-keygen -A
fi

# ── SSH starten ──────────────────────────────────────────────────────
systemctl enable sshd 2>/dev/null || systemctl enable ssh 2>/dev/null || true
systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null || true

if systemctl is-active sshd &>/dev/null || systemctl is-active ssh &>/dev/null; then
    echo "[ssh] sshd laeuft"
else
    echo "[ssh] Direktstart..."
    /usr/sbin/sshd 2>/dev/null || true
fi

# ── IP anzeigen ──────────────────────────────────────────────────────
IP=$(ip -4 addr show scope global 2>/dev/null | awk '/inet / {split($2,a,"/"); print a[1]; exit}')
echo ""
echo "[ssh] =========================================="
echo "[ssh] SSH bereit!"
echo "[ssh]   IP:    ${IP:-unbekannt}"
echo "[ssh]   User:  root (nur Key-Auth; Passwort-Login systemweit aus)"
echo "[ssh]   Port:  22"
echo "[ssh] =========================================="
