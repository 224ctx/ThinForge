#!/usr/bin/env bash
#
# export-xfce-config.sh — XFCE-Einstellungen aus der Cloning-VM exportieren
#
# Erstellt ein importierbares ZIP-Paket mit thinforge.yml Manifest,
# Ansible-Playbook und Rolle fuer den Automation-Tab.
#
# Usage:
#   ./scripts/export-xfce-config.sh [--user=thinforge] [--port=2222] [--host=localhost]
#   ./scripts/export-xfce-config.sh --ip=192.168.20.5   # direkt von einem Client
#
# Output: backup/xfce-desktop-konfiguration.zip

set -euo pipefail

# -- Defaults ------------------------------------------------------------------
SSH_USER="root"
XFCE_USER="thinforge"
SSH_PORT="2222"
SSH_HOST="localhost"
SSH_KEY=""
DIRECT_IP=""

# -- Hilfsfunktionen -----------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log()   { echo -e "${GREEN}[export]${NC} $*"; }
error() { echo -e "${RED}[export]${NC} $*" >&2; }
fatal() { error "$*"; exit 1; }

# -- Argumente parsen ----------------------------------------------------------
for arg in "$@"; do
  case "$arg" in
    --user=*)  XFCE_USER="${arg#--user=}" ;;
    --port=*)  SSH_PORT="${arg#--port=}" ;;
    --host=*)  SSH_HOST="${arg#--host=}" ;;
    --ip=*)    DIRECT_IP="${arg#--ip=}" ;;
    --key=*)   SSH_KEY="${arg#--key=}" ;;
    --help|-h)
      echo "Usage: $0 [--user=thinforge] [--port=2222] [--host=localhost] [--ip=CLIENT_IP] [--key=SSH_KEY]"
      echo ""
      echo "  --user    Desktop-User auf dem Zielrechner (default: thinforge)"
      echo "  --port    SSH-Port (default: 2222, fuer Cloning-VM)"
      echo "  --host    SSH-Host (default: localhost)"
      echo "  --ip      Direkte IP eines Clients (nutzt Port 22 und Provisioning-Key)"
      echo "  --key     Pfad zum SSH-Key (default: auto-detect aus ThinForgeDaten/ssh/)"
      echo ""
      echo "Output: backup/xfce-desktop-konfiguration.zip"
      exit 0
      ;;
    *) fatal "Unbekanntes Argument: $arg (--help fuer Hilfe)" ;;
  esac
done

# -- Projekt-Root finden -------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# -- Aufraeumen ----------------------------------------------------------------
# EIN Trap fuer alles Temporaere. Ein zweites `trap ... EXIT` weiter unten
# ersetzte den ersten, und die Schluesselkopie bliebe liegen.
TMP_KEY=""
WORK_DIR=""
cleanup() {
  if [ -n "$TMP_KEY" ]; then rm -f "$TMP_KEY"; fi
  if [ -n "$WORK_DIR" ]; then rm -rf "$WORK_DIR"; fi
}
trap cleanup EXIT

# -- SSH-Key finden ------------------------------------------------------------
# Kein fester Pfad unter /tmp als Kandidat: eine dort abgelegte Datei eines
# anderen Kontos wuerde sonst still als SSH-Identitaet uebernommen.
if [ -z "$SSH_KEY" ] && [ -f "$PROJECT_ROOT/ThinForgeDaten/ssh/provisioning_key" ]; then
  SSH_KEY="$PROJECT_ROOT/ThinForgeDaten/ssh/provisioning_key"
fi

if [ -z "$SSH_KEY" ]; then
  # Key aus dem Container in eine frische Datei kopieren, die mktemp mit 0600
  # anlegt, BEVOR der Schluessel hineinfliesst; der Trap loescht sie am Ende.
  # Frueher landete er in der festen Datei /tmp/tf_key, beim Umlenken mit der
  # umask angelegt (fuer alle lesbar) und nie geloescht — dieser Schluessel
  # oeffnet root-SSH auf jedem verwalteten Geraet.
  log "SSH-Key aus Container kopieren..."
  TMP_KEY=$(mktemp)
  docker compose exec -T backend cat /data/ssh/provisioning_key > "$TMP_KEY" 2>/dev/null \
    || fatal "SSH-Key nicht aus dem Backend-Container lesbar. Nutze --key=PFAD"
  SSH_KEY="$TMP_KEY"
fi

[ -s "$SSH_KEY" ] || fatal "SSH-Key nicht gefunden. Nutze --key=PFAD"

# -- SSH-Verbindung konfigurieren ---------------------------------------------
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"

if [ -n "$DIRECT_IP" ]; then
  SSH_HOST="$DIRECT_IP"
  SSH_PORT="22"
  log "Verbinde direkt zu Client $DIRECT_IP:22"
else
  log "Verbinde zur Cloning-VM $SSH_HOST:$SSH_PORT"
fi

SSH_CMD="ssh $SSH_OPTS -p $SSH_PORT -i $SSH_KEY $SSH_USER@$SSH_HOST"

# -- Verbindung testen --------------------------------------------------------
log "SSH-Verbindung testen..."
$SSH_CMD "hostname" >/dev/null 2>&1 || fatal "SSH-Verbindung fehlgeschlagen ($SSH_HOST:$SSH_PORT)"
REMOTE_HOST=$($SSH_CMD "hostname" 2>/dev/null)
log "Verbunden mit: $REMOTE_HOST"

# -- XFCE-Config vom Remote holen ---------------------------------------------
log "XFCE-Konfiguration von /home/$XFCE_USER/.config exportieren..."

REMOTE_DIRS="xfce4/ autostart/ gtk-3.0/"
CONFIG_ARCHIVE=$($SSH_CMD "
  cd /home/$XFCE_USER/.config 2>/dev/null || exit 1
  tar czf /tmp/xfce-config-export.tar.gz $REMOTE_DIRS 2>/dev/null
  base64 /tmp/xfce-config-export.tar.gz
  rm -f /tmp/xfce-config-export.tar.gz
" 2>/dev/null | grep -v "^Warning:")

[ -n "$CONFIG_ARCHIVE" ] || fatal "Konnte XFCE-Config nicht exportieren. Existiert /home/$XFCE_USER/.config/xfce4/?"

# -- ZIP-Paket zusammenbauen --------------------------------------------------
log "ZIP-Paket erstellen..."

WORK_DIR=$(mktemp -d)

# Config-Archiv decodieren
echo "$CONFIG_ARCHIVE" | base64 -d > "$WORK_DIR/xfce-config.tar.gz"

# Rolle erstellen
mkdir -p "$WORK_DIR/roles/xfce-config/files"
mkdir -p "$WORK_DIR/roles/xfce-config/tasks"
mv "$WORK_DIR/xfce-config.tar.gz" "$WORK_DIR/roles/xfce-config/files/"

cat > "$WORK_DIR/roles/xfce-config/tasks/main.yml" << 'ROLE_EOF'
---
- name: Set user home fact
  ansible.builtin.set_fact:
    xfce_home: "/home/{{ xfce_user | default('thinforge') }}"

- name: Ensure .config directory exists
  ansible.builtin.file:
    path: "{{ xfce_home }}/.config"
    state: directory
    owner: "{{ xfce_user | default('thinforge') }}"
    group: "{{ xfce_user | default('thinforge') }}"
    mode: "0755"

- name: Extract XFCE configuration
  ansible.builtin.unarchive:
    src: xfce-config.tar.gz
    dest: "{{ xfce_home }}/.config/"
    owner: "{{ xfce_user | default('thinforge') }}"
    group: "{{ xfce_user | default('thinforge') }}"
ROLE_EOF

# Playbook erstellen
cat > "$WORK_DIR/apply-xfce-config.yml" << 'PLAY_EOF'
---
- name: Apply XFCE desktop configuration
  hosts: all
  become: true
  gather_facts: true

  roles:
    - role: xfce-config
      vars:
        xfce_user: thinforge
PLAY_EOF

# Manifest erstellen
TIMESTAMP=$(date +%Y-%m-%d)
cat > "$WORK_DIR/thinforge.yml" << MANIFEST_EOF
name: "XFCE Desktop-Konfiguration"
playbook: apply-xfce-config.yml
description: "XFCE-Einstellungen exportiert von $REMOTE_HOST am $TIMESTAMP"
MANIFEST_EOF

# ZIP erstellen
mkdir -p "$PROJECT_ROOT/backup"
OUTPUT="$PROJECT_ROOT/backup/xfce-desktop-konfiguration.zip"

python3 -c "
import zipfile, os
os.chdir('$WORK_DIR')
with zipfile.ZipFile('$OUTPUT', 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk('.'):
        for f in files:
            path = os.path.join(root, f)
            zf.write(path, path[2:])
"

SIZE=$(du -h "$OUTPUT" | cut -f1)

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  XFCE-Konfiguration exportiert!${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Quelle:   $REMOTE_HOST (/home/$XFCE_USER/.config/)"
echo -e "  Datei:    $OUTPUT"
echo -e "  Groesse:  $SIZE"
echo ""
echo -e "  ${GREEN}Import:${NC} Im ThinForge-UI unter Clients → Automation → Hochladen"
echo ""
