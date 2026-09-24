#!/usr/bin/env bash
# stop-all.sh — Faehrt alle ThinForge-Container herunter.
#
# Daten in den Volumes (Postgres, Clones, Deltas, Backups, ...) bleiben
# erhalten. Der naechste `bootstrap-release.sh` / `rebuild.sh` / `docker
# compose up -d` faehrt alles wieder hoch.
#
# Behandelt alle Compose-Profile (network, testing, monitoring, cloner,
# multicast, bittorrent) UND raeumt zusaetzlich Stragglers ab, die per
# `docker run` ausserhalb von Compose gestartet wurden (Cloner-Subprozesse,
# Delta-Worker, BT-Seeder, Multicast-Sender) — erkannt am Namenspraefix
# `thinforge-`.
#
# Usage:
#   ./stop-all.sh         # default: down (entfernt Container, behaelt Volumes)
#   ./stop-all.sh --keep  # nur stop (Container bleiben, schnellerer Restart)

set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/scripts/lib-env.sh"
init_project_root
# Beide Compose-Dateien interpolieren REDIS_PASSWORD strikt (`${…:?}`) —
# auch fuer `down` und `stop`. Ohne diese Zeile brach das Skript auf einer
# Installation von vor der Umstellung (Review 2026-09-02 S5-1) schon am
# ersten compose-Aufruf ab, und wegen `set -e` blieben auch die Nachzuegler
# unten stehen. Haengt die Variable wie rebuild.sh/deploy.sh an (nie
# `sed -i`: die .env ist inode-gebunden ins Backend gemountet).
ensure_env_secrets

COMPOSE_FILE="docker-compose.yml"
ALL_PROFILES=(network testing monitoring cloner multicast bittorrent)

MODE="down"
for arg in "$@"; do
  case "$arg" in
    --keep) MODE="stop" ;;
    -h|--help)
      sed -n '2,16p' "$0"
      exit 0
      ;;
    *)
      echo "Unbekanntes Argument: $arg" >&2
      exit 2
      ;;
  esac
done

PROFILE_FLAGS=()
for p in "${ALL_PROFILES[@]}"; do
  PROFILE_FLAGS+=(--profile "$p")
done

if [[ "$MODE" == "down" ]]; then
  echo "Stoppe und entferne alle ThinForge-Container ueber Compose..."
  docker compose -f "$COMPOSE_FILE" "${PROFILE_FLAGS[@]}" down --remove-orphans
else
  echo "Stoppe alle ThinForge-Container ueber Compose (Container bleiben)..."
  docker compose -f "$COMPOSE_FILE" "${PROFILE_FLAGS[@]}" stop
fi

# Stragglers: Container, die das Backend selbst per `docker run` startet und
# die Compose deshalb nicht kennt. Gefiltert wird ueber das NAMENSPRAEFIX, nicht
# ueber com.thinforge.label: dieses Label steht ausschliesslich in den
# Service-Definitionen der beiden Compose-Dateien, also genau an den
# Containern, die `docker compose down` eine Zeile weiter oben ohnehin schon
# entfernt hat. Keine der bollard-Aufrufstellen setzt `labels`, und keine der
# `docker run`-Stellen uebergibt `--label` — der Block lief also in beiden
# Betriebsarten ins Leere, waehrend "Fertig." trotzdem gemeldet wurde.
#
# Betroffen waren: thinforge-cloner-1 und -cloner-1-restore (privileged),
# thinforge-delta-worker/-delta-merge und die delta-export-/import-Container
# (privileged, --pid=host, --device=/dev/nbd0), thinforge-bt-seeder-service,
# thinforge-mc-sender-<id>, thinforge-ssh-inject und
# thinforge-prepare-base-disk-1. Alle beginnen mit "${APP_NAME_LOWER}-".
#
# Compose-Container matcht das Praefix ebenfalls, das schadet aber nicht: nach
# `down` sind sie weg, nach `stop` laufen sie nicht mehr, und `docker ps -q`
# listet nur laufende. Fremde Container ohne das Praefix bleiben unberuehrt.
APP_NAME_LOWER="thinforge"
strays=$(docker ps -q --filter "name=^${APP_NAME_LOWER}-" 2>/dev/null || true)
if [[ -n "${strays}" ]]; then
  echo "Stoppe zusaetzliche ThinForge-Container ausserhalb von Compose..."
  # shellcheck disable=SC2086
  docker stop ${strays} >/dev/null 2>&1 || true
  if [[ "$MODE" == "down" ]]; then
    # `|| true`: die meisten dieser Container laufen mit `--rm` bzw.
    # auto_remove, der Daemon raeumt sie also beim Stoppen schon selbst weg —
    # `docker rm` scheitert dann an einem Container, den es nicht mehr gibt,
    # und wuerde unter `set -e` das Skript vor der Schlussmeldung beenden.
    # shellcheck disable=SC2086
    docker rm ${strays} >/dev/null 2>&1 || true
  fi
fi

echo "Fertig. Volumes und ThinForge-Daten bleiben erhalten."
