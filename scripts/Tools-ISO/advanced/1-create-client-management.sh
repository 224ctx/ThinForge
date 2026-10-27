#!/bin/bash
# ThinForge — 1-create-client-management.sh
#
# Bereitet eine VM für das Klonen vor. Läuft AUSSCHLIESSLICH im ISO-Modus:
#
#   mount /dev/sr1 /mnt && bash /mnt/advanced/1-create-client-management.sh
#
# (Das Skript liegt auf der ISO unter advanced/; die install-*.sh im
# ISO-Wurzelverzeichnis rufen es in ihrem finish-Schritt selbst auf.)
#
# Die Tools-ISO ist die kanonische Provisioning-Quelle und enthält alle
# benötigten Dateien (provisioning_key.pub, server_url, heartbeat_token,
# server.crt, signing-pubkey, agent-binary samt minisign-Signatur, die
# Hilfsskripte unter advanced/). Das Agent-Binary wird vor dem Kopieren gegen den
# Signierschlüssel des Servers geprüft (Schritt 5). Der frühere
# curl|bash-Bootstrap-Modus über die öffentliche API wurde entfernt — er
# leakte das geteilte Heartbeat-Token und das Trust-Anchor-Material an
# jeden LAN-Host. Siehe docs/security/security-audit-2026-04-18.md F-CR-01 + F-CR-05.
#
# Installiert:
#   - SSH Public Key des Servers (für den SSH-Zugang des Servers nach dem
#     Deployment: Terminal, Befehle, Neustart, Inventur, Agent-Neuinstallation)
#   - SSH-Server (openssh-server) mit Key-only Auth
#   - ThinForge Agent (Go) + Token + Heartbeat
#   - Shutdown-Update-Dienst agent-apply-update.service; er ruft
#     `thinforge-agent apply-update` (apply-delta/apply-update sind seit dem
#     Go-Agent Unterbefehle des Binarys, keine Skripte mehr)
#   - manual-manage-snapshots.sh
#   - Remote-Desktop-Pakete ueber provision-remote-desktop.sh (x11vnc)
#   - tpm2-tools, falls `tpm2_getcap` fehlt (TPM-Status im Heartbeat)
#   - Journal dauerhaft unter /data/log/journal (Haertungspaket 2, V15)
#
# Die Agent-Unit kommt in zwei Fassungen (Haertungspaket 2, V6/V7): ab
# Agent v2.28.0 die gehaertete (Type=notify, Watchdog, Capability-Grenzen,
# OnFailure=thinforge-agent-recover.service), davor die bisherige. Welche,
# sagt die `agent-version` der Tools-ISO (optional; fehlt sie, die bisherige
# — die Migration zieht beim ersten Agent-Start nach). Die Texte stehen
# byte-gleich in agent-go/*.service und agent-migrate.sh
# (cloningvm_service::tools_iso_unit_tests).
#
set -u

# ── ISO-Mount validieren ─────────────────────────────────────────────
# Skript muss von der Tools-ISO ausgeführt werden. Bei curl|bash ist
# $0 = "bash" und SCRIPT_DIR ungültig — fail-fast.

if [ ! -f "$0" ]; then
  echo "[setup] ERROR: Script must be executed as a file, not via curl|bash."
  echo "[setup] Expected usage:"
  echo "[setup]   mount /dev/sr1 /mnt && bash /mnt/advanced/1-create-client-management.sh"
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

# ── Hilfsfunktion: minisign bereitstellen ────────────────────────────
# Die Installer (install-*.sh) bringen minisign schon mit; dieses Skript ist
# aber auch als Einzelaufruf dokumentiert. Ohne minisign liesse sich weder
# das Agent-Binary hier pruefen noch spaeter ein Update oder Delta — der
# Agent ruft dafuer selbst `minisign -V`.

ensure_minisign() {
  command -v minisign >/dev/null 2>&1 && return 0
  echo "[setup] Installing minisign..."
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq && apt-get install -y -qq minisign
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y -q minisign
  elif command -v pacman >/dev/null 2>&1; then
    pacman -Sy --noconfirm minisign
  fi
  command -v minisign >/dev/null 2>&1
}

# ── Hilfsfunktion: tpm2-tools bereitstellen ──────────────────────────
# Der Agent liest den TPM-Zustand ueber `tpm2_getcap`
# (agent-go/internal/tpm/tpm.go::Present); ohne das Paket meldet er auch auf
# Geraeten mit TPM "kein TPM" (tpm_present=false). Die install-*.sh haben
# tpm2-tools in ihrer Paketliste (EXTRA_PKGS); der Einzelaufruf dieses
# Skripts auf einem bestehenden System bekam es bis Runde 6 nicht (T149).
# Unabhaengig davon, ob DIESES System ein TPM hat: das Golden Image entsteht
# oft in einer VM ohne TPM, die Klone laufen auf Hardware mit TPM.

ensure_tpm2_tools() {
  command -v tpm2_getcap >/dev/null 2>&1 && return 0
  echo "[setup] Installing tpm2-tools..."
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq && apt-get install -y -qq tpm2-tools
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y -q tpm2-tools
  elif command -v pacman >/dev/null 2>&1; then
    pacman -Sy --noconfirm tpm2-tools
  fi
  command -v tpm2_getcap >/dev/null 2>&1
}

# ── Hilfsfunktion: Signatur des Agent-Binarys pruefen ────────────────
# verify_agent_signature BINARY SIGNATUR PUBKEY-DATEI
#
# Befund D14 (Review 2026-09-02): Bis 2026-09-14 kopierte Schritt 5 das
# Binary ungeprueft. Die ISO konnte dabei ein eingechecktes, veraltetes und
# unsigniertes Binary tragen, das so auf das Golden Image und jeden Klon kam.
# Geprueft wird gegen dieselbe Schluesseldatei, der der Agent spaeter bei
# jedem Update vertraut. Den Schluessel liest die Funktion wie der Go-Agent
# (minisign.ReadPubKeyLine): erste nicht leere Zeile ohne
# "untrusted comment:" — das vertraegt auch eine einzeilige Datei.

verify_agent_signature() {
  local binary="$1" signature="$2" pubkey_file="$3" pubkey
  if [ ! -s "${signature}" ]; then
    echo "[setup] ERROR: $(basename "${signature}") is missing from the Tools-ISO — the agent binary cannot be verified."
    return 1
  fi
  if [ ! -s "${pubkey_file}" ]; then
    echo "[setup] ERROR: signing key ${pubkey_file} is missing — the agent binary cannot be verified."
    return 1
  fi
  pubkey=$(grep -v '^untrusted comment:' "${pubkey_file}" | grep -m1 -E '[^[:space:]]' | tr -d '[:space:]' || true)
  if [ -z "${pubkey}" ]; then
    echo "[setup] ERROR: no public key found in ${pubkey_file} — the agent binary cannot be verified."
    return 1
  fi
  if ! ensure_minisign; then
    echo "[setup] ERROR: minisign is not installed and could not be installed — the agent binary cannot be verified."
    return 1
  fi
  if ! minisign -V -P "${pubkey}" -m "${binary}" -x "${signature}"; then
    echo "[setup] ERROR: signature check of the agent binary FAILED — it does not match its signature or this server's signing key."
    return 1
  fi
  echo "[setup] Agent binary signature verified"
}

# ── Hilfsfunktion: Versionstor der gehaerteten Unit ──────────────────
# unit_hardened_for_version VERSION — 0, wenn die gehaertete Unit gilt
# (Vergleich wie in agent-migrate.sh rein ueber sort -V).

UNIT_HARDENED_FROM="v2.28.0"
unit_hardened_for_version() {
  local v="$1"
  [ -n "${v}" ] || return 1
  [ "$(printf '%s\n' "${UNIT_HARDENED_FROM}" "${v}" | sort -V | head -n1)" = "${UNIT_HARDENED_FROM}" ]
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
# Das Go-Binary (thinforge-agent) von der ISO — nur nach bestandener
# Signaturpruefung gegen /data/thinforge/signing.pub (Schritt 4b).

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
  # Vor dem Kopieren: ein Binary, dessen Signatur nicht passt, kommt nicht
  # auf das System (auch nicht als .new).
  if ! verify_agent_signature "${SCRIPT_DIR}/thinforge-agent" \
       "${SCRIPT_DIR}/thinforge-agent.minisig" /data/thinforge/signing.pub; then
    echo "[setup] Refusing to install the agent. Build and sign it on the server"
    echo "[setup] (Clients → Agent), rebuild the Tools-ISO and run this script again."
    exit 1
  fi
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
  # Die geprueft Signatur neben die Binary (Haertungspaket 2, V7): der Agent
  # prueft sich beim Start dagegen, die Recover-Unit braucht sie fuer .prev.
  cp "${SCRIPT_DIR}/thinforge-agent.minisig" /data/thinforge/thinforge-agent.minisig \
    && chmod 644 /data/thinforge/thinforge-agent.minisig \
    && echo "[setup] Agent signature installed next to the binary" \
    || echo "[setup] WARNING: could not copy thinforge-agent.minisig next to the binary"
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
  echo "[setup] ERROR: thinforge-agent is missing from the Tools-ISO."
  echo "[setup] Build and sign the agent on the server (Clients → Agent), then rebuild the Tools-ISO."
  exit 1
else
  cat > /data/thinforge/agent.conf <<AGENTCONF
[agent]
server_url = ${SERVER_URL:-https://thinforge-server}
AGENTCONF
  echo "[setup] agent.conf written (server URL: ${SERVER_URL})"

  # Zwei Fassungen der Unit, Tor ueber die agent-version der ISO (s. Kopf).
  AGENT_VERSION_ISO=$(get_file "agent-version" 2>/dev/null | tr -d '[:space:]' || true)
  if unit_hardened_for_version "${AGENT_VERSION_ISO}"; then
    cat > /etc/systemd/system/thinforge-agent.service <<'AGENTUNIT_V2'
[Unit]
Description=ThinForge Agent (Heartbeat + Updates)
After=network-online.target data.mount
Wants=network-online.target
Requires=data.mount
StartLimitBurst=5
StartLimitIntervalSec=300
OnFailure=thinforge-agent-recover.service

[Service]
Type=notify
NotifyAccess=main
ExecStart=/data/thinforge/thinforge-agent
Restart=always
RestartSec=10
WatchdogSec=120
TimeoutStartSec=300
CapabilityBoundingSet=CAP_SYS_ADMIN CAP_DAC_OVERRIDE CAP_DAC_READ_SEARCH CAP_CHOWN CAP_FOWNER CAP_FSETID CAP_SETUID CAP_SETGID CAP_SETFCAP CAP_MKNOD CAP_AUDIT_WRITE CAP_SYS_CHROOT CAP_KILL CAP_SYS_PTRACE
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictRealtime=yes
LockPersonality=yes
SystemCallArchitectures=native
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6 AF_NETLINK
TasksMax=512
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
AGENTUNIT_V2
    cat > /etc/systemd/system/thinforge-agent-recover.service <<'RECOVERUNIT'
[Unit]
Description=ThinForge Agent Recovery (restores the signed previous binary, else retries in 5 min)
After=data.mount
Requires=data.mount

[Service]
Type=oneshot
TimeoutStartSec=400
ExecStart=/bin/bash -c ' \
    set -u; D=/data/thinforge; B=$$D/thinforge-agent; P=$$B.prev; A=thinforge-agent.service; \
    retry() { echo "agent-recover: retrying $$A in 5 min"; sleep 300; \
        if systemctl is-failed --quiet $$A; then systemctl reset-failed $$A; systemctl start --no-block $$A; echo "agent-recover: $$A started again"; \
        else echo "agent-recover: $$A is no longer failed - no retry"; fi; exit 0; }; \
    K=$$(grep -v "^untrusted comment:" "$$D/signing.pub" | grep -m1 . | tr -d "[:space:]"); \
    if [ ! -s "$$P" ] || [ ! -s "$$P.minisig" ] || [ -z "$$K" ]; then \
        echo "agent-recover: no signed previous binary - nothing to restore"; retry; fi; \
    if ! minisign -V -q -P "$$K" -m "$$P" -x "$$P.minisig"; then \
        echo "agent-recover: previous binary fails its signature check - not restored"; retry; fi; \
    F=$$(sha256sum "$$B" | cut -c1-8); \
    V=$$("$$P" version 2>/dev/null || grep -a -o -E "config[.]AgentVersion=v[0-9][0-9A-Za-z.-]*" "$$P" | head -1 | cut -d= -f2); \
    mv -f "$$B" "$$B.failed"; mv -f "$$P" "$$B"; mv -f "$$P.minisig" "$$B.minisig"; \
    { echo "restored=$$V"; echo "failed=$$F"; } > "$$D/agent-recovered"; \
    echo "agent-recover: restored agent $$V, failed binary $$F kept as thinforge-agent.failed"; \
    systemctl reset-failed $$A; systemctl start --no-block $$A'
RECOVERUNIT
    echo "[setup] thinforge-agent.service: hardened unit (agent ${AGENT_VERSION_ISO}) + thinforge-agent-recover.service"
  else
    cat > /etc/systemd/system/thinforge-agent.service <<'AGENTUNIT'
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
AGENTUNIT
    rm -f /etc/systemd/system/thinforge-agent-recover.service
    echo "[setup] thinforge-agent.service: classic unit (agent ${AGENT_VERSION_ISO:-unknown}, hardened unit from ${UNIT_HARDENED_FROM})"
  fi

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
#
# Die Unit kommt als Datei von der ISO (advanced/agent-apply-update.service)
# — EINE Quelle. Bis 2026-10-01 schrieb dieses Skript einen eigenen Heredoc,
# und die Datei im Repo war eine zweite, aeltere Fassung ohne data.mount.
# agent-migrate.sh traegt eine Kopie fuer Bestandsgeraete (es wird einzeln
# ausgeliefert); dass sie der Datei gleicht, prueft
# cloningvm_service::tools_iso_unit_tests.
#
# Warum data.mount: ExecStop startet das Binary von /data. `After=` ordnet
# das Stoppen dieser Unit beim Herunterfahren VOR das Aushaengen von /data;
# ueber local-fs.target allein gilt das nur, solange /data ohne `nofail`
# eingehaengt ist. `Requires=` laesst die Unit gar nicht erst starten, wenn
# /data nicht eingehaengt wurde.

echo "[setup] Installing shutdown-update service..."

APPLY_UNIT_CONTENT=$(get_file "agent-apply-update.service")
if [ -z "${APPLY_UNIT_CONTENT}" ]; then
  echo "[setup] ERROR: agent-apply-update.service is missing from the Tools-ISO."
  echo "[setup] Without it the client never applies updates at shutdown. Rebuild the Tools-ISO."
  exit 1
fi
printf '%s\n' "${APPLY_UNIT_CONTENT}" > /etc/systemd/system/agent-apply-update.service

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

# ── 6e. (entfaellt) Neustart-Dialog liegt im Go-Agent ─────────────────────
# Frueher holte dieser Schritt agent-notify-reboot.sh von der ISO. Seit Agent
# v2.13.0 zeigt der Agent den Dialog selbst (`thinforge-agent notify-reboot`,
# internal/notify); die Datei liegt nicht mehr auf der ISO, der Schritt tat
# also nichts mehr. agent-migrate.sh entfernt alte Kopien auf Bestandsgeraeten.

# ── 7. Remote Desktop Abhaengigkeiten installieren ─────────────────────

echo "[setup] Remote Desktop dependencies are being installed..."
RD_SCRIPT=$(get_file "provision-remote-desktop.sh")
if [ -n "${RD_SCRIPT}" ]; then
  echo "${RD_SCRIPT}" | bash
else
  echo "[setup] WARNING: provision-remote-desktop.sh not available"
fi

# ── 7b. tpm2-tools (TPM-Status im Heartbeat) ───────────────────────────
# Best effort: ohne Paketquellen bleibt es bei einer Warnung — betroffen ist
# nur die TPM-Statusmeldung des Agenten, nicht Heartbeat oder Updates.

if ensure_tpm2_tools; then
  echo "[setup] tpm2-tools available (TPM status in the heartbeat)"
else
  echo "[setup] WARNING: tpm2-tools could not be installed — the agent will report"
  echo "[setup]          no TPM (tpm_present=false), even on devices that have one."
  echo "[setup]          Install tpm2-tools by hand and run this script again."
fi

# ── 7c. Journal dauerhaft auf /data (Haertungspaket 2, V15) ────────────
# Ein Subvolume-Tausch ersetzt @rootfs samt /var/log/journal. Deshalb liegt
# das Journal unter /data/log/journal, /var/log/journal ist ein Symlink
# dorthin, ein Drop-in erzwingt Storage=persistent (Deckel 200 MB). Dieselben
# drei Schritte wiederholt agent-migrate.sh bei jedem Agent-Start (Drift-
# Reparatur nach dem Tausch); hier wie dort wird ein vorhandenes echtes
# Verzeichnis verschoben, nicht geloescht.

echo "[setup] Moving the journal to /data/log/journal..."
mkdir -p /data/log/journal
if [ -d /var/log/journal ] && [ ! -L /var/log/journal ]; then
  cp -a /var/log/journal/. /data/log/journal/
  rm -rf /var/log/journal.migrated
  mv /var/log/journal /var/log/journal.migrated
fi
if [ ! -L /var/log/journal ] || [ "$(readlink /var/log/journal)" != "/data/log/journal" ]; then
  rm -rf /var/log/journal
  ln -s /data/log/journal /var/log/journal
fi
chmod 0755 /data/log/journal
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/thinforge.conf <<'JOURNALD'
[Journal]
Storage=persistent
SystemMaxUse=200M
JOURNALD
journalctl --rotate 2>/dev/null || true
journalctl --flush 2>/dev/null || true
rm -rf /var/log/journal.migrated
echo "[setup] Journal persistent under /data/log/journal (/var/log/journal is a symlink)"

# ── 8. (entfaellt) WireGuard-Tools ───────────────────────────────────
# Bis 2026-10-01 installierte dieser Schritt `wireguard-tools`. Den
# VPN-Transport bringt der NetBird-Client selbst mit (statisch gelinkt, ohne
# Paketabhaengigkeit auf wireguard-tools); weder der Agent noch ein Skript
# ruft `wg` auf. Den Tunnel-Zustand zeigt `netbird status -d`.

# ── Fertig ───────────────────────────────────────────────────────────

echo ""
echo "[setup] =========================================="
echo "[setup] Clone preparation complete!"
echo "[setup]   TLS cert:     installed (HTTPS)"
echo "[setup]   SSH key:      installed"
echo "[setup]   Hostname:     automatic via MAC"
echo "[setup]   Heartbeat:    with token (interval set by the server, default 10s)"
echo "[setup]   Remote Desktop: x11vnc (Guacamole VNC)"
echo "[setup]   Server:       ${SERVER_URL}"
echo "[setup] =========================================="
echo "[setup] VM is ready to be cloned."
echo "[setup] After deployment all clients"
echo "[setup] are reachable via SSH."
