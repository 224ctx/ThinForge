#!/bin/bash
#
# ThinForge — Remote-Desktop-Clients fuer Debian
#
# Installiert auf einem frisch ausgerollten Debian-System:
#   - Citrix Workspace App (.deb)
#   - Omnissa Horizon Client (.bundle, ehem. VMware Horizon Client)
#
# Benoetigt root (sudo) und eine Internetverbindung ODER lokale
# Installer-Dateien.
#
# Aufruf:
#   sudo bash install-remote-clients-debian.sh              # interaktiv (Menu)
#   sudo bash install-remote-clients-debian.sh --citrix     # nur Citrix
#   sudo bash install-remote-clients-debian.sh --horizon    # nur Horizon
#   sudo bash install-remote-clients-debian.sh --all        # beides ohne Frage
#
# Quellen fuer die Installer (nur eines pro Produkt noetig):
#
#   1. URL ueber Env-Variable
#        CITRIX_DEB_URL=https://...icaclient_x86_64.deb sudo bash ...
#        HORIZON_BUNDLE_URL=https://...x86_64.bundle    sudo bash ...
#
#   2. Lokal abgelegte Datei in diesem Ordner (DistroTweaks/):
#        DistroTweaks/icaclient_*_amd64.deb
#        DistroTweaks/VMware-Horizon-Client-*.x86_64.bundle
#        (Omnissa-Build mit "Omnissa-Horizon-Client-*" wird ebenfalls erkannt)
#
#   3. Pfad ueber Env-Variable auf eine bereits gemountete Datei:
#        CITRIX_DEB_FILE=/mnt/usb/icaclient.deb
#        HORIZON_BUNDLE_FILE=/mnt/usb/horizon.bundle
#
# Da Citrix und Omnissa Downloads hinter einer Akzeptanz-Seite liegen,
# laedt das Script *nichts* automatisch von der Hersteller-Webseite —
# der Admin legt die Installer einmalig in DistroTweaks/ ab oder gibt
# eine direkte Download-URL via Env mit.

set -euo pipefail

# -- Hilfsfunktionen ---------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()   { echo -e "${GREEN}[thinforge]${NC} $*"; }
warn()  { echo -e "${YELLOW}[thinforge]${NC} $*"; }
error() { echo -e "${RED}[thinforge]${NC} $*" >&2; }
fatal() { error "$*"; exit 1; }

require_root() {
    if [ "${EUID:-$(id -u)}" -ne 0 ]; then
        fatal "This script must run as root (sudo bash $0 ...)."
    fi
}

# Verzeichnis dieses Scripts (= DistroTweaks/ auf der Tools-ISO).
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# -- Quelle fuer Installer-Datei finden --------------------------------------
#
# resolve_installer <produkt> <env-file-var> <env-url-var> <glob1> [glob2 ...]
# Setzt die globale Variable RESOLVED_FILE auf einen lokal verfuegbaren
# Dateipfad oder leeren String wenn nichts gefunden wurde.

resolve_installer() {
    local product="$1"; shift
    local env_file_var="$1"; shift
    local env_url_var="$1"; shift
    local globs=( "$@" )

    RESOLVED_FILE=""

    # 1) Env: direkter Pfad
    local env_file="${!env_file_var:-}"
    if [ -n "$env_file" ]; then
        if [ ! -f "$env_file" ]; then
            fatal "$product: $env_file_var=$env_file does not exist."
        fi
        RESOLVED_FILE="$env_file"
        return 0
    fi

    # 2) Lokale Datei in DistroTweaks/
    local found=""
    local g
    for g in "${globs[@]}"; do
        # shellcheck disable=SC2086
        for f in $SCRIPT_DIR/$g; do
            [ -f "$f" ] || continue
            found="$f"
            break 2
        done
    done
    if [ -n "$found" ]; then
        RESOLVED_FILE="$found"
        return 0
    fi

    # 3) Env: URL — runterladen ins /tmp
    local env_url="${!env_url_var:-}"
    if [ -n "$env_url" ]; then
        local tmp
        tmp="$(mktemp -p /tmp "thinforge-${product,,}.XXXXXX")"
        log "$product: downloading from $env_url ..."
        if ! curl -fL --retry 3 -o "$tmp" "$env_url"; then
            rm -f "$tmp"
            fatal "$product: Download failed ($env_url)."
        fi
        RESOLVED_FILE="$tmp"
        return 0
    fi

    # nichts gefunden
    return 1
}

# -- Citrix Workspace App ----------------------------------------------------

install_citrix() {
    log "=== Citrix Workspace App ==="

    if ! resolve_installer "Citrix" CITRIX_DEB_FILE CITRIX_DEB_URL \
            "icaclient_*_amd64.deb" "icaclient*.deb" "citrix-workspace*.deb"; then
        warn "No Citrix installer found. One of the following sources is expected:"
        warn "  - File in $SCRIPT_DIR/icaclient_*_amd64.deb"
        warn "  - Env CITRIX_DEB_FILE=/path/to/file.deb"
        warn "  - Env CITRIX_DEB_URL=https://.../icaclient_..._amd64.deb"
        warn "Download page: https://www.citrix.com/downloads/workspace-app/linux/"
        return 1
    fi

    log "Citrix Installer: $RESOLVED_FILE"

    # Abhaengigkeiten (Bookworm/Trixie) — werden bei Bedarf von apt automatisch
    # nachgezogen, hier explizit fuer aeltere icaclient-Builds:
    DEBIAN_FRONTEND=noninteractive apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        libwebkit2gtk-4.1-0 \
        libxkbfile1 \
        libxinerama1 \
        libxrandr2 \
        libxtst6 \
        libxss1 \
        libxaw7 \
        libgtk-3-0 \
        libcanberra-gtk3-module \
        libsecret-1-0 \
        libidn12 \
        || warn "Some Citrix dependencies could not be installed — continuing."

    # Citrix akzeptiert seine EULA waehrend dpkg-Postinst — das blockt sonst.
    echo "icaclient app_protection/install_app_protection select no"  | debconf-set-selections
    echo "icaclient icaclient/license/accept_eula  boolean true"      | debconf-set-selections

    log "Installing $RESOLVED_FILE ..."
    if ! DEBIAN_FRONTEND=noninteractive apt-get install -y "$RESOLVED_FILE"; then
        # apt-get install <deb> ist erst ab apt 1.1 — Fallback auf dpkg + apt -f
        warn "apt install <.deb> failed, trying dpkg + apt-get -f install ..."
        dpkg -i "$RESOLVED_FILE" || true
        DEBIAN_FRONTEND=noninteractive apt-get install -y -f
    fi

    # Mozilla-CA-Bundle in Citrix-Trust-Store verlinken — sonst SSL-Fehler beim
    # Connect zu Storefront mit Lets-Encrypt-/internen Zertifikaten.
    if [ -d /opt/Citrix/ICAClient/keystore/cacerts ] \
        && [ -d /usr/share/ca-certificates/mozilla ]; then
        log "Linking Mozilla CAs into Citrix keystore ..."
        ln -sf /usr/share/ca-certificates/mozilla/* \
            /opt/Citrix/ICAClient/keystore/cacerts/ || true
        if [ -x /opt/Citrix/ICAClient/util/ctx_rehash ]; then
            /opt/Citrix/ICAClient/util/ctx_rehash || true
        fi
    fi

    log "Citrix Workspace App installed."
}

# -- Omnissa Horizon Client (ehem. VMware Horizon Client) --------------------

install_horizon() {
    log "=== Omnissa Horizon Client ==="

    if ! resolve_installer "Horizon" HORIZON_BUNDLE_FILE HORIZON_BUNDLE_URL \
            "Omnissa-Horizon-Client-*.x86_64.bundle" \
            "VMware-Horizon-Client-*.x86_64.bundle" \
            "*Horizon-Client*.bundle"; then
        warn "No Horizon installer found. One of the following sources is expected:"
        warn "  - File in $SCRIPT_DIR/(Omnissa|VMware)-Horizon-Client-*.x86_64.bundle"
        warn "  - Env HORIZON_BUNDLE_FILE=/path/to/file.bundle"
        warn "  - Env HORIZON_BUNDLE_URL=https://.../horizon-client.bundle"
        warn "Download page: https://customerconnect.omnissa.com/downloads (Linux x64)"
        return 1
    fi

    log "Horizon Installer: $RESOLVED_FILE"

    # Bundles brauchen ein paar GUI-Libs zur Laufzeit. Das Bundle prueft selbst,
    # aber wir installieren die haeufigsten vorab damit der erste Start klappt.
    DEBIAN_FRONTEND=noninteractive apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        libxss1 \
        libxtst6 \
        libxkbfile1 \
        libgtk-3-0 \
        libudev1 \
        libatk-bridge2.0-0 \
        libpangoxft-1.0-0 \
        libnss3 \
        libxshmfence1 \
        libgl1 \
        libxcb-keysyms1 \
        libxcb-image0 \
        libxcb-render-util0 \
        libxcb-icccm4 \
        libxcb-xkb1 \
        || warn "Some Horizon dependencies could not be installed — continuing."

    chmod +x "$RESOLVED_FILE"

    # Bundle nicht-interaktiv ausfuehren. Die Optionen funktionieren sowohl
    # fuer alte VMware-Builds als auch fuer aktuelle Omnissa-Builds.
    log "Running bundle installer (silent) ..."
    "$RESOLVED_FILE" \
        --console \
        --required \
        --eulas-agreed \
        || fatal "Horizon Bundle installer failed."

    log "Omnissa Horizon Client installed."
}

# -- Argumente / Menue -------------------------------------------------------

DO_CITRIX=0
DO_HORIZON=0

while [ $# -gt 0 ]; do
    case "$1" in
        --citrix)  DO_CITRIX=1 ;;
        --horizon) DO_HORIZON=1 ;;
        --all)     DO_CITRIX=1; DO_HORIZON=1 ;;
        -h|--help)
            sed -n '2,30p' "$0"
            exit 0
            ;;
        *) fatal "Unknown argument: $1" ;;
    esac
    shift
done

require_root

if [ "$DO_CITRIX" -eq 0 ] && [ "$DO_HORIZON" -eq 0 ]; then
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Install Remote Desktop Clients${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
    read -rp "  Install Citrix Workspace App? [Y/n]: " a
    case "${a:-J}" in [JjYy]*|"") DO_CITRIX=1 ;; esac
    read -rp "  Install Omnissa Horizon Client? [Y/n]: " a
    case "${a:-J}" in [JjYy]*|"") DO_HORIZON=1 ;; esac
    echo ""
fi

FAIL=0
if [ "$DO_CITRIX"  -eq 1 ]; then install_citrix  || FAIL=$((FAIL+1)); fi
if [ "$DO_HORIZON" -eq 1 ]; then install_horizon || FAIL=$((FAIL+1)); fi

if [ "$FAIL" -gt 0 ]; then
    warn "$FAIL product(s) could not be installed — see messages above."
    exit 1
fi

log "Done."
