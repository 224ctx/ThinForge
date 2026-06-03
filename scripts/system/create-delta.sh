#!/bin/bash
#
# ThinForge Delta-Update Erstellung
#
# Erstellt versionierte btrfs-Snapshots in einer VM-Disk und
# generiert optional Deltas zwischen zwei Versionen.
#
# Snapshots werden fuer @root UND @home erstellt, damit
# Desktop-Aenderungen und OS-Updates gemeinsam in Deltas fliessen.
# @cache und @log werden nicht gesnapshot (transient).
#
# Voraussetzungen:
#   - qemu-nbd, btrfs-progs, zstd
#   - root-Rechte (fuer nbd + mount)
#   - VM muss heruntergefahren sein!
#
# Verwendung:
#   # Snapshot erstellen (nach Updates in der VM):
#   ./create-delta.sh snapshot /pfad/zu/vm.qcow2 v3.2
#
#   # Delta zwischen zwei Versionen erzeugen:
#   ./create-delta.sh delta /pfad/zu/vm.qcow2 v3.1 v3.2
#
#   # Vorhandene Snapshots auflisten:
#   ./create-delta.sh list /pfad/zu/vm.qcow2
#

set -euo pipefail

# -- Versions-Normalisierung: immer "v"-Prefix ----------------------------
normalize_version() {
    local v="$1"
    [[ "$v" == v* ]] && echo "$v" || echo "v${v}"
}

# -- Hilfsfunktionen ------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()   { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[FEHLER]${NC} $*" >&2; }
fatal() { error "$*"; exit 1; }

NBD_DEV="/dev/nbd0"
MNT=""

cleanup() {
    if [ -n "$MNT" ] && mountpoint -q "$MNT" 2>/dev/null; then
        umount "$MNT" 2>/dev/null || true
    fi
    # Flush all pending I/O before disconnecting to avoid
    # "Buffer I/O error on dev nbd0" kernel warnings.
    sync
    blockdev --flushbufs "$NBD_DEV" 2>/dev/null || true
    sleep 1
    qemu-nbd --disconnect "$NBD_DEV" 2>/dev/null || true
    [ -n "$MNT" ] && rmdir "$MNT" 2>/dev/null || true
}
trap cleanup EXIT

usage() {
    cat << 'EOF'
ThinForge Delta-Update Erstellung

Verwendung:
  create-delta.sh <AKTION> <QCOW2> [ARGUMENTE...]

Aktionen:
  list    <QCOW2>                     Snapshots in der VM-Disk auflisten
  snapshot <QCOW2> <VERSION>          Read-only Snapshots von @root + @home erstellen
  delta   <QCOW2> <VON> <NACH>       Deltas zwischen zwei Snapshot-Versionen erzeugen

Argumente:
  QCOW2       Pfad zur VM-Disk (qcow2-Format)
  VERSION     Versionsname (z.B. v3.1, v3.2)
  VON/NACH    Quell- und Ziel-Version fuer Delta

Optionen:
  -o, --output DIR    Ausgabeverzeichnis fuer Delta (Standard: ./deltas/)
  -h, --help          Diese Hilfe anzeigen

Beispiele:
  # 1. Nach Updates in der VM: Neuen Snapshot erstellen
  create-delta.sh snapshot /data/cloning-vm/disk.qcow2 v3.2

  # 2. Delta erzeugen (nur Differenz, komprimiert)
  create-delta.sh delta /data/cloning-vm/disk.qcow2 v3.1 v3.2

  # 3. Snapshots pruefen
  create-delta.sh list /data/cloning-vm/disk.qcow2

Workflow:
  1. VM starten, Updates durchfuehren, VM herunterfahren
  2. create-delta.sh snapshot ... v3.2
  3. create-delta.sh delta ... v3.1 v3.2
  4. Delta an Clients verteilen (ueber ThinForge-API)
EOF
    exit 0
}

# -- NBD verbinden --------------------------------------------------------
nbd_connect() {
    local qcow2="$1"
    local readonly="${2:-false}"

    modprobe nbd max_part=16 2>/dev/null || true

    if [ "$readonly" = "true" ]; then
        qemu-nbd --connect="$NBD_DEV" --read-only "$qcow2"
    else
        qemu-nbd --connect="$NBD_DEV" "$qcow2"
    fi
    sleep 2
    partprobe "$NBD_DEV" 2>/dev/null || true
    sleep 1
    # In Containern werden Device-Nodes nicht automatisch erstellt
    local nbd_base
    nbd_base=$(basename "$NBD_DEV")
    awk -v dev="$nbd_base" '$4 ~ dev"p" { system("mknod /dev/" $4 " b " $1 " " $2) }' /proc/partitions 2>/dev/null || true
}

# System-Partition finden (die groesste btrfs-Partition, nicht die Daten-Partition)
find_system_partition() {
    local sys_part=""
    local sys_size=0

    # In Containern werden Device-Nodes nicht automatisch erstellt
    local nbd_base
    nbd_base=$(basename "$NBD_DEV")
    awk -v dev="$nbd_base" '$4 ~ dev"p" { system("mknod /dev/" $4 " b " $1 " " $2) }' /proc/partitions 2>/dev/null || true

    for part in "${NBD_DEV}p"*; do
        [ -b "$part" ] || continue
        local fstype
        fstype=$(blkid -o value -s TYPE "$part" 2>/dev/null || echo "")
        [ "$fstype" != "btrfs" ] && continue

        local label
        label=$(blkid -o value -s LABEL "$part" 2>/dev/null || echo "")
        # Daten-Partition ueberspringen (Label "data" oder "Daten")
        [[ "$label" == "data" || "$label" == "Daten" ]] && continue

        local size
        size=$(blockdev --getsize64 "$part")
        if [ "$size" -gt "$sys_size" ]; then
            sys_size=$size
            sys_part=$part
        fi
    done

    echo "$sys_part"
}

# Detect root subvolume name (@root for Manjaro, @ for Debian)
detect_root_subvol() {
    local mnt="$1"
    if btrfs subvolume show "$mnt/@root" &>/dev/null; then
        echo "@root"
    elif btrfs subvolume show "$mnt/@" &>/dev/null; then
        echo "@"
    else
        echo ""
    fi
}

# -- Aktionen -------------------------------------------------------------

action_list() {
    local qcow2="$1"

    log "Verbinde VM-Disk (read-only)..."
    nbd_connect "$qcow2" true

    local sys_part
    sys_part=$(find_system_partition)
    [ -z "$sys_part" ] && fatal "Keine btrfs System-Partition gefunden!"

    local label
    label=$(blkid -o value -s LABEL "$sys_part" 2>/dev/null || echo "?")
    log "System-Partition: $sys_part (Label: $label)"

    MNT=$(mktemp -d)
    mount -o ro "$sys_part" "$MNT"

    echo ""
    echo -e "${CYAN}Subvolumes in der VM-Disk:${NC}"
    echo ""
    btrfs subvolume list -t "$MNT" 2>/dev/null || btrfs subvolume list "$MNT"
    echo ""

    # Snapshots hervorheben
    local snap_count=0
    while IFS= read -r line; do
        if echo "$line" | grep -q "@snap_"; then
            snap_count=$((snap_count + 1))
        fi
    done < <(btrfs subvolume list "$MNT")

    if [ "$snap_count" -gt 0 ]; then
        log "Gefunden: $snap_count Versions-Snapshot(s)"
    else
        warn "Keine Versions-Snapshots gefunden"
        warn "Erstelle zuerst einen initialen Snapshot mit: $0 snapshot $qcow2 <VERSION>"
    fi
}

action_snapshot() {
    local qcow2="$1"
    local version
    version=$(normalize_version "$2")
    local snap_root="@snap_${version}"
    local snap_home="@snap_${version}_home"

    log "Verbinde VM-Disk (read-write)..."
    nbd_connect "$qcow2" false

    local sys_part
    sys_part=$(find_system_partition)
    [ -z "$sys_part" ] && fatal "Keine btrfs System-Partition gefunden!"
    log "System-Partition: $sys_part"

    MNT=$(mktemp -d)
    mount "$sys_part" "$MNT"

    # Detect root subvolume (@root for Manjaro, @ for Debian)
    local ROOT_SV
    ROOT_SV=$(detect_root_subvol "$MNT")
    [ -z "$ROOT_SV" ] && fatal "Weder @root noch @ Subvolume gefunden!"

    # Pruefen ob Snapshot schon existiert
    if btrfs subvolume show "$MNT/$snap_root" &>/dev/null; then
        fatal "Snapshot $snap_root existiert bereits! Loeschen mit:\n  btrfs subvolume delete $MNT/$snap_root"
    fi

    # Root Snapshot
    log "Erstelle Read-only Snapshot: $ROOT_SV → $snap_root"
    btrfs subvolume snapshot -r "$MNT/$ROOT_SV" "$MNT/$snap_root"

    # @home Snapshot (falls vorhanden)
    if btrfs subvolume show "$MNT/@home" &>/dev/null; then
        if btrfs subvolume show "$MNT/$snap_home" &>/dev/null; then
            warn "Snapshot $snap_home existiert bereits — ueberspringe"
        else
            log "Erstelle Read-only Snapshot: @home → $snap_home"
            btrfs subvolume snapshot -r "$MNT/@home" "$MNT/$snap_home"
        fi
    else
        warn "@home Subvolume nicht gefunden — nur $ROOT_SV gesnapshot"
    fi

    echo ""
    log "Snapshots erstellt:"
    btrfs subvolume show "$MNT/$snap_root" | head -3
    if btrfs subvolume show "$MNT/$snap_home" &>/dev/null; then
        btrfs subvolume show "$MNT/$snap_home" | head -3
    fi
    echo ""

    log "Vorhandene Subvolumes:"
    btrfs subvolume list "$MNT"
}

action_delta() {
    local qcow2="$1"
    local from_version
    from_version=$(normalize_version "$2")
    local to_version
    to_version=$(normalize_version "$3")
    local output_dir="$4"

    local from_snap="@snap_${from_version}"
    local to_snap="@snap_${to_version}"
    local from_snap_home="@snap_${from_version}_home"
    local to_snap_home="@snap_${to_version}_home"
    local delta_file="${output_dir}/delta_${from_version}_to_${to_version}.zst"
    local delta_home_file="${output_dir}/delta_${from_version}_to_${to_version}_home.zst"

    mkdir -p "$output_dir"

    log "Verbinde VM-Disk (read-only)..."
    nbd_connect "$qcow2" true

    local sys_part
    sys_part=$(find_system_partition)
    [ -z "$sys_part" ] && fatal "Keine btrfs System-Partition gefunden!"
    log "System-Partition: $sys_part"

    MNT=$(mktemp -d)
    mount -o ro "$sys_part" "$MNT"

    # Pruefen ob @root Snapshots existieren
    if ! btrfs subvolume show "$MNT/$from_snap" &>/dev/null; then
        error "Quell-Snapshot $from_snap nicht gefunden!"
        echo "Verfuegbare Snapshots:"
        btrfs subvolume list "$MNT" | grep "@snap_" || echo "  (keine)"
        exit 1
    fi
    if ! btrfs subvolume show "$MNT/$to_snap" &>/dev/null; then
        fatal "Ziel-Snapshot $to_snap nicht gefunden!\nErstelle zuerst: $0 snapshot $qcow2 $to_version"
    fi

    # -- @root Delta ---------------------------------------------------------
    log "Erzeuge @root Delta: $from_snap → $to_snap"
    btrfs send --compressed-data -p "$MNT/$from_snap" "$MNT/$to_snap" | zstd -3 -T0 > "$delta_file"
    local root_size
    root_size=$(du -h "$delta_file" | cut -f1)
    log "@root Delta: $delta_file ($root_size)"

    # -- @home Delta ---------------------------------------------------------
    local home_included=false
    local home_incremental=false
    local home_size_bytes=0

    if btrfs subvolume show "$MNT/$to_snap_home" &>/dev/null; then
        if btrfs subvolume show "$MNT/$from_snap_home" &>/dev/null; then
            # Inkrementelles Delta (Eltern-Snapshot vorhanden)
            log "Erzeuge @home Delta (inkrementell): $from_snap_home → $to_snap_home"
            btrfs send --compressed-data -p "$MNT/$from_snap_home" "$MNT/$to_snap_home" | zstd -3 -T0 > "$delta_home_file"
            home_incremental=true
        else
            # Voll-Snapshot (kein Eltern-Snapshot, erster @home-Delta)
            log "Erzeuge @home Delta (voll, kein Eltern-Snapshot): $to_snap_home"
            btrfs send --compressed-data "$MNT/$to_snap_home" | zstd -3 -T0 > "$delta_home_file"
            home_incremental=false
        fi
        home_size_bytes=$(stat -c%s "$delta_home_file")
        local home_size
        home_size=$(du -h "$delta_home_file" | cut -f1)
        log "@home Delta: $delta_home_file ($home_size)"
        home_included=true
    else
        warn "@home Snapshot $to_snap_home nicht gefunden — kein @home Delta"
    fi

    echo ""
    local total_size
    total_size=$(du -ch "$delta_file" "$delta_home_file" 2>/dev/null | tail -1 | cut -f1)
    log "Gesamt: $total_size"
    echo ""

    # Info-JSON mit Subvolume-Informationen
    local home_json="null"
    if [ "$home_included" = "true" ]; then
        local from_home_json="null"
        [ "$home_incremental" = "true" ] && from_home_json="\"$from_snap_home\""
        home_json=$(cat << HOMEJSON
{
      "file": "delta_${from_version}_to_${to_version}_home.zst",
      "from_snapshot": $from_home_json,
      "to_snapshot": "$to_snap_home",
      "incremental": $home_incremental,
      "size_bytes": $home_size_bytes
    }
HOMEJSON
)
    fi

    cat > "${output_dir}/delta_${from_version}_to_${to_version}.json" << DELTAJSON
{
  "from_version": "${from_version}",
  "to_version": "${to_version}",
  "from_snapshot": "${from_snap}",
  "to_snapshot": "${to_snap}",
  "delta_file": "delta_${from_version}_to_${to_version}.zst",
  "delta_size_bytes": $(stat -c%s "$delta_file"),
  "home_delta": $home_json,
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
DELTAJSON

    log "Metadaten: ${output_dir}/delta_${from_version}_to_${to_version}.json"
}

action_cleanup() {
    local qcow2="$1"
    local keep="${2:-2}"

    log "Verbinde VM-Disk (read-write fuer Snapshot-Loeschung)..."
    nbd_connect "$qcow2" false

    local sys_part
    sys_part=$(find_system_partition)
    [ -z "$sys_part" ] && fatal "Keine btrfs System-Partition gefunden!"

    MNT=$(mktemp -d)
    mount "$sys_part" "$MNT"

    # Alle @snap_* Subvolumes sammeln (ohne _home Pendants)
    local -a root_snaps=()
    while IFS= read -r line; do
        local name
        name=$(echo "$line" | awk '{print $NF}')
        if [[ "$name" =~ ^@snap_v?[0-9] ]] && [[ ! "$name" =~ _home$ ]]; then
            root_snaps+=("$name")
        fi
    done < <(btrfs subvolume list "$MNT")

    local total=${#root_snaps[@]}
    if [ "$total" -le "$keep" ]; then
        log "Nur $total Snapshot(s) vorhanden, behalte alle (keep=$keep)."
        return
    fi

    # Nach Version sortieren — `sort -V` deckt sowohl Legacy-SemVer
    # (@snap_v1.000 < @snap_v1.001 < @snap_v2.000) als auch CalVer
    # (@snap_v2026.05.07-001 < @snap_v2026.05.07-002 < @snap_v2026.05.08-001)
    # in einem Aufruf ab — Punkte und Bindestriche werden als Trenner behandelt
    # und numerische Felder numerisch verglichen.
    IFS=$'\n' read -r -d '' -a sorted < <(
        for s in "${root_snaps[@]}"; do echo "$s"; done | sort -V
    ) || true

    local delete_count=$((total - keep))
    log "$total Snapshots gefunden, behalte die letzten $keep, loesche $delete_count"

    for ((i = 0; i < delete_count; i++)); do
        local snap="${sorted[$i]}"
        local home_snap="${snap}_home"

        # Root-Snapshot loeschen
        if btrfs subvolume show "$MNT/$snap" &>/dev/null; then
            btrfs property set "$MNT/$snap" ro false 2>/dev/null || true
            btrfs subvolume delete "$MNT/$snap"
            log "Geloescht: $snap"
        fi

        # Home-Pendant loeschen falls vorhanden
        if btrfs subvolume show "$MNT/$home_snap" &>/dev/null; then
            btrfs property set "$MNT/$home_snap" ro false 2>/dev/null || true
            btrfs subvolume delete "$MNT/$home_snap"
            log "Geloescht: $home_snap"
        fi
    done

    echo ""
    log "Cleanup abgeschlossen. Verbleibende Snapshots:"
    btrfs subvolume list "$MNT" | grep "@snap_" || echo "  (keine)"
}

action_receive() {
    local qcow2="$1"
    shift
    local -a delta_files=("$@")

    [ ${#delta_files[@]} -eq 0 ] && fatal "Keine Delta-Dateien angegeben"

    log "Verbinde VM-Disk (read-write fuer btrfs receive)..."
    nbd_connect "$qcow2" false

    local sys_part
    sys_part=$(find_system_partition)
    [ -z "$sys_part" ] && fatal "Keine btrfs System-Partition gefunden!"

    MNT=$(mktemp -d)
    mount -o compress=zstd:1 "$sys_part" "$MNT"

    for delta in "${delta_files[@]}"; do
        [ -f "$delta" ] || { warn "Delta nicht gefunden: $delta — ueberspringe"; continue; }

        local snap_name
        snap_name=$(basename "$delta" | sed -n 's/.*_to_\(v[0-9._]*\)\(\.zst\|_home\.zst\)/\1/p')
        if [ -z "$snap_name" ]; then
            warn "Kann Snapshot-Version nicht aus Dateiname ableiten: $(basename "$delta") — ueberspringe"
            continue
        fi
        local subvol_suffix=""
        echo "$delta" | grep -q "_home\.zst" && subvol_suffix="_home"
        local expected="@snap_${snap_name}${subvol_suffix}"

        if btrfs subvolume show "$MNT/$expected" &>/dev/null; then
            log "$expected existiert bereits — ueberspringe"
            continue
        fi

        log "Empfange Delta: $(basename "$delta") → $expected"
        zstd -d -c "$delta" | btrfs receive "$MNT/"

        if ! btrfs subvolume show "$MNT/$expected" &>/dev/null; then
            warn "btrfs receive hat $expected nicht erzeugt — fahre fort"
        else
            log "Empfangen: $expected"
        fi
    done

    log "Alle Deltas angewendet. Subvolumes:"
    btrfs subvolume list "$MNT" | grep "@snap_"
}

action_merge() {
    local qcow2="$1"
    local output_dir="$2"
    local target="$3"
    shift 3
    local -a from_versions=("$@")

    target=$(normalize_version "$target")

    [ ${#from_versions[@]} -eq 0 ] && fatal "Keine Start-Versionen angegeben"

    mkdir -p "$output_dir"

    log "Verbinde VM-Disk (read-only fuer Merged-Delta-Erzeugung)..."
    nbd_connect "$qcow2" true

    # Merge-Disk hat keine Partitionstabelle — btrfs liegt direkt auf dem Device.
    # Fallback: erst Partitionen pruefen, dann ganzes Device versuchen.
    local sys_part
    sys_part=$(find_system_partition)
    if [ -z "$sys_part" ]; then
        # Kein Partitions-Layout — btrfs direkt auf NBD-Device (temp Merge-Disk)
        sys_part="$NBD_DEV"
    fi

    MNT=$(mktemp -d)
    mount -o ro "$sys_part" "$MNT"

    local to_snap="@snap_${target}"
    if ! btrfs subvolume show "$MNT/$to_snap" &>/dev/null; then
        fatal "Ziel-Snapshot $to_snap nicht gefunden auf der Disk!"
    fi

    for from_ver in "${from_versions[@]}"; do
        from_ver=$(normalize_version "$from_ver")
        local from_snap="@snap_${from_ver}"
        local delta_file="${output_dir}/delta_${from_ver}_to_${target}.zst"
        local delta_home="${output_dir}/delta_${from_ver}_to_${target}_home.zst"

        if [ -f "$delta_file" ]; then
            log "Merged-Delta $from_ver→$target existiert bereits — ueberspringe"
            continue
        fi

        if ! btrfs subvolume show "$MNT/$from_snap" &>/dev/null; then
            warn "Quell-Snapshot $from_snap nicht vorhanden — ueberspringe"
            continue
        fi

        # @root Merged-Delta
        log "Erzeuge Merged-Delta: $from_ver → $target (@root)"
        btrfs send --compressed-data -p "$MNT/$from_snap" "$MNT/$to_snap" \
            | zstd -3 -T0 > "$delta_file"
        local root_size
        root_size=$(du -h "$delta_file" | cut -f1)
        log "@root Merged-Delta: $delta_file ($root_size)"

        # @home Merged-Delta (falls beide Home-Snapshots vorhanden)
        local from_home="@snap_${from_ver}_home"
        local to_home="@snap_${target}_home"
        local home_size_bytes=0
        local home_included=false

        if btrfs subvolume show "$MNT/$to_home" &>/dev/null; then
            if btrfs subvolume show "$MNT/$from_home" &>/dev/null; then
                log "Erzeuge Merged-Delta: $from_ver → $target (@home)"
                btrfs send --compressed-data -p "$MNT/$from_home" "$MNT/$to_home" \
                    | zstd -3 -T0 > "$delta_home"
                home_size_bytes=$(stat -c%s "$delta_home")
                home_included=true
            else
                log "Erzeuge @home Delta (voll, kein Eltern-Snapshot): $to_home"
                btrfs send --compressed-data "$MNT/$to_home" \
                    | zstd -3 -T0 > "$delta_home"
                home_size_bytes=$(stat -c%s "$delta_home")
                home_included=true
            fi
        fi

        # Metadaten-JSON
        local home_json="null"
        if [ "$home_included" = "true" ]; then
            local from_home_json="null"
            btrfs subvolume show "$MNT/$from_home" &>/dev/null && from_home_json="\"$from_home\""
            home_json=$(cat << HOMEJSON
{
      "file": "delta_${from_ver}_to_${target}_home.zst",
      "from_snapshot": $from_home_json,
      "to_snapshot": "$to_home",
      "incremental": $(btrfs subvolume show "$MNT/$from_home" &>/dev/null && echo true || echo false),
      "size_bytes": $home_size_bytes
    }
HOMEJSON
)
        fi

        cat > "${output_dir}/delta_${from_ver}_to_${target}.json" << DELTAJSON
{
  "from_version": "${from_ver}",
  "to_version": "${target}",
  "from_snapshot": "${from_snap}",
  "to_snapshot": "${to_snap}",
  "delta_file": "delta_${from_ver}_to_${target}.zst",
  "delta_size_bytes": $(stat -c%s "$delta_file"),
  "home_delta": $home_json,
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "merged": true
}
DELTAJSON

        log "Merged-Delta $from_ver → $target fertig"
    done
}

# -- Argumente parsen -----------------------------------------------------
ACTION=""
QCOW2=""
OUTPUT_DIR="./deltas"
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

[ ${#POSITIONAL[@]} -lt 1 ] && usage
ACTION="${POSITIONAL[0]}"

# -- Validierung ----------------------------------------------------------
[[ $EUID -ne 0 ]] && fatal "Dieses Script muss als root ausgefuehrt werden."

case "$ACTION" in
    list)
        [ ${#POSITIONAL[@]} -lt 2 ] && fatal "Verwendung: $0 list <QCOW2>"
        QCOW2="${POSITIONAL[1]}"
        [ ! -f "$QCOW2" ] && fatal "Datei nicht gefunden: $QCOW2"
        action_list "$QCOW2"
        ;;
    snapshot)
        [ ${#POSITIONAL[@]} -lt 3 ] && fatal "Verwendung: $0 snapshot <QCOW2> <VERSION>"
        QCOW2="${POSITIONAL[1]}"
        VERSION="${POSITIONAL[2]}"
        [ ! -f "$QCOW2" ] && fatal "Datei nicht gefunden: $QCOW2"
        action_snapshot "$QCOW2" "$VERSION"
        ;;
    delta)
        [ ${#POSITIONAL[@]} -lt 4 ] && fatal "Verwendung: $0 delta <QCOW2> <VON> <NACH>"
        QCOW2="${POSITIONAL[1]}"
        FROM="${POSITIONAL[2]}"
        TO="${POSITIONAL[3]}"
        [ ! -f "$QCOW2" ] && fatal "Datei nicht gefunden: $QCOW2"
        action_delta "$QCOW2" "$FROM" "$TO" "$OUTPUT_DIR"
        ;;
    cleanup)
        [ ${#POSITIONAL[@]} -lt 2 ] && fatal "Verwendung: $0 cleanup <QCOW2> [KEEP]"
        QCOW2="${POSITIONAL[1]}"
        KEEP="${POSITIONAL[2]:-2}"
        [ ! -f "$QCOW2" ] && fatal "Datei nicht gefunden: $QCOW2"
        action_cleanup "$QCOW2" "$KEEP"
        ;;
    receive)
        [ ${#POSITIONAL[@]} -lt 3 ] && fatal "Verwendung: $0 receive <QCOW2> <DELTA1.zst> [DELTA2.zst ...]"
        QCOW2="${POSITIONAL[1]}"
        [ ! -f "$QCOW2" ] && fatal "Datei nicht gefunden: $QCOW2"
        action_receive "$QCOW2" "${POSITIONAL[@]:2}"
        ;;
    merge)
        [ ${#POSITIONAL[@]} -lt 4 ] && fatal "Verwendung: $0 merge <QCOW2> <ZIEL_VERSION> <VON1> [VON2 ...]"
        QCOW2="${POSITIONAL[1]}"
        TARGET="${POSITIONAL[2]}"
        [ ! -f "$QCOW2" ] && fatal "Datei nicht gefunden: $QCOW2"
        action_merge "$QCOW2" "$OUTPUT_DIR" "$TARGET" "${POSITIONAL[@]:3}"
        ;;
    *)
        fatal "Unbekannte Aktion: $ACTION\nSiehe --help"
        ;;
esac
