#!/bin/bash
#
# ThinForge — Debian Cleanup
#
# Entfernt vorinstallierte Desktop-Apps, die im Thin-Client-/Kiosk-Image nicht
# gebraucht werden, raeumt nicht mehr benoetigte Abhaengigkeiten ab
# (apt-get autoremove --purge) und loescht den apt-Cache (apt-get clean).
#
# Aufruf:
#   sudo bash cleanup-debian.sh             # entfernen
#   sudo bash cleanup-debian.sh --dry-run   # nur anzeigen, nichts aendern
#
# NICHT entfernt (nur der Menue-Eintrag wird ausgeblendet):
#   - "Icon Browser"     -> Paket 'yad'    : Laufzeit-Abhaengigkeit des
#                           ThinForge-Agents (Notification-Dialoge) und der
#                           Installer-Dialoge — Entfernen wuerde diese brechen.
#   - "Massenumbenennen" -> Paket 'thunar' : der Dateimanager (Bulk-Rename ist
#                           Teil davon, kein eigenes Paket).

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

DRY_RUN=0
case "${1:-}" in
    --dry-run|-n) DRY_RUN=1 ;;
    "") ;;
    *) echo "Unknown argument: $1 (use --dry-run)"; exit 1 ;;
esac

[ "$(id -u)" -eq 0 ] || { echo "Run as root: sudo bash $0" >&2; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[cleanup]${NC} $*"; }
warn() { echo -e "${YELLOW}[cleanup]${NC} $*"; }

pkg_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }

# ── Zu entfernende Apps: "Anzeigename|Kandidaten-Pakete" ────────────────────
# Nur tatsaechlich installierte Kandidaten werden gepurgt. UXTerm + XTerm
# liefert das xterm-Paket; "Notizen" kann xfce4-notes UND/ODER -plugin sein.
APP_MAP=(
    "Xfburn|xfburn"
    "Notizen|xfce4-notes xfce4-notes-plugin"
    "Anwendungsfinder|xfce4-appfinder"
    "Taskmanager|xfce4-taskmanager"
    "XTerm + UXTerm|xterm"
    "Ex Falso|exfalso"
    "Quod Libet|quodlibet"
    "XSane|xsane"
    "Ristretto-Bildbetrachter|ristretto"
    "Atril|atril"
)

# LibreOffice (alles): alle installierten libreoffice*-Pakete + uebliche
# Support-Pakete (ure/uno/python3-uno/fonts-opensymbol), dynamisch.
LO_PKGS=$(dpkg-query -W -f='${Package}\n' 'libreoffice*' 'ure' 'uno-libs-private' 'python3-uno' 'fonts-opensymbol' 2>/dev/null | sort -u || true)
[ -n "$LO_PKGS" ] && APP_MAP+=("LibreOffice (all)|$(echo $LO_PKGS | tr '\n' ' ')")

# ── Sammeln: was ist installiert? ───────────────────────────────────────────
log "Checking listed apps..."
declare -a PURGE=()
for entry in "${APP_MAP[@]}"; do
    name="${entry%%|*}"; pkgs="${entry#*|}"; hit=""
    for p in $pkgs; do
        pkg_installed "$p" && { PURGE+=("$p"); hit="$hit $p"; }
    done
    if [ -n "$hit" ]; then echo -e "  ${CYAN}${name}${NC} ->$hit"; else echo "  ${name} -> (not installed)"; fi
done
if [ "${#PURGE[@]}" -gt 0 ]; then
    mapfile -t PURGE < <(printf '%s\n' "${PURGE[@]}" | sort -u)
fi

# ── Menue-Eintrag ausblenden, dessen Paket NICHT entfernt werden darf ───────
# Override in /usr/local/share/applications hat Vorrang vor /usr/share/...
hide_launcher() {
    local id="$1" name="$2" exec_line="$3"
    [ -f "/usr/share/applications/${id}" ] || { echo "  ${name} -> launcher not present (ok)"; return 0; }
    if [ "$DRY_RUN" = 1 ]; then warn "[dry-run] would hide menu entry '${name}' (${id})"; return 0; fi
    install -d -m0755 /usr/local/share/applications
    cat > "/usr/local/share/applications/${id}" <<EOF
[Desktop Entry]
Type=Application
Name=${name}
Exec=${exec_line}
NoDisplay=true
EOF
    log "Menu entry '${name}' hidden (package kept)."
}

# ── Ausfuehren ──────────────────────────────────────────────────────────────
echo
if [ "${#PURGE[@]}" -eq 0 ]; then
    log "None of the listed app packages are installed."
else
    log "To purge (${#PURGE[@]} packages): ${PURGE[*]}"

    # Desktop-/System-Kern + Allerwelts-Tools + ThinForge-Pflicht (yad/zenity)
    # als 'manual' pinnen. Das Purgen von xfce4-appfinder/-notes/-taskmanager
    # entfernt ueber Depends die Metapakete xfce4-goodies/xfce4/task-xfce-desktop;
    # ohne diese Pins wuerde das nachfolgende autoremove die GANZE XFCE-Sitzung
    # (Panel, Whisker-Menue, thunar, alle Plugins) + nuetzliche Tools mitnehmen.
    # Mit den Pins entfernt autoremove nur noch die exklusiven Orphans der
    # entfernten Apps (v.a. die ~100 LibreOffice-Bibliotheken). apt-mark ist
    # idempotent/harmlos und wird auch im --dry-run gesetzt, damit die Vorschau
    # den tatsaechlichen (gepinnten) Stand zeigt.
    PINS=$(dpkg-query -W -f='${Package}\n' \
        'xfce4-*' 'libxfce4*' 'thunar*' 'xfdesktop4' 'xfwm4' 'tumbler*' 'garcon*' \
        'lightdm*' 'xserver-xorg*' 'xorg' 'xinit' 'xinput' \
        'network-manager*' 'yad' 'zenity' \
        'xarchiver' 'unzip' 'zip' 'xdg-utils' 'xdg-desktop-portal*' \
        'xdg-dbus-proxy' 'bubblewrap' 2>/dev/null | sort -u || true)
    [ -n "$PINS" ] && { apt-mark manual $PINS >/dev/null 2>&1 || true; }

    if [ "$DRY_RUN" = 1 ]; then
        warn "[dry-run] Simulation (desktop pinned 'manual' -> only orphans of the removed apps):"
        apt-get -s purge --auto-remove "${PURGE[@]}" 2>/dev/null | grep -E '^(Remv|Purg) ' || true
        warn "[dry-run] (the real run additionally performs 'apt-get clean')"
    else
        apt-get purge -y "${PURGE[@]}"
        log "Removing no-longer-needed packages (autoremove --purge)..."
        apt-get autoremove --purge -y
        log "Cleaning apt cache..."
        apt-get clean
    fi
fi

echo
hide_launcher "thunar-bulk-rename.desktop" "Bulk Rename" "thunar --bulk-rename %F"
hide_launcher "yad-icon-browser.desktop"   "Icon Browser" "yad-icon-browser"

if [ "$DRY_RUN" != 1 ]; then
    update-desktop-database /usr/local/share/applications 2>/dev/null || true
    update-desktop-database 2>/dev/null || true
fi

echo
log "Cleanup done."
