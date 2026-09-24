#!/usr/bin/env bash
# deploy.sh — Pull the ThinForge container images from the registry and
# (re-)start the stack. Does NOT build anything — source trees under
# crates/, agent-go/ etc. are intentionally absent in the Release repo.
#
# Usage:
#   ./deploy.sh              # pull + up -d
#   ./deploy.sh --pull-only  # pull images, do not touch the stack

set -euo pipefail

# Gemeinsame Helfer wie in rebuild.sh: setzt PROJECT_ROOT und wechselt dorthin,
# damit die relativen Pfade unten (.env, docker/caddy/Caddyfile, Compose-Datei)
# auch stimmen, wenn deploy.sh aus einem anderen Verzeichnis gestartet wird.
# load_storage_dir folgt bewusst erst NACH der .env-Vorpruefung: es wuerde ueber
# ensure_env_file eine fehlende .env selbst erzeugen und damit den
# ausdruecklichen Abbruch unten aushebeln — auf einem Release-Host soll der
# Betreiber die .env sehen und bearbeiten, nicht zufaellige Werte geschenkt
# bekommen.
source "$(cd "$(dirname "$0")" && pwd)/scripts/lib-env.sh"
init_project_root

COMPOSE_FILE="docker-compose.yml"

# Start profiles mirror the Dev-side default (rebuild.sh). Cloner/cloning-vm
# are on-demand only (UI-triggered QEMU VMs), not started here.
ALL_PROFILES=(network testing monitoring cloner multicast bittorrent)
START_PROFILES=(network monitoring)

PULL_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --pull-only) PULL_ONLY=1 ;;
    --help|-h)
      # Genau den Kopfkommentar zeigen — `grep '^#' | head` zog sonst je nach
      # Dateiaufbau noch eine beliebige spaetere Kommentarzeile mit hinein.
      sed -n '2,8p' "$0"
      exit 0 ;;
    *)
      echo "Unknown option: $arg"; exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
# Pre-flight: .env + registry login
# ---------------------------------------------------------------------------
if [ ! -f .env ]; then
  echo "ERROR: .env missing. Create one from .env.example first:"
  echo "  cp .env.example .env && \"\${EDITOR:-nano}\" .env"
  exit 1
fi

# STORAGE_DIR aus derselben Quelle wie docker compose aufloesen (Shell-Umgebung
# schlaegt .env, .env schlaegt ./ThinForgeDaten) und exportieren. Vorher las
# deploy.sh nur die Shell-Umgebung: mit einem eigenen STORAGE_DIR in der .env
# legte es Verzeichnisbaum, TLS-Zertifikat, Caddyfile und die exports-DATEI
# unter ./ThinForgeDaten an, waehrend Compose ${STORAGE_DIR} aus der .env
# mountete. Docker legt jede fehlende Bind-Quelle als VERZEICHNIS an — aus
# nfs-config/exports wurde ein Verzeichnis, der nfs-server ging in den
# Restart-Loop, und Caddy fand kein Zertifikat.
load_storage_dir

# ---------------------------------------------------------------------------
# .env migrations — identisch zu rebuild.sh (F-HI-09 + Services-Panel-Filter).
# REDIS_PASSWORD kommt aus scripts/lib-env.sh::ensure_env_secrets (in
# load_storage_dir oben) — vor dem ersten compose-Aufruf, sonst scheitert
# schon `pull` an `${REDIS_PASSWORD:?}`.
# Existierende .env-Dateien ohne SEMAPHORE_ADMIN_PASSWORD bekommen eine
# frische Random-Passphrase; sonst bricht Semaphore beim Up.
# ---------------------------------------------------------------------------
SEMAPHORE_PW_RESET_NEEDED=0
if ! grep -q '^SEMAPHORE_ADMIN_PASSWORD=' .env; then
  PASS=$(openssl rand -base64 32 2>/dev/null | tr -d '\n/+=' \
    || head -c 32 /dev/urandom | base64 | tr -d '\n/+=')
  printf '\n# Semaphore admin (auto-added by deploy.sh — F-HI-09)\nSEMAPHORE_ADMIN_PASSWORD=%s\n' \
    "$PASS" >> .env
  echo "[migration] SEMAPHORE_ADMIN_PASSWORD ergaenzt in .env"
  SEMAPHORE_PW_RESET_NEEDED=1
fi

# Services-Panel-Filter: Standard nur nachziehen, wo die Zeile fehlt, leer
# ist oder einen frueheren Standard traegt — ein eigener Wert bleibt stehen
# (scripts/lib-env.sh::ensure_enabled_profiles, Review 2026-09-02, B1).
ensure_enabled_profiles "$(IFS=,; echo "${START_PROFILES[*]},testing,cloner,bittorrent,multicast")" deploy.sh

COMPOSE_CMD=(docker compose -f "$COMPOSE_FILE")
PROFILE_FLAGS=();      for p in "${ALL_PROFILES[@]}";   do PROFILE_FLAGS+=("--profile" "$p");   done
START_PROFILE_FLAGS=(); for p in "${START_PROFILES[@]}"; do START_PROFILE_FLAGS+=("--profile" "$p"); done

echo "============================================"
echo " ThinForge — Deploy (pull-only)"
echo " Compose: $COMPOSE_FILE"
echo " Storage: $STORAGE_DIR"
echo "============================================"

echo ""
echo "[1/4] Pulling images from git.thinforge.org/thinforge/*..."
"${COMPOSE_CMD[@]}" "${PROFILE_FLAGS[@]}" pull

# Backend-Services rufen einige Images noch mit Short-Name auf
# (delta_runner.rs -> 'thinforge-cloner', cloningvm_service.rs -> 'thinforge-cloner',
#  host_network_service.rs -> 'thinforge-backend'). Auf Release-Hosts existieren
# die Short-Names nicht, nur die Registry-qualifizierten Tags. Alias-Tag setzen,
# damit 'docker run thinforge-cloner' ohne Registry-Query landet.
for img in backend worker frontend bt-seeder cloner cloning-vm chrony dnsmasq multicast-sender nfs-server; do
  ref="$(grep -oE "^[[:space:]]*image: git\.thinforge\.org/thinforge/thinforge-${img}:[A-Za-z0-9._-]+" "$COMPOSE_FILE" \
        | head -1 | awk '{print $2}')"
  [ -n "$ref" ] || continue
  docker tag "$ref" "thinforge-${img}:latest" 2>/dev/null || true
done

if [ "$PULL_ONLY" = "1" ]; then
  echo ""; echo "--pull-only requested; done."; exit 0
fi

echo ""
echo "[2/4] Preparing storage directories..."
STORAGE_DIRS=(
  postgres dnsmasq netbird-config tftp isos cloning-vm clones captures deltas
  ssh keys chrony caddy/data caddy/config caddy/certs
  semaphore/data semaphore/config semaphore/tmp semaphore/playbooks
  bittorrent nfs-config
)
for dir in "${STORAGE_DIRS[@]}"; do
  sudo mkdir -p "${STORAGE_DIR}/${dir}"
done

sudo chown -R 1001:0 "${STORAGE_DIR}/semaphore"
sudo mkdir -p "${STORAGE_DIR}/prometheus" && sudo chown 65534:65534 "${STORAGE_DIR}/prometheus"
sudo mkdir -p "${STORAGE_DIR}/grafana"    && sudo chown 472:0       "${STORAGE_DIR}/grafana"
sudo mkdir -p "${STORAGE_DIR}/vulnerability-scans/sbom" "${STORAGE_DIR}/vulnerability-scans/grype"
sudo chown -R "$(id -u):$(id -g)" "${STORAGE_DIR}/vulnerability-scans"

# NFS exports must be a file, not a directory
if [ -d "${STORAGE_DIR}/nfs-config/exports" ]; then
  sudo rm -rf "${STORAGE_DIR}/nfs-config/exports"
fi
if [ ! -f "${STORAGE_DIR}/nfs-config/exports" ]; then
  echo "# ThinForge NFS exports — managed by backend" | sudo tee "${STORAGE_DIR}/nfs-config/exports" > /dev/null
fi

# Self-signed TLS cert on first run
CERT_FILE="${STORAGE_DIR}/caddy/certs/server.crt"
KEY_FILE="${STORAGE_DIR}/caddy/certs/server.key"
if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
  HOSTNAME_VAL=$(hostname -f 2>/dev/null || hostname)
  sudo openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$KEY_FILE" -out "$CERT_FILE" \
    -days 365 -subj "/O=ThinForge/CN=${HOSTNAME_VAL}" \
    -addext "subjectAltName=DNS:${HOSTNAME_VAL},DNS:localhost,IP:127.0.0.1" 2>/dev/null
  sudo chmod 600 "$KEY_FILE"
  echo "  TLS certificate generated for CN=${HOSTNAME_VAL}"
fi

# Caddyfile: source of truth is docker/caddy/Caddyfile (shipped in Release)
sudo install -m 0644 docker/caddy/Caddyfile "${STORAGE_DIR}/caddy/Caddyfile"

# Kernel modules needed for NFS + NBD
sudo modprobe nbd max_part=16 2>/dev/null || true
sudo modprobe nfs 2>/dev/null || true
sudo modprobe nfsd 2>/dev/null || true

echo ""
echo "[3/4] Stopping running containers..."
"${COMPOSE_CMD[@]}" "${PROFILE_FLAGS[@]}" down --remove-orphans || true

echo ""
echo "[4/4] Starting stack (VMs excluded — start via UI)..."
"${COMPOSE_CMD[@]}" "${START_PROFILE_FLAGS[@]}" up -d

# ---------------------------------------------------------------------------
# Semaphore admin-password DB rotation (F-HI-09). Only fires when the
# .env migration above added a fresh password AND the semaphore container
# is actually running (seit 2026-04-20 ist der Service in der Registry-
# Compose auskommentiert; die Rotation ist dann ein No-Op).
# ---------------------------------------------------------------------------
if [ "$SEMAPHORE_PW_RESET_NEEDED" = "1" ] && docker ps --format '{{.Names}}' | grep -q '^thinforge-semaphore-1$'; then
  echo ""
  echo "[migration] Rotating Semaphore admin password in running DB..."
  for _i in $(seq 1 30); do
    if docker exec thinforge-semaphore-1 wget -qO/dev/null http://localhost:3000 2>/dev/null; then break; fi
    sleep 2
  done
  PASS=$(grep '^SEMAPHORE_ADMIN_PASSWORD=' .env | cut -d= -f2-)
  if docker exec thinforge-semaphore-1 semaphore users change-by-login \
       --login admin --password "$PASS" --config /etc/semaphore/config.json >/dev/null 2>&1; then
    echo "[migration] Semaphore-Admin-Passwort rotiert"
  else
    # Kein Klartext-Passwort in der Ausgabe (Terminal-Verlauf, Install-Logs,
    # CI) — der vorgeschlagene Befehl liest den Wert selbst aus der .env.
    echo "[migration] WARN: Semaphore-PW-Reset fehlgeschlagen, manuell nachholen (Passwort: SEMAPHORE_ADMIN_PASSWORD in .env):"
    echo "  docker exec thinforge-semaphore-1 semaphore users change-by-login \\"
    echo "    --login admin --password \"\$(grep '^SEMAPHORE_ADMIN_PASSWORD=' .env | cut -d= -f2-)\" --config /etc/semaphore/config.json"
  fi
fi

echo ""
echo "============================================"
echo " Done. Container status:"
echo "============================================"
"${COMPOSE_CMD[@]}" "${START_PROFILE_FLAGS[@]}" ps
echo ""
df -h / | tail -1 | awk '{print "  Disk: " $3 " used / " $4 " free (" $5 " full)"}'
