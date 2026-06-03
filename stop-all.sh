#!/usr/bin/env bash
# stop-all.sh — Faehrt alle ThinForge-Container herunter.
#
# Daten in den Volumes (Postgres, Clones, Deltas, Backups, ...) bleiben
# erhalten. Der naechste `bootstrap-release.sh` / `rebuild.sh` / `docker
# compose up -d` faehrt alles wieder hoch.
#
# Behandelt alle Compose-Profile (network, testing, monitoring, cloner,
# multicast, bittorrent) UND raeumt zusaetzlich Stragglers ab, die per
# `docker run` ausserhalb von Compose gestartet wurden (Cloning-VMs,
# Cloner-Subprozesse) — erkannt am `com.thinforge.*`-Label.
#
# Usage:
#   ./stop-all.sh         # default: down (entfernt Container, behaelt Volumes)
#   ./stop-all.sh --keep  # nur stop (Container bleiben, schnellerer Restart)

set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/scripts/lib-env.sh"
init_project_root

COMPOSE_FILE="docker-compose.yml"
ALL_PROFILES=(network testing monitoring cloner multicast bittorrent)

MODE="down"
for arg in "$@"; do
  case "$arg" in
    --keep) MODE="stop" ;;
    -h|--help)
      sed -n '2,15p' "$0"
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

# Stragglers: Container mit com.thinforge.*-Label, die nicht ueber Compose
# liefen (Cloning-VMs, Cloner-Subprozesse via `docker run`). Filter sucht
# auf einem *gesetzten* com.thinforge.label-Wert — matched alle, ignoriert
# Default-Containern ohne unsere Labels.
strays=$(docker ps -q --filter "label=com.thinforge.label" 2>/dev/null || true)
if [[ -n "${strays}" ]]; then
  echo "Stoppe zusaetzliche ThinForge-Container ausserhalb von Compose..."
  # shellcheck disable=SC2086
  docker stop ${strays} >/dev/null
  if [[ "$MODE" == "down" ]]; then
    # shellcheck disable=SC2086
    docker rm ${strays} >/dev/null
  fi
fi

echo "Fertig. Volumes und ThinForge-Daten bleiben erhalten."
