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

# ── Abrufe nach aussen: fruehere Vorgaben einmalig ausschalten ─────
# Bis 2026-10 trug .env.example zwei Abrufe ins Internet als Vorgabe ein: den
# Abgleich der Akzeptanzliste (THINFORGE_ACCEPTANCE_LIST_MODE=remote mit der
# offiziellen Adresse auf git.thinforge.org) und den KEV-Katalog
# (THINFORGE_KEV_URL mit dem CISA-Feed). Seitdem sind beide aus, auch fuer
# bestehende Installationen: beim Update werden sie ausgeschaltet.
#
# Umgestellt wird nur, was genau die frueher ausgelieferten Werte traegt; eine
# andere Adresse (ein eigener Spiegel) hat der Betrieb gesetzt und bleibt.
# Danach markiert eine Kommentarzeile die .env als geprueft, und die Funktion
# tut nichts mehr: wer einen Abruf spaeter bewusst wieder einschaltet, auch mit
# der offiziellen Adresse, behaelt seine Wahl. Gemeldet wird nur eine echte
# Umstellung, und nur einmal.
#
# Laeuft in load_storage_dir und damit fuer deploy.sh, rebuild.sh,
# install-deps.sh und clean-reset.sh — auch fuer das deploy.sh des
# Release-Repos, das diese Datei mitbringt. Wertaenderungen gehen wie in
# ensure_enabled_profiles ueber `sed -i`; das folgende `up -d` erzeugt das
# Backend wegen der geaenderten Umgebung neu und bindet `/.env` frisch ein.
EXTERNE_ABRUFE_MARKE='# thinforge-migration: externe-abrufe-aus'
AKZEPTANZLISTE_FRUEHERE_URLS=(
  # .env.example seit 2026-07-16 (und vom 2026-07-13 bis 2026-07-14)
  "https://git.thinforge.org/thinforge/ThinForge-Release/raw/branch/master/docs/security/vulnerability-acceptance.md"
  # .env.example 2026-07-14 bis 2026-07-16 (Ein-Repo-Zwischenstand)
  "https://git.thinforge.org/thinforge/ThinForge/raw/branch/master/docs/security/vulnerability-acceptance.md"
)
KEV_FRUEHERE_URL="https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json"
ensure_external_fetches_off() {
  local env_file="${PROJECT_ROOT}/.env"
  [ -f "$env_file" ] || return 0
  grep -qxF "$EXTERNE_ABRUFE_MARKE" "$env_file" && return 0

  local modus url kev bekannt umgestellt=""
  # `|| true`: ohne die Zeile liefert grep 1, und unter `set -eo pipefail`
  # (deploy.sh, rebuild.sh) braeche die Zuweisung das Skript ab.
  modus=$(grep '^THINFORGE_ACCEPTANCE_LIST_MODE=' "$env_file" | tail -n 1 | cut -d= -f2- || true)
  url=$(grep '^THINFORGE_ACCEPTANCE_LIST_URL=' "$env_file" | tail -n 1 | cut -d= -f2- || true)
  kev=$(grep '^THINFORGE_KEV_URL=' "$env_file" | tail -n 1 | cut -d= -f2- || true)

  if [ "$modus" = "remote" ]; then
    for bekannt in "${AKZEPTANZLISTE_FRUEHERE_URLS[@]}"; do
      if [ "$url" = "$bekannt" ]; then
        sed -i 's|^THINFORGE_ACCEPTANCE_LIST_MODE=.*|THINFORGE_ACCEPTANCE_LIST_MODE=local|' "$env_file"
        umgestellt="Akzeptanzlisten-Abgleich (git.thinforge.org)"
        break
      fi
    done
  fi
  if [ "$kev" = "$KEV_FRUEHERE_URL" ]; then
    sed -i 's|^THINFORGE_KEV_URL=.*|THINFORGE_KEV_URL=|' "$env_file"
    umgestellt="${umgestellt:+${umgestellt} und }KEV-Abruf (cisa.gov)"
  fi

  printf '\n# Abrufe nach aussen (Akzeptanzlisten-Abgleich, KEV-Katalog): die frueheren\n# Vorgaben hat scripts/lib-env.sh einmalig ausgeschaltet; eigene Werte bleiben stehen.\n%s\n' \
    "$EXTERNE_ABRUFE_MARKE" >> "$env_file"
  if [ -n "$umgestellt" ]; then
    echo "  [migration] ${umgestellt} in .env ausgeschaltet — das waren die frueheren Vorgaben, kein eigener Wert. Wieder einschalten: siehe .env.example"
  fi
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
  # Fruehere Vorgaben fuer Abrufe nach aussen einmalig ausschalten (2026-10).
  ensure_external_fetches_off

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

# ── PostgreSQL: Wechsel von glibc auf musl absichern ───────────────
# ThinForge-Dev bezog PostgreSQL bis 2026-10-26 als reg.mini.dev/postgres:18
# (Minimus, glibc), seitdem als postgres:18-alpine (musl); Minimus hat die
# Registry am 2026-10-22 abgeschaltet. musl sortiert Text anders, die unter
# glibc gebauten Textindizes passen danach nicht mehr. thinforge-migrate baut
# sie beim ersten Start von Backend und Worker neu auf, aber erst ab dem Stand
# POSTGRES_REINDEX_SEIT (4acb3154, crates/thinforge-migrate/src/collation.rs).
# Ein aelteres Backend, so das des Kanals :release bis zum naechsten Release
# (gebaut 2026-09-24), startet ohne Neuaufbau: Suchen ueber einen Textindex
# finden Zeilen nicht mehr, eindeutige Indizes lassen Doppel zu (Nachstellung
# in collation.rs: 4 von 29 Textindizes kaputt, 297 von 2580 Benutzernamen
# gefunden).
#
# guard_postgres_libc_switch <compose-befehl…> gibt 1 zurueck und erklaert auf
# stderr, wenn das PostgreSQL-Abbild der Compose-Datei musl ist, der Wechsel
# noch aussteht und das Backend der Compose-Datei aelter ist als der
# Neuaufbau. Ausstehend ist der Wechsel, wenn
#   - das laufende PostgreSQL fuer die ThinForge-Datenbank eine
#     Collation-Version gespeichert hat (nur glibc schreibt eine; eine unter
#     musl angelegte oder neu aufgebaute Datenbank hat keine), oder
#   - PostgreSQL nicht laeuft und das Datenverzeichnis einem anderen Benutzer
#     gehoert als dem postgres-Benutzer des Ziel-Abbilds (dessen Einstieg
#     uebernimmt es beim ersten Start: Alpine 70, Minimus 999).
# Was sich nicht lesen laesst, sperrt ebenfalls. Ohne Datenverzeichnis (neue
# Installation) und mit einem glibc-Ziel bleibt die Sperre aus. deploy.sh ruft
# sie nach dem Pull und vor jedem Eingriff auf; rebuild.sh braucht sie nicht,
# es baut das Backend aus dem Quelltext. Test:
# scripts/tests/postgres-libc-switch-gate.sh.
POSTGRES_REINDEX_SEIT='2026-10-16T07:51:16+02:00'
guard_postgres_libc_switch() {
  local compose=("$@")
  local pgdata="${STORAGE_DIR}/postgres/pgdata"
  local images pg_img backend_img ziel_uid befund created gebaut

  images=$("${compose[@]}" config --images 2>/dev/null) || images=''
  pg_img=$(printf '%s\n' "$images" | grep -E '(^|/)postgres[:@]' | head -n 1) || pg_img=''
  backend_img=$(printf '%s\n' "$images" | grep -E '(^|/)thinforge-backend[:@]' | head -n 1) || backend_img=''
  [ -n "$pg_img" ] || return 0

  # musl-Ziel? Dann nennt das Abbild die uid seines postgres-Benutzers.
  ziel_uid=$(docker run --rm --pull=never --network none --entrypoint sh "$pg_img" \
    -c 'ls /lib/ld-musl-* >/dev/null 2>&1 && id -u postgres' 2>/dev/null) || return 0
  [ -n "$ziel_uid" ] || return 0

  if "${compose[@]}" exec -T postgres true >/dev/null 2>&1; then
    if befund=$(printf '%s\n' "select coalesce(datcollversion, '') from pg_database where datname = current_database();" \
        | "${compose[@]}" exec -T postgres sh -c 'psql -X -A -t -q -U "$POSTGRES_USER" -d "$POSTGRES_DB"' 2>/dev/null); then
      [ -n "$befund" ] || return 0
      befund="gespeicherte Collation-Version ${befund}"
    else
      befund="Collation-Version der Datenbank unlesbar"
    fi
  else
    sudo test -d "$pgdata" || return 0
    if befund=$(sudo stat -c %u "$pgdata" 2>/dev/null); then
      [ "$befund" != "$ziel_uid" ] || return 0
      befund="PostgreSQL laeuft nicht, das Datenverzeichnis gehoert uid ${befund} statt ${ziel_uid}"
    else
      befund="PostgreSQL laeuft nicht, Besitzer des Datenverzeichnisses unlesbar"
    fi
  fi

  created=$(docker image inspect -f '{{.Created}}' "$backend_img" 2>/dev/null) || created=''
  if [ -n "$created" ] \
     && [ "$(date -d "$created" +%s 2>/dev/null || echo 0)" -ge "$(date -d "$POSTGRES_REINDEX_SEIT" +%s)" ]; then
    return 0
  fi
  gebaut="${created:0:10}"
  [ -n "$gebaut" ] || gebaut="unbekannt"

  {
    echo ""
    echo "FEHLER: Dieser Deploy stellt PostgreSQL auf ${pg_img} um (musl), die"
    echo "        Datenbank stammt aber aus einem glibc-Abbild: ${befund}."
    echo "        Ihre Textindizes muessen dabei neu aufgebaut werden, und das kann erst"
    echo "        ein Backend ab dem ${POSTGRES_REINDEX_SEIT:0:10}. ${backend_img:-Das Backend} ist gebaut am ${gebaut}."
    echo "        Ohne Neuaufbau sortieren die Textindizes falsch: Suchen finden Zeilen"
    echo "        nicht mehr, eindeutige Indizes lassen Doppel zu."
    echo "        Am Stack wurde nichts veraendert."
    echo ""
    echo "        Weiter auf einem dieser Wege:"
    echo "          THINFORGE_TAG=beta ./deploy.sh --persist-tag"
    echo "              Kanal beta; dessen Backend baut die Indizes beim ersten Start neu auf"
    echo "          ./rebuild.sh"
    echo "              nur ThinForge-Dev: baut Backend und Worker aus dem Quelltext"
    echo "          das Update bis zum naechsten Release zurueckstellen, auch kein"
    echo "              'docker compose up' von Hand: es loeste denselben Wechsel aus"
    echo "        Schritt fuer Schritt: https://thinforge.org/doku-migration.html"
  } >&2
  return 1
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
