#!/usr/bin/env bash
# lib-env.sh — Shared environment helpers for ThinForge scripts
# Source this file: source "$(dirname "$0")/scripts/lib-env.sh"
#
# Alle Pfade werden relativ zum Verzeichnis aufgeloest, in dem das
# aufrufende Script liegt. Dadurch funktionieren rebuild.sh und
# clean-reset.sh aus jedem beliebigen Installationsverzeichnis.

# ── Project Root ermitteln ──────────────────────────────────────────
# PROJECT_ROOT ist das Verzeichnis in dem docker-compose.yml liegt.
# Ermittelt aus dem Pfad von lib-env.sh selbst (liegt in scripts/).
init_project_root() {
  # lib-env.sh liegt in scripts/ — eine Ebene hoch ist der Project Root
  local lib_dir
  lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(cd "${lib_dir}/.." && pwd)"
  export PROJECT_ROOT
  # Sicherstellen dass wir im Project Root arbeiten
  cd "$PROJECT_ROOT"
}

# ── Sicheren Zufallswert erzeugen ──────────────────────────────────
# 32 Byte Base64 ohne `/`, `+`, `=` — also nur Buchstaben und Ziffern.
# Das ist Absicht: die Werte landen in URLs (REDIS_URL) und werden von
# docker compose interpoliert; ein `$`, `@`, `:` oder `/` braeche das.
gen_secret() {
  openssl rand -base64 32 2>/dev/null | tr -d '\n/+=' \
    || head -c 32 /dev/urandom | base64 | tr -d '\n/+='
}

# ── Pflicht-Secrets in einer BESTEHENDEN .env nachziehen ───────────
# Variablen, die nach der Erst-Erzeugung der .env dazugekommen sind.
# Idempotent: jede fehlende Variable wird genau einmal mit einem frischen
# Zufallswert ANGEHAENGT (`>>`, nie `sed -i`: die .env ist als Einzeldatei
# in den Backend-Container gemountet und haengt am Inode — eine neu
# geschriebene Datei saehe der laufende Container nicht).
#
# Ohne diesen Schritt scheitert JEDER compose-Aufruf an der strikten
# Interpolation (`${REDIS_PASSWORD:?…}`) — auch `docker compose down`, das
# clean-reset.sh mit `|| true` schluckt, bevor es Datenverzeichnisse loescht.
# Deshalb laeuft das hier in load_storage_dir und nicht nur in rebuild.sh.
#
# Aufrufer, die die Variable nachgetragen bekommen, muessen die betroffenen
# Container neu erzeugen (`up -d --force-recreate redis backend worker`);
# `docker compose up -d` tut das von selbst, weil sich die Konfiguration
# der drei Dienste geaendert hat.
ensure_env_secrets() {
  local env_file="${PROJECT_ROOT}/.env"
  [ -f "$env_file" ] || return 0

  if ! grep -q '^REDIS_PASSWORD=' "$env_file"; then
    printf '\n# Redis-Passwort (automatisch ergaenzt von scripts/lib-env.sh; Review 2026-09-02 S5-1)\n# Aenderung erfordert: docker compose up -d --force-recreate redis backend worker\nREDIS_PASSWORD=%s\n' \
      "$(gen_secret)" >> "$env_file"
    echo "  [migration] REDIS_PASSWORD ergaenzt in .env — redis, backend und worker werden beim naechsten 'up -d' neu erzeugt"
  fi
}

# ── Services-Panel-Filter in .env pflegen ──────────────────────────
# THINFORGE_ENABLED_PROFILES sagt dem Backend, welche Compose-Profile zu
# dieser Installation gehoeren (compose::enabled_profiles_from_env); das
# Services-Panel blendet Dienste anderer Profile aus. rebuild.sh und
# deploy.sh uebergeben ihren Standard (START_PROFILES + on-demand-Profile).
#
# Nachgezogen wird nur, was die Skripte selbst einmal geschrieben haben: eine
# fehlende Zeile, der leere Wert aus .env.example und fruehere Standards
# (ENABLED_PROFILES_FRUEHERE_STANDARDS). Jeden anderen Wert hat der Betrieb
# gesetzt — .env.example bietet das an, z. B. `testing` weglassen auf Hosts
# ohne KVM — und er bleibt stehen. Bis 2026-09-23 schrieben beide Skripte
# jeden abweichenden Wert bei jedem Lauf auf ihren Standard zurueck (Review
# 2026-09-02, scripts-docker-root-correctness:B1).
#
# Das Anheben eines frueheren Standards geht ueber `sed -i` (neue Datei, dann
# rename — atomar; ein Abbruch mitten im Schreiben kann die .env mit allen
# Secrets nicht leeren). Den Inode-Haken aus ensure_env_secrets umgeht das
# hier nicht, braucht es aber auch nicht: der geaenderte Wert aendert die
# Umgebung des Backends, das folgende `up -d` erzeugt es neu und bindet
# `/.env` dabei frisch ein.
#
# Aufruf: ensure_enabled_profiles <aktueller Standard> <Skriptname>
ENABLED_PROFILES_FRUEHERE_STANDARDS=(
  ""                                   # .env.example: leer = Vorgabe des Backends
  "network,monitoring,testing,cloner"  # rebuild.sh 2026-04-21 bis 2026-04-25
)
ensure_enabled_profiles() {
  local standard="$1" skript="$2"
  local env_file="${PROJECT_ROOT}/.env"
  local zeile="THINFORGE_ENABLED_PROFILES=${standard}"
  [ -f "$env_file" ] || return 0

  if ! grep -q '^THINFORGE_ENABLED_PROFILES=' "$env_file"; then
    printf '\n# Services-Panel-Filter (Standard von %s; ein eigener Wert bleibt stehen)\n%s\n' \
      "$skript" "$zeile" >> "$env_file"
    echo "  [migration] THINFORGE_ENABLED_PROFILES ergaenzt in .env"
    return 0
  fi

  local aktuell bekannt
  aktuell=$(grep '^THINFORGE_ENABLED_PROFILES=' "$env_file" | tail -n 1 | cut -d= -f2-)
  [ "$aktuell" = "$standard" ] && return 0
  for bekannt in "${ENABLED_PROFILES_FRUEHERE_STANDARDS[@]}"; do
    if [ "$aktuell" = "$bekannt" ]; then
      sed -i "s|^THINFORGE_ENABLED_PROFILES=.*|${zeile}|" "$env_file"
      echo "  [migration] THINFORGE_ENABLED_PROFILES auf den Standard von ${skript} gehoben: ${standard}"
      return 0
    fi
  done
  echo "  THINFORGE_ENABLED_PROFILES=${aktuell} ist ein eigener Wert und bleibt stehen (Standard waere ${standard})"
}

# ── .env sicherstellen ─────────────────────────────────────────────
# Erzeugt .env aus .env.example wenn sie fehlt. Generiert sichere
# Zufallswerte fuer Secrets.
ensure_env_file() {
  local env_file="${PROJECT_ROOT}/.env"

  if [ -f "$env_file" ]; then
    return 0
  fi

  # Guard: Wenn .env fehlt, aber ein bestehendes Postgres-Volume existiert,
  # wuerden frisch generierte Credentials zum alten Volume mismatchen —
  # Backend crasht dann dauerhaft mit "password authentication failed".
  # Besser hart abbrechen als den User in einen Restart-Loop laufen lassen.
  local pgdata="${STORAGE_DIR:-${PROJECT_ROOT}/ThinForgeDaten}/postgres/pgdata"
  if [ -d "$pgdata" ]; then
    cat >&2 <<EOF
FEHLER: .env fehlt, aber Postgres-Volume existiert unter:
  $pgdata

Eine neu generierte .env wuerde zufaellige Credentials erzeugen, die nicht
zum bestehenden Volume passen. Backend-Container wuerde mit
"password authentication failed for user" crashen.

Loesung (eine waehlen):
  A) .env aus Backup / Git-History / Passwort-Manager wiederherstellen
     (behaelt die bestehende Datenbank).
  B) Altes Volume loeschen — ACHTUNG: loescht alle Clients, User, Settings:
       sudo rm -rf "$pgdata"
     Danach erneut ./rebuild.sh aufrufen.
EOF
    exit 1
  fi

  if [ ! -f "${PROJECT_ROOT}/.env.example" ]; then
    echo "FEHLER: Weder .env noch .env.example gefunden in ${PROJECT_ROOT}"
    echo "  Erstelle eine .env-Datei oder kopiere .env.example nach .env"
    exit 1
  fi

  echo "  .env nicht vorhanden — erzeuge aus .env.example..."
  cp "${PROJECT_ROOT}/.env.example" "$env_file"

  # CHANGE_ME-Platzhalter durch sichere Zufallswerte ersetzen (gen_secret
  # steht oben auf Dateiebene, damit ensure_env_secrets es ebenfalls nutzt)
  sed -i "s|CHANGE_ME_postgres_password|$(gen_secret)|" "$env_file"
  sed -i "s|CHANGE_ME_grafana_admin_password|$(gen_secret)|" "$env_file"
  sed -i "s|CHANGE_ME_semaphore_admin_password|$(gen_secret)|" "$env_file"
  sed -i "s|CHANGE_ME_redis_password|$(gen_secret)|" "$env_file"

  echo "  .env erzeugt in ${env_file} (Secrets automatisch generiert)"
}

# ── STORAGE_DIR laden und auf absoluten Pfad aufloesen ─────────────
load_storage_dir() {
  init_project_root
  ensure_env_file
  # Nach der Erzeugung (oder auf einer bestehenden .env): spaeter dazugekommene
  # Pflicht-Secrets nachziehen, BEVOR irgendein compose-Aufruf die Datei liest.
  ensure_env_secrets

  STORAGE_DIR="${STORAGE_DIR:-}"

  # Aus .env lesen wenn nicht gesetzt
  if [ -z "$STORAGE_DIR" ] && [ -f "${PROJECT_ROOT}/.env" ]; then
    STORAGE_DIR=$(grep -E '^STORAGE_DIR=' "${PROJECT_ROOT}/.env" | cut -d= -f2- || true)
  fi

  # Default: ThinForgeDaten im Project Root
  STORAGE_DIR="${STORAGE_DIR:-./ThinForgeDaten}"

  # Relative Pfade gegen PROJECT_ROOT aufloesen
  if [[ "$STORAGE_DIR" == ./* ]] || [[ "$STORAGE_DIR" != /* ]]; then
    STORAGE_DIR="${PROJECT_ROOT}/${STORAGE_DIR#./}"
  fi

  export STORAGE_DIR

  # STORAGE_DIR in .env auf absoluten Pfad aktualisieren (einmalig)
  if grep -q "^STORAGE_DIR=\./" "${PROJECT_ROOT}/.env" 2>/dev/null; then
    sed -i "s|^STORAGE_DIR=\./.*|STORAGE_DIR=${STORAGE_DIR}|" "${PROJECT_ROOT}/.env"
    echo "  STORAGE_DIR in .env auf absoluten Pfad aktualisiert: ${STORAGE_DIR}"
  fi
}

# ── Kernel-Modul laden ─────────────────────────────────────────────
load_module() {
  local mod="$1"; shift
  if lsmod | grep -q "^${mod} " || [ -d "/sys/module/${mod}" ]; then
    echo "  Kernel module '${mod}' already loaded."
    return 0
  fi
  echo "  Loading kernel module '${mod}'..."
  if sudo modprobe "$mod" "$@" 2>/dev/null; then
    echo "  Kernel module '${mod}' loaded."
    return 0
  fi
  return 1
}
