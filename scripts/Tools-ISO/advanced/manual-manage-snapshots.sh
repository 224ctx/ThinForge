#!/bin/bash
#
# ThinForge Snapshot-Verwaltung
#
# Zeigt alle btrfs-Snapshots auf der System-Partition an und ermoeglicht
# das gezielte oder vollstaendige Loeschen.
#
# Angeboten werden NUR die Snapshots, die der Agent selbst anlegt
# (@snap_*), plus die Rollback-Reste des letzten Apply (@root_old,
# @rootfs_old, @_old). Alles andere — aktive Subvolumes wie @, @root,
# @home, @cache, @log, @data und jedes fremde Subvolume — bleibt
# unangetastet, auch wenn es hier unbekannt ist.
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

# Erlaubliste statt Sperrliste. Eine Sperrliste ist bei einem Werkzeug, das
# loescht, die falsche Richtung: Was sie nicht kennt, faellt. Sie kannte
# @home/@cache/@log nicht — auf einem Geraet, das ohne den prepare-Schritt
# installiert wurde (die Installer WARNEN nur, siehe install-manjaro.sh),
# steht genau dieses Calamares-Layout auf der Platte, und "--delete-all"
# haette die Home-Subvolumes aller Benutzer mitgenommen.
#
# Deshalb dieselbe Regel, nach der auch der Agent aufraeumt
# (agent-go/internal/applydelta/cleanup.go: strings.HasPrefix(name,
# "@snap_")): angeboten wird nur, was ThinForge selbst angelegt hat.
#
# Absichtlich nur der Praefix und nicht das strenge Versionsmuster des
# Agents (@snap_v<CalVer>): Leftover aus der Zeit vor der CalVer-Umstellung
# tragen ein Hex-Suffix, passen also nicht auf das Muster — und genau die
# soll dieses Werkzeug wegraeumen koennen.
SNAP_PREFIX="@snap_"

# Die Rollback-Reste des letzten Apply. SwapSubvolumes benennt das laufende
# Root-Subvolume in <root>_old um und loescht diesen Rest beim naechsten
# Apply selbst wieder; der Rollback greift auf @snap_* zurueck, nicht auf
# _old. Sie sind also loeschbar, ohne den Rueckweg zu verlieren — dieselben
# drei Namen wie in agent-go/internal/applydelta/grub.go.
ROLLBACK_LEFTOVERS=("@root_old" "@rootfs_old" "@_old")

# Ist "$1" ein Name, den dieses Werkzeug loeschen darf?
is_deletable() {
    local name="$1"
    # Leer oder mit '/' im Namen: ein verschachteltes Subvolume (btrfs listet
    # top-level-relativ, z.B. "@root/var/lib/machines"). Das liegt INNERHALB
    # eines anderen Subvolumes und ist nie ein Snapshot von uns.
    case "$name" in
        ""|*/*) return 1 ;;
    esac
    case "$name" in
        "${SNAP_PREFIX}"*) return 0 ;;
    esac
    local p
    for p in "${ROLLBACK_LEFTOVERS[@]}"; do
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

# Den Pfad aus einer Zeile von `btrfs subvolume list` schneiden.
# Format: "ID 257 gen 100 top level 5 path @snap_v2026.05.01-001".
# `awk '{print $NF}'` nahm nur das LETZTE Feld und zerschnitt damit jeden
# Namen mit Leerzeichen; die Parameter-Expansion nimmt alles nach " path ".
subvol_path_of() {
    local line="$1"
    case "$line" in
        *" path "*) printf '%s\n' "${line#* path }" ;;
        *) printf '\n' ;;
    esac
}

get_snapshots() {
    # Gibt die Subvolumes zurueck, die dieses Werkzeug loeschen darf.
    btrfs subvolume list "$SYSTEM_MNT" | while IFS= read -r line; do
        local name
        name=$(subvol_path_of "$line")
        if is_deletable "$name"; then
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
    echo -e "${CYAN}Deletable:${NC}     ${SNAP_PREFIX}* ${ROLLBACK_LEFTOVERS[*]}"
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
        # Zweite Pruefung unmittelbar vor dem Loeschen: die Zusicherung soll an
        # der gefaehrlichen Zeile stehen, nicht nur beim Einsammeln.
        if ! is_deletable "$snap"; then
            warn "Refusing to delete '$snap' — not a ThinForge snapshot"
            continue
        fi
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
        # Wie oben: die Zusicherung steht an der loeschenden Zeile.
        if ! is_deletable "$snap"; then
            warn "Refusing to delete '$snap' — not a ThinForge snapshot"
            continue
        fi
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
    echo "Only these subvolumes are ever offered for deletion:"
    echo "  ${SNAP_PREFIX}*  (ThinForge snapshots)  ${ROLLBACK_LEFTOVERS[*]}  (rollback leftovers)"
    echo ""
    echo "Everything else — @, @root, @home, @cache, @log, @data and any"
    echo "third-party subvolume — is never touched."
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
