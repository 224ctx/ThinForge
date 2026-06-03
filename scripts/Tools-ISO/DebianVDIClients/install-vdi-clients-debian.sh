#!/bin/bash
#
# ThinForge — VDI client installer (Debian)
#
# Installiert die VDI-Clients (Citrix Workspace App, Parallels Client, Omnissa
# Horizon Client) aus den Hersteller-Paketen, die in DIESEM Ordner
# (DebianVDIClients/) liegen. Fuer keinen der drei gibt es ein oeffentliches
# apt-Repository — die Pakete sind EULA-gated Downloads und werden daher einmal
# hier abgelegt (manuell oder via `download`) und beim Client-Setup von hier
# installiert. Siehe README.md.
#
# Aufruf auf dem CLIENT (z.B. aus install-debian-minimal.sh finish):
#   sudo bash install-vdi-clients-debian.sh            # installieren
#   sudo bash install-vdi-clients-debian.sh --dry-run  # nur anzeigen
#
# Aufruf auf dem BUILD-Host (Pakete in den Ordner holen, best-effort):
#   bash install-vdi-clients-debian.sh download        # URLs via urls.conf/Env
#
# Erkannte Dateinamen in diesem Ordner:
#   Citrix     : icaclient*.deb            (+ optional ctxusb*.deb)
#   Parallels  : *parallels*client*.deb     / parallelsclient*.deb
#   Omnissa    : *Horizon*Client*.bundle    (oder *horizon*client*.deb)

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[vdi]${NC} $*"; }
warn() { echo -e "${YELLOW}[vdi]${NC} $*"; }
err()  { echo -e "${RED}[vdi]${NC} $*" >&2; }

ACTION="install"; DRY_RUN=0
for a in "$@"; do
    case "$a" in
        download)      ACTION="download" ;;
        install)       ACTION="install" ;;
        --dry-run|-n)  DRY_RUN=1 ;;
        -h|--help)     sed -n '2,30p' "$0"; exit 0 ;;
        *)             err "Unknown argument: $a (see --help)"; exit 1 ;;
    esac
done

# Erste vorhandene Datei zu einem Glob in SCRIPT_DIR (oder leer).
first_match() {
    local g
    for g in "$SCRIPT_DIR"/$1; do [ -e "$g" ] && { printf '%s\n' "$g"; return 0; }; done
    return 0
}

# .deb (ggf. mehrere) via apt installieren — zieht Abhaengigkeiten.
install_debs() {
    local name="$1"; shift
    log "${name}: installing $(for f in "$@"; do basename "$f"; done | tr '\n' ' ')"
    if [ "$DRY_RUN" = 1 ]; then warn "[dry-run] apt-get install -y $*"; return 0; fi
    if apt-get install -y "$@"; then log "  OK ${name} installed"; else warn "  FAIL ${name}"; return 1; fi
}

# Omnissa-/VMware-Bundle (self-extracting) im Textmodus installieren.
install_bundle() {
    local f="$1" name="$2"
    log "${name}: running bundle $(basename "$f")"
    # --console (Textmodus), --required (nur Pflichtkomponenten), --eulas-agreed
    # (EULA non-interaktiv). Per Env HORIZON_BUNDLE_FLAGS ueberschreibbar, falls
    # eine Version andere Flags braucht.
    local flags="${HORIZON_BUNDLE_FLAGS:---console --required --eulas-agreed}"
    if [ "$DRY_RUN" = 1 ]; then warn "[dry-run] sh '$f' $flags"; return 0; fi
    chmod +x "$f" 2>/dev/null || true
    if sh "$f" $flags </dev/null; then log "  OK ${name} installed"; else warn "  FAIL ${name} bundle (EULA/flags? see README.md)"; return 1; fi
}

do_install() {
    [ "$(id -u)" -eq 0 ] || { err "install needs root: sudo bash $0"; exit 1; }
    local found=0

    # Citrix Workspace App (.deb, ggf. icaclient + ctxusb).
    local citrix_debs=()
    for d in "$SCRIPT_DIR"/icaclient*.deb "$SCRIPT_DIR"/ctxusb*.deb; do [ -e "$d" ] && citrix_debs+=("$d"); done
    if [ "${#citrix_debs[@]}" -gt 0 ]; then found=1; install_debs "Citrix Workspace App" "${citrix_debs[@]}" || true
    else echo "  Citrix     -> no icaclient*.deb in $(basename "$SCRIPT_DIR")/"; fi

    # Parallels Client (.deb).
    local par; par="$(first_match '*[Pp]arallels*[Cc]lient*.deb')"; [ -z "$par" ] && par="$(first_match 'parallelsclient*.deb')"
    if [ -n "$par" ]; then found=1; install_debs "Parallels Client" "$par" || true
    else echo "  Parallels  -> no *parallels*client*.deb"; fi

    # Omnissa Horizon Client (.bundle bevorzugt, sonst .deb).
    local hb hd; hb="$(first_match '*[Hh]orizon*[Cc]lient*.bundle')"; hd="$(first_match '*[Hh]orizon*[Cc]lient*.deb')"
    if [ -n "$hb" ]; then found=1; install_bundle "$hb" "Omnissa Horizon Client" || true
    elif [ -n "$hd" ]; then found=1; install_debs "Omnissa Horizon Client" "$hd" || true
    else echo "  Horizon    -> no *Horizon*Client*.bundle/.deb"; fi

    echo
    if [ "$found" = 0 ]; then
        warn "No VDI client packages found in $SCRIPT_DIR."
        warn "Place the vendor packages here (see README.md) or run: bash $0 download"
    else
        log "VDI client installation done."
    fi
}

do_download() {
    command -v curl >/dev/null 2>&1 || { err "curl is required for 'download'."; exit 1; }
    # URLs aus urls.conf (oder Env). EULA-gated -> keine stabilen Permalinks,
    # daher traegt der Operator die nach EULA-Klick erhaltenen Links ein.
    [ -f "$SCRIPT_DIR/urls.conf" ] && . "$SCRIPT_DIR/urls.conf"
    local any=0
    dl() { # $1=url $2=zieldatei $3=label
        [ -n "${1:-}" ] || { warn "$3: no URL set -> download manually (README.md)"; return 0; }
        any=1; log "$3: downloading -> $2"
        if [ "$DRY_RUN" = 1 ]; then warn "[dry-run] curl -fL -o '$SCRIPT_DIR/$2' '$1'"; return 0; fi
        curl -fL --retry 3 -o "$SCRIPT_DIR/$2" "$1" && log "  OK $2" || warn "  FAIL download ($3)"
    }
    dl "${CITRIX_URL:-}"    "icaclient_amd64.deb"           "Citrix"
    dl "${PARALLELS_URL:-}" "parallels-client_amd64.deb"    "Parallels"
    dl "${HORIZON_URL:-}"   "Omnissa-Horizon-Client.bundle" "Horizon"
    [ "$any" = 1 ] || warn "No URLs configured — see README.md / urls.conf.example."
}

case "$ACTION" in
    install)  do_install ;;
    download) do_download ;;
esac
