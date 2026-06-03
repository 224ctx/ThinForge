#!/bin/bash
#
# ThinForge Snapshot-Verwaltung
#
# Zeigt alle btrfs-Snapshots auf der System-Partition an und ermoeglicht
# das gezielte oder vollstaendige Loeschen.
#
# Aktive Subvolumes (@root, @home, @cache, @log) werden NIE geloescht.
#
# Voraussetzungen:
#   - btrfs-progs
#   - root-Rechte
#
# Verwendung:
#   ./manual-manage-snapshots.sh                Alle Snapshots auflisten
#   ./manual-manage-snapshots.sh --delete       Interaktiv loeschen
#   ./manual-manage-snapshots.sh --delete-all   Alle Snapshots loeschen (mit Bestaetigung)
#   ./manual-manage-snapshots.sh --help         Hilfe anzeigen
#

set -euo pipefail

SYSTEM_MNT=""

# -- Hilfsfunktionen ----------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()   { echo -e "${GREEN}[snapshots]${NC} $*"; }
warn()  { echo -e "${YELLOW}[snapshots]${NC} $*"; }
error() { echo -e "${RED}[snapshots]${NC} $*" >&2; }
fatal() { error "$*"; exit 1; }

cleanup() {
    if [ -n "$SYSTEM_MNT" ] && mountpoint -q "$SYSTEM_MNT" 2>/dev/null; then
        umount "$SYSTEM_MNT" 2>/dev/null || true
    fi
    [ -n "$SYSTEM_MNT" ] && rmdir "$SYSTEM_MNT" 2>/dev/null || true
}
trap cleanup EXIT

# Geschuetzte Subvolumes die nie geloescht werden duerfen — alle bekannten
# Root-Subvol-Namen (Debian/Ubuntu/Mint) plus _old-Pendants (frischer
# Rollback-Stand vom letzten Apply) und @data fuer persistente Daten.
PROTECTED=("@" "@root" "@rootfs" "@data" "@root_old" "@rootfs_old" "@_old")

is_protected() {
    local name="$1"
    for p in "${PROTECTED[@]}"; do
        [ "$name" = "$p" ] && return 0
    done
    return 1
}

# -- System-Partition finden und mounten --------------------------------------

find_system_device() {
    local source
    source=$(findmnt -n -o SOURCE /)
    echo "$source" | sed 's/\[.*\]//'
}

mount_toplevel() {
    local dev
    dev=$(find_system_device)
    SYSTEM_MNT=$(mktemp -d)
    mount "$dev" "$SYSTEM_MNT"
}

# -- Snapshot-Liste sammeln ---------------------------------------------------

get_snapshots() {
    # Gibt alle Subvolumes zurueck die NICHT geschuetzt sind
    btrfs subvolume list "$SYSTEM_MNT" | while IFS= read -r line; do
        local name
        name=$(echo "$line" | awk '{print $NF}')
        if ! is_protected "$name"; then
            echo "$name"
        fi
    done
}

# -- Aktionen ----------------------------------------------------------------

action_list() {
    local dev
    dev=$(find_system_device)
    mount_toplevel

    echo ""
    echo -e "${CYAN}System device:${NC}  $dev"
    echo -e "${CYAN}Active subvols:${NC} ${PROTECTED[*]}"
    echo ""

    local snaps
    snaps=$(get_snapshots)

    if [ -z "$snaps" ]; then
        log "No snapshots found."
        return
    fi

    log "Snapshots:"
    echo ""
    local i=1
    while IFS= read -r snap; do
        local ro_flag=""
        if btrfs property get "$SYSTEM_MNT/$snap" ro 2>/dev/null | grep -q "true"; then
            ro_flag=" (read-only)"
        fi
        printf "  ${CYAN}%2d${NC}  %s%s\n" "$i" "$snap" "$ro_flag"
        i=$((i + 1))
    done <<< "$snaps"
    echo ""
}

action_delete() {
    mount_toplevel

    local snaps
    snaps=$(get_snapshots)

    if [ -z "$snaps" ]; then
        log "No snapshots found."
        return
    fi

    # Snapshots nummeriert anzeigen
    echo ""
    log "Available snapshots:"
    echo ""
    local -a snap_arr=()
    local i=1
    while IFS= read -r snap; do
        local ro_flag=""
        if btrfs property get "$SYSTEM_MNT/$snap" ro 2>/dev/null | grep -q "true"; then
            ro_flag=" (read-only)"
        fi
        printf "  ${CYAN}%2d${NC}  %s%s\n" "$i" "$snap" "$ro_flag"
        snap_arr+=("$snap")
        i=$((i + 1))
    done <<< "$snaps"
    echo ""

    echo -n "Numbers to delete (comma-separated, e.g. 1,3,5) or 'all': "
    read -r input

    if [ -z "$input" ]; then
        log "Aborted."
        return
    fi

    local -a to_delete=()

    if [ "$input" = "all" ]; then
        to_delete=("${snap_arr[@]}")
    else
        IFS=',' read -ra nums <<< "$input"
        for num in "${nums[@]}"; do
            num=$(echo "$num" | tr -d ' ')
            if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#snap_arr[@]}" ]; then
                to_delete+=("${snap_arr[$((num - 1))]}")
            else
                warn "Invalid number: $num — skipped"
            fi
        done
    fi

    if [ ${#to_delete[@]} -eq 0 ]; then
        log "Nothing to delete."
        return
    fi

    echo ""
    warn "The following snapshots will be deleted:"
    for snap in "${to_delete[@]}"; do
        echo "    $snap"
    done
    echo ""
    echo -n "Continue? [y/N] "
    read -r confirm
    if [ "$confirm" != "j" ] && [ "$confirm" != "J" ] && [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        log "Aborted."
        return
    fi

    for snap in "${to_delete[@]}"; do
        # Read-only Flag entfernen falls gesetzt
        if btrfs property get "$SYSTEM_MNT/$snap" ro 2>/dev/null | grep -q "true"; then
            btrfs property set "$SYSTEM_MNT/$snap" ro false
        fi
        btrfs subvolume delete "$SYSTEM_MNT/$snap"
        log "Deleted: $snap"
    done

    echo ""
    log "Done. ${#to_delete[@]} snapshot(s) removed."
}

action_delete_all() {
    mount_toplevel

    local snaps
    snaps=$(get_snapshots)

    if [ -z "$snaps" ]; then
        log "No snapshots found."
        return
    fi

    local count
    count=$(echo "$snaps" | wc -l)

    echo ""
    warn "All $count snapshots will be deleted:"
    echo ""
    while IFS= read -r snap; do
        echo "    $snap"
    done <<< "$snaps"
    echo ""
    echo -n "Continue? [y/N] "
    read -r confirm
    if [ "$confirm" != "j" ] && [ "$confirm" != "J" ] && [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        log "Aborted."
        return
    fi

    while IFS= read -r snap; do
        if btrfs property get "$SYSTEM_MNT/$snap" ro 2>/dev/null | grep -q "true"; then
            btrfs property set "$SYSTEM_MNT/$snap" ro false
        fi
        btrfs subvolume delete "$SYSTEM_MNT/$snap"
        log "Deleted: $snap"
    done <<< "$snaps"

    echo ""
    log "Done. $count snapshot(s) removed."
}

usage() {
    echo "ThinForge Snapshot Management"
    echo ""
    echo "Usage:"
    echo "  manual-manage-snapshots.sh                List snapshots"
    echo "  manual-manage-snapshots.sh --delete       Delete interactively"
    echo "  manual-manage-snapshots.sh --delete-all   Delete all snapshots"
    echo "  manual-manage-snapshots.sh --help         This help"
    echo ""
    echo "Protected subvolumes (never deleted):"
    echo "  ${PROTECTED[*]}"
    exit 0
}

# -- Hauptprogramm ------------------------------------------------------------

[[ $EUID -ne 0 ]] && fatal "This script must be run as root."

case "${1:-}" in
    --delete|-d)
        action_delete
        ;;
    --delete-all|-D)
        action_delete_all
        ;;
    --help|-h)
        usage
        ;;
    ""|--list|-l)
        action_list
        ;;
    *)
        error "Unknown argument: $1"
        usage
        ;;
esac
