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

  # Sichere Zufallswerte generieren
  gen_secret() {
    openssl rand -base64 32 2>/dev/null | tr -d '\n/+=' \
      || head -c 32 /dev/urandom | base64 | tr -d '\n/+='
  }

  # CHANGE_ME-Platzhalter durch sichere Zufallswerte ersetzen
  sed -i "s|CHANGE_ME_postgres_password|$(gen_secret)|" "$env_file"
  sed -i "s|CHANGE_ME_grafana_admin_password|$(gen_secret)|" "$env_file"
  sed -i "s|CHANGE_ME_semaphore_admin_password|$(gen_secret)|" "$env_file"

  echo "  .env erzeugt in ${env_file} (Secrets automatisch generiert)"
}

# ── STORAGE_DIR laden und auf absoluten Pfad aufloesen ─────────────
load_storage_dir() {
  init_project_root
  ensure_env_file

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
