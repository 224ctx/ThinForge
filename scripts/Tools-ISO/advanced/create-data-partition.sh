#!/bin/bash
#
# ThinForge — Data-Partition einrichten (auto-mode, dynamisch)
#
# Hintergrund: Die Basis-HD wird im UI ('Basis HD erstellen') mit drei
# Partitionen angelegt — ESP, System (btrfs), und am Ende eine Data-
# Partition mit @data-Subvolume. Calamares & Co. installieren auf
# p1+p2 und sollen p3 nicht anfassen. Dieses Script wird vom
# install-*.sh finish aufgerufen und sorgt dafuer, dass /data am Ende
# eingehaengt + in fstab eingetragen ist.
#
# Verhalten je nach Zustand der Disk:
#   1. p3 existiert bereits mit btrfs + @data           -> nur mounten + fstab
#   2. p3 existiert mit btrfs ohne @data                -> @data anlegen, mounten + fstab
#   3. p3 existiert mit fremdem FS                      -> abbrechen (Operator entscheiden lassen)
#   4. p3 existiert nicht, aber Trailing-Free-Space da  -> neue Partition aus dem Free-Space
#                                                          (nimmt 100 % davon — keine
#                                                          Aufruferseite mehr, die das limitieren
#                                                          wuerde, weil die Soll-Groesse schon
#                                                          beim Basis-HD-Erstellen festgelegt
#                                                          wurde), btrfs + @data, mounten + fstab
#   5. Weder p3 noch Trailing-Free-Space                -> abbrechen mit Hinweis
#
# Es wird **nicht mehr** in die Root-Partition reingesneeded — kein
# btrfs-online-resize-Pfad. Die Geometrie kommt aus der UI; das hier
# soll nur reaktiv darauf reagieren, was tatsaechlich auf der Disk steht.
#
# Aufruf:
#   sudo bash create-data-partition.sh
#
# Voraussetzungen:
#   - GPT-Partitionstabelle
#   - sfdisk, btrfs-progs, mkfs.btrfs verfuegbar
#

set -euo pipefail

# -- Hilfsfunktionen --------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[data-partition]${NC} $*"; }
warn()  { echo -e "${YELLOW}[data-partition]${NC} $*"; }
fatal() { echo -e "${RED}[data-partition]${NC} $*" >&2; exit 1; }

# -- Checks ------------------------------------------------------------------

[[ $EUID -ne 0 ]] && fatal "Must be run as root."

for cmd in sfdisk btrfs mkfs.btrfs blkid blockdev partprobe findmnt; do
    command -v "$cmd" &>/dev/null || fatal "$cmd not found — please install it"
done

# -- Root-Partition und Disk ermitteln --------------------------------------

ROOT_DEV=$(findmnt -n -o SOURCE / | sed 's/\[.*//')   # z.B. /dev/vda2
DISK_DEV=$(echo "$ROOT_DEV" | sed 's/[0-9]*$//')       # z.B. /dev/vda
ROOT_PARTNUM=$(echo "$ROOT_DEV" | grep -o '[0-9]*$')   # z.B. 2
DATA_PARTNUM=$(( ROOT_PARTNUM + 1 ))
DATA_DEV="${DISK_DEV}${DATA_PARTNUM}"

# -- Helfer: @data anlegen falls fehlend, mounten, in fstab eintragen -------

ensure_mount_and_fstab() {
    local dev="$1"
    log "Mounting data partition + fstab entry: $dev"

    # @data-Subvolume sicherstellen
    local probe
    probe=$(mktemp -d)
    mount "$dev" "$probe"
    if ! btrfs subvolume show "$probe/@data" &>/dev/null; then
        log "  @data subvolume missing -> creating"
        btrfs subvolume create "$probe/@data"
    fi
    umount "$probe"
    rmdir "$probe"

    # /data mounten
    mkdir -p /data
    if ! mountpoint -q /data; then
        mount -o subvol=@data "$dev" /data
    fi

    # fstab-Eintrag idempotent
    local uuid
    uuid=$(blkid -s UUID -o value "$dev")
    [ -n "$uuid" ] || fatal "Could not read UUID from $dev"
    if ! grep -qE "^UUID=${uuid}\\s" /etc/fstab; then
        echo "UUID=${uuid}  /data  btrfs  subvol=@data,defaults  0  0" >> /etc/fstab
        log "  fstab entry for UUID=${uuid} added"
    else
        log "  fstab entry for UUID=${uuid} already present"
    fi

    log "Done: $dev -> /data (subvol=@data)"
}

# -- Fall 1-3: Partition existiert schon ------------------------------------

if [ -b "$DATA_DEV" ]; then
    fstype=$(blkid -o value -s TYPE "$DATA_DEV" 2>/dev/null || true)
    case "$fstype" in
        btrfs)
            log "Data partition exists (${DATA_DEV}, btrfs) — setting up only"
            ensure_mount_and_fstab "$DATA_DEV"
            exit 0
            ;;
        "")
            log "Data partition exists (${DATA_DEV}) without FS — formatting as btrfs"
            mkfs.btrfs -f -L data "$DATA_DEV"
            ensure_mount_and_fstab "$DATA_DEV"
            exit 0
            ;;
        *)
            fatal "Partition $DATA_DEV exists with FS type '$fstype' (not btrfs).\nDecide manually whether to reformat, then run again."
            ;;
    esac
fi

# -- Fall 4: Partition fehlt — Trailing-Free-Space nutzen --------------------

log "Partition $DATA_DEV does not exist — checking for trailing free space"

# sfdisk -F gibt freie Bereiche aus. Format:
#   Unpartitioned space /dev/vda: 19,5 GiB, ...
#       Start         End     Sectors    Size
#   ...      free
# Wir nehmen den letzten "free"-Eintrag (= Trailing-Free-Space).
FREE_LINE=$(sfdisk -F "$DISK_DEV" 2>/dev/null | awk '/^[[:space:]]*[0-9]+/{line=$0} END{print line}')
if [ -z "$FREE_LINE" ]; then
    fatal "No free space found at the end of $DISK_DEV.\nThe base HD was created in the UI with a data partition — the installer appears to have removed it.\nEither use Calamares 'Manual partitioning' and leave p${DATA_PARTNUM} alone, or enlarge the disk."
fi

FREE_START=$(echo "$FREE_LINE" | awk '{print $1}')
FREE_END=$(echo "$FREE_LINE" | awk '{print $2}')
FREE_SECTORS=$(echo "$FREE_LINE" | awk '{print $3}')
FREE_BYTES=$(( FREE_SECTORS * 512 ))
FREE_GIB=$(( FREE_BYTES / 1024 / 1024 / 1024 ))

if [ "$FREE_SECTORS" -lt $(( 1024 * 1024 * 2 )) ]; then  # < 1 GiB
    fatal "Trailing free space too small (${FREE_SECTORS} sectors, < 1 GiB).\nLeave at least 1 GiB free for a usable data partition."
fi

log "Trailing free space: Start=${FREE_START} End=${FREE_END} Size=${FREE_GIB} GiB"
log "Creating new partition ${DATA_DEV} (uses all trailing free space)"

# Partition via sfdisk anhaengen (ein-Zeilen-Append-Modus)
echo "${DATA_DEV} : start=${FREE_START}, size=${FREE_SECTORS}, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=\"data\"" \
    | sfdisk --append --force "$DISK_DEV"
partprobe "$DISK_DEV" 2>/dev/null || true
sleep 1

[ -b "$DATA_DEV" ] || fatal "Partition $DATA_DEV not present after sfdisk + partprobe — kernel has not picked up the new table. Try rebooting."

log "Formatting data partition (btrfs)..."
mkfs.btrfs -f -L data "$DATA_DEV"

ensure_mount_and_fstab "$DATA_DEV"

log "Data partition created:"
log "  Device:      ${DATA_DEV}"
log "  Size:        ${FREE_GIB} GiB (trailing free space of disk)"
log "  Filesystem:  btrfs (@data subvolume)"
log "  Mountpoint:  /data"
