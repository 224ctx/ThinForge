#!/bin/bash
#
# ThinForge Client-Partitionierung
#
# Erstellt das btrfs-Snapshot-Partitionsschema dynamisch basierend
# auf der Festplattengroesse. Alle Daten auf der Ziel-Disk werden geloescht!
#
# Layout:
#   sda1  2G      ESP (vfat)
#   sda2  Rest    System (btrfs, Subvolumes: @root + Snapshots)
#   sda3  5G      Daten  (btrfs, Subvolume: @data)
#
# A/B-Slots entfallen — Rollback erfolgt ueber btrfs-Snapshots.
# GRUB bootet @root (normal) oder @snap_<version> (Fallback).
#
# Verwendung:
#   ./0-right-partition-layout.sh /dev/sda
#   ./0-right-partition-layout.sh /dev/nvme0n1
#   ./0-right-partition-layout.sh /dev/sda --data-size 10G
#   ./0-right-partition-layout.sh /dev/sda --dry-run
#

set -euo pipefail

# -- Standardwerte --------------------------------------------------------
ESP_SIZE_MB=2048
DATA_SIZE_GB=5        # Groesse der Datenpartition
MIN_SYSTEM_GB=15      # Minimale Groesse fuer Systempartition
DRY_RUN=false
FORCE=false

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

usage() {
    cat << 'EOF'
Verwendung: 0-right-partition-layout.sh <DISK> [OPTIONEN]

Argumente:
  DISK                Ziel-Disk (z.B. /dev/sda, /dev/nvme0n1)

Optionen:
  --data-size SIZE    Groesse der Datenpartition (Standard: 5G)
  --dry-run           Zeigt nur an was gemacht wuerde, aendert nichts
  --force             Keine Bestaetigungsabfrage
  -h, --help          Diese Hilfe anzeigen

Layout:
  sda1  2G      ESP (vfat)           UEFI-Bootloader
  sda2  Rest    System (btrfs)       @root + @snap_* Snapshots
  sda3  5G      Daten (btrfs)        @data (persistent)

Rollback erfolgt ueber btrfs-Snapshots, nicht ueber A/B-Partitionen.
GRUB bootet normalerweise subvol=@root. Bei 3 fehlgeschlagenen Boots
wird automatisch auf den letzten Snapshot zurueckgeschaltet.

Beispiele:
  0-right-partition-layout.sh /dev/sda                    # Standard
  0-right-partition-layout.sh /dev/sda --data-size 10G    # 10GB Daten
  0-right-partition-layout.sh /dev/nvme0n1 --dry-run      # Nur anzeigen
  0-right-partition-layout.sh /dev/sda --force             # Ohne Abfrage
EOF
    exit 0
}

# Groesse in GB parsen (akzeptiert "25G", "25", "25GB")
parse_size_gb() {
    local input="${1^^}"  # uppercase
    input="${input%B}"    # entferne trailing B
    input="${input%G}"    # entferne trailing G
    if ! [[ "$input" =~ ^[0-9]+$ ]]; then
        fatal "Ungueltige Groessenangabe: $1 (erwartet z.B. 5G)"
    fi
    echo "$input"
}

# -- Argumente parsen -----------------------------------------------------
DISK=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        /dev/*)
            DISK="$1"
            ;;
        --data-size)
            DATA_SIZE_GB=$(parse_size_gb "$2")
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --force)
            FORCE=true
            ;;
        -h|--help)
            usage
            ;;
        *)
            fatal "Unbekanntes Argument: $1\nSiehe --help"
            ;;
    esac
    shift
done

[[ -z "$DISK" ]] && fatal "Keine Disk angegeben.\nVerwendung: $0 /dev/sda [OPTIONEN]"

# -- Validierung ----------------------------------------------------------
[[ $EUID -ne 0 ]] && fatal "Dieses Script muss als root ausgefuehrt werden."
[[ ! -b "$DISK" ]] && fatal "$DISK ist kein Block-Device."

# Pruefe ob Disk gemountet ist
if grep -q "^${DISK}" /proc/mounts; then
    fatal "$DISK oder eine Partition davon ist noch gemountet!"
fi

# Partitionsbezeichnung: NVMe, eMMC und NBD verwenden "p"-Suffix
if [[ "$DISK" == *nvme* ]] || [[ "$DISK" == *mmcblk* ]] || [[ "$DISK" == *nbd* ]]; then
    PART_PREFIX="${DISK}p"
else
    PART_PREFIX="${DISK}"
fi

# -- Disk-Groesse ermitteln -----------------------------------------------
DISK_BYTES=$(blockdev --getsize64 "$DISK")
DISK_GB=$((DISK_BYTES / 1024 / 1024 / 1024))

log "Ziel-Disk: $DISK"
log "Disk-Groesse: ${DISK_GB} GB (${DISK_BYTES} Bytes)"

# -- System-Groesse berechnen ---------------------------------------------
# System = Disk - ESP (~1GB aufgerundet) - Daten
SYSTEM_GB=$((DISK_GB - 1 - DATA_SIZE_GB))

if [[ $SYSTEM_GB -lt $MIN_SYSTEM_GB ]]; then
    fatal "Disk zu klein! ${DISK_GB} GB reicht nicht fuer ${MIN_SYSTEM_GB}GB System + ${DATA_SIZE_GB}GB Daten.\nMindestens $((MIN_SYSTEM_GB + DATA_SIZE_GB + 1)) GB erforderlich."
fi

log "System-Partition: ${SYSTEM_GB} GB (Rest nach ESP + Daten)"
log "Daten-Partition: ${DATA_SIZE_GB} GB"

# -- Layout anzeigen ------------------------------------------------------
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  ThinForge Partitionslayout fuer ${DISK} (${DISK_GB} GB)${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""
printf "  %-12s  %-8s  %-6s  %-8s  %s\n" "Partition" "Groesse" "Typ" "FS" "Beschreibung"
printf "  %-12s  %-8s  %-6s  %-8s  %s\n" "─────────" "───────" "───" "──" "────────────"
ESP_DISPLAY=$(( ESP_SIZE_MB >= 1024 ? ESP_SIZE_MB / 1024 : ESP_SIZE_MB ))
ESP_UNIT=$(( ESP_SIZE_MB >= 1024 ? 1 : 0 ))
printf "  %-12s  %-8s  %-6s  %-8s  %s\n" "${PART_PREFIX}1" "${ESP_DISPLAY}$([ $ESP_UNIT -eq 1 ] && echo G || echo M)" "EF00" "vfat"  "EFI System Partition"
printf "  %-12s  %-8s  %-6s  %-8s  %s\n" "${PART_PREFIX}2" "~${SYSTEM_GB}G" "8300" "btrfs" "System (@root + Snapshots)"
printf "  %-12s  %-8s  %-6s  %-8s  %s\n" "${PART_PREFIX}3" "${DATA_SIZE_GB}G" "8300" "btrfs" "Daten (@data)"
echo ""

# -- Dry-Run? -------------------------------------------------------------
if $DRY_RUN; then
    log "Dry-Run: Keine Aenderungen vorgenommen."
    exit 0
fi

# -- Bestaetigung ---------------------------------------------------------
if ! $FORCE; then
    echo -e "${RED}ACHTUNG: Alle Daten auf ${DISK} werden unwiderruflich geloescht!${NC}"
    echo ""
    read -r -p "Fortfahren? (ja/nein): " CONFIRM
    if [[ "$CONFIRM" != "ja" ]]; then
        log "Abgebrochen."
        exit 0
    fi
    echo ""
fi

# -- Partitionierung -----------------------------------------------------
log "Loesche bestehende Partitionstabelle..."
wipefs -af "$DISK"
sgdisk --zap-all "$DISK"

log "Erstelle GPT-Partitionen..."
sgdisk -n 1:0:+${ESP_SIZE_MB}M  -t 1:ef00 -c 1:"EFI System Partition"  "$DISK"
sgdisk -n 2:0:-${DATA_SIZE_GB}G -t 2:8300 -c 2:"ThinForge System"      "$DISK"
sgdisk -n 3:0:0                  -t 3:8300 -c 3:"Daten"                  "$DISK"

# Kernel ueber neue Partitionen informieren
partprobe "$DISK" 2>/dev/null || true
sleep 1

# In containers, partition device nodes may not be auto-created.
# Create them manually from /proc/partitions if needed.
if [[ "$DISK" == *nbd* ]]; then
    local_dev=$(basename "$DISK")
    awk -v dev="$local_dev" '$4 ~ dev"p" { system("mknod /dev/" $4 " b " $1 " " $2) }' /proc/partitions 2>/dev/null || true
fi

log "Partitionstabelle erstellt:"
sgdisk -p "$DISK"
echo ""

# -- Dateisysteme formatieren --------------------------------------------
log "Formatiere ESP (vfat)..."
mkfs.vfat -F 32 -n ESP "${PART_PREFIX}1"

log "Formatiere System-Partition (btrfs)..."
mkfs.btrfs -f -L "ThinForge" "${PART_PREFIX}2"

log "Formatiere Daten-Partition (btrfs)..."
mkfs.btrfs -f -L "Daten" "${PART_PREFIX}3"

# -- Subvolumes erstellen ------------------------------------------------
_MNT=$(mktemp -d)
trap 'umount "$_MNT" 2>/dev/null; rmdir "$_MNT" 2>/dev/null' EXIT

log "Erstelle @root Subvolume auf System-Partition..."
mount "${PART_PREFIX}2" "$_MNT"
btrfs subvolume create "$_MNT/@root"
umount "$_MNT"

log "Erstelle @data Subvolume auf Daten-Partition..."
mount "${PART_PREFIX}3" "$_MNT"
btrfs subvolume create "$_MNT/@data"
umount "$_MNT"

rmdir "$_MNT"
trap - EXIT

# -- UUIDs ausgeben -------------------------------------------------------
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Partitionierung abgeschlossen${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

UUID_ESP=$(blkid -s UUID -o value "${PART_PREFIX}1")
UUID_SYSTEM=$(blkid -s UUID -o value "${PART_PREFIX}2")
UUID_DATA=$(blkid -s UUID -o value "${PART_PREFIX}3")

printf "  %-8s  %-10s  UUID=%-38s  %s\n" "ESP"    "${PART_PREFIX}1" "$UUID_ESP"    "(vfat)"
printf "  %-8s  %-10s  UUID=%-38s  %s\n" "System" "${PART_PREFIX}2" "$UUID_SYSTEM" "(btrfs, @root)"
printf "  %-8s  %-10s  UUID=%-38s  %s\n" "Daten"  "${PART_PREFIX}3" "$UUID_DATA"   "(btrfs, @data)"

echo ""
echo "fstab:"
echo "  UUID=${UUID_SYSTEM}  /          btrfs  subvol=@root,defaults,compress=zstd:3  0  1"
echo "  UUID=${UUID_ESP}     /boot/efi  vfat   umask=0077                             0  1"
echo "  UUID=${UUID_DATA}    /data      btrfs  subvol=@data,defaults,compress=zstd:3  0  2"
echo ""
log "Fertig. Naechster Schritt: OS in @root installieren."
