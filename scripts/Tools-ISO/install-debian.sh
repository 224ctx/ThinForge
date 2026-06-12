#!/bin/bash
#
# ThinForge — Debian Installation vorbereiten + nachbereiten
#
# Dieses Script hat zwei Modi:
#
#   VORHER (vor dem Calamares-Installer):
#     sudo bash install-debian.sh prepare /dev/vda
#     → Partitioniert die Disk: ESP + System (btrfs) + Data (btrfs)
#     → Passt Calamares an: @root statt @
#     → Danach den Installer starten, "Manuelle Partitionierung" waehlen
#
#   NACHHER (nach dem Calamares-Installer, im installierten System):
#     sudo bash install-debian.sh finish [--server=https://...]
#     → GRUB mit ThinForge Boot-Logik
#     → ThinForge Agent installieren
#
# Ausfuehrung von der Debian Live-ISO:
#   sudo bash install-debian.sh prepare /dev/vda
#   # → Calamares starten, "Manuelle Partitionierung",
#   #   Partition 1 → /boot/efi, Partition 2 → / (btrfs)
#   #   Partition 3 NICHT zuweisen (bleibt fuer /data)
#   # → Ins neue System booten
#   sudo bash install-debian.sh finish
#

set -euo pipefail

# -- Konfiguration -----------------------------------------------------------

ESP_SIZE_MB=2048

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


# Partitionsbezeichnung: NVMe/eMMC/NBD verwenden "p"-Suffix
part_prefix() {
    local disk="$1"
    if [[ "$disk" == *nvme* ]] || [[ "$disk" == *mmcblk* ]] || [[ "$disk" == *nbd* ]]; then
        echo "${disk}p"
    else
        echo "$disk"
    fi
}

# ══════════════════════════════════════════════════════════════════════════
# PREPARE — Disk partitionieren + Calamares anpassen
# ══════════════════════════════════════════════════════════════════════════

do_prepare() {
    local DISK="${1:-}"
    [ -z "$DISK" ] && fatal "No disk specified.\nUsage: install-debian.sh prepare /dev/vda"
    [ ! -b "$DISK" ] && fatal "$DISK is not a block device."

    log "Configuring Calamares (disk layout must be created first via ThinForge UI 'Create Base HD')..."

    local PP
    PP=$(part_prefix "$DISK")

    # ── 2. Calamares konfigurieren ───────────────────────────────────

    log "Configuring Calamares..."

    # Calamares-Config an beiden Pfaden sicherstellen
    # Debian liefert mount.conf und partition.conf NICHT mit —
    # sie muessen erstellt werden, sonst ignoriert Calamares sie.
    local cala_dirs=(/etc/calamares/modules /usr/share/calamares/modules)

    for cala_dir in "${cala_dirs[@]}"; do
        mkdir -p "$cala_dir" 2>/dev/null || continue

        # mount.conf: Single-Root-Layout (@root, kein separates @home/@cache/@log).
        # /home, /var/cache, /var/log gehoeren zum selben Subvolume — sonst
        # erfasst der Btrfs-Send-Delta sie nicht und Updates bringen zwar
        # Programme, aber keine Desktop-Files / User-Configs.
        local mount_conf="$cala_dir/mount.conf"
        if [ -f "$mount_conf" ]; then
            cp "$mount_conf" "${mount_conf}.bak"
            awk '
                BEGIN { in_block = 0 }
                /^btrfsSubvolumes:/ {
                    print "btrfsSubvolumes:"
                    print "    - mountPoint: /"
                    print "      subvolume: /@root"
                    in_block = 1
                    next
                }
                in_block && /^[A-Za-z]/ { in_block = 0; print; next }
                in_block { next }
                { print }
            ' "$mount_conf" > "${mount_conf}.tmp" && mv "${mount_conf}.tmp" "$mount_conf"
            log "Adjusted: $mount_conf (single-root layout)"
        else
            cat > "$mount_conf" <<'MOUNTCONF'
# ThinForge btrfs Subvolume-Layout (Single-Root)
btrfsSubvolumes:
    - mountPoint: /
      subvolume: /@root
MOUNTCONF
            log "Created: $mount_conf"
        fi

        # partition.conf: btrfs als Default-Dateisystem
        local part_conf="$cala_dir/partition.conf"
        if [ -f "$part_conf" ]; then
            cp "$part_conf" "${part_conf}.bak"
            if grep -q "defaultFileSystemType" "$part_conf"; then
                sed -i 's/^defaultFileSystemType:.*/defaultFileSystemType: "btrfs"/' "$part_conf"
            else
                echo 'defaultFileSystemType: "btrfs"' >> "$part_conf"
            fi
            log "Adjusted: $part_conf (btrfs default)"
        else
            cat > "$part_conf" <<'PARTCONF'
# ThinForge Partitions-Konfiguration
efiSystemPartitionSize: 2048M
defaultFileSystemType: "btrfs"
PARTCONF
            log "Created: $part_conf"
        fi
    done

    # ── 3. Anweisungen ───────────────────────────────────────────────

    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Preparation complete!${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Disk:          $DISK"
    echo -e "  ${PP}1:  ESP         (${ESP_SIZE_MB} MB, FAT32)"
    echo -e "  ${PP}2:  System      (btrfs)"
    echo ""
    echo -e "  ${YELLOW}Next steps:${NC}"
    echo ""
    echo -e "  1. Start Debian installer (Calamares)"
    echo -e "  2. Choose ${YELLOW}Manual Partitioning${NC}!"
    echo -e "  3. Assign partitions:"
    echo -e "       ${PP}1 → /boot/efi  (keep, FAT32)"
    echo -e "       ${PP}2 → /          (format, btrfs)"
    echo -e "       ${PP}3 → ${YELLOW}DO NOT ASSIGN${NC} (reserved for /data)"
    echo -e "  4. Carry out the installation"
    echo -e "  5. Boot into the new system"
    echo -e "  6. Run finish:"
    echo -e "     ${CYAN}sudo bash install-debian.sh finish${NC}"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════
# FINISH — GRUB + Agent im installierten System einrichten
# ══════════════════════════════════════════════════════════════════════════

do_finish() {
    local THINFORGE_SERVER="${1:-}"

    log "ThinForge configuration in the installed system..."

    local SCRIPT_DIR_FINISH
    SCRIPT_DIR_FINISH="$(cd "$(dirname "$0")" && pwd)"

    # Pruefen ob wir im installierten System sind (nicht Live-ISO)
    if [ -d /run/live/medium ] || [ -d /run/live/rootfs ]; then
        fatal "You are still on the Live ISO!\nPlease boot into the installed system and run this there."
    fi

    # Pruefen ob btrfs mit @root
    local root_source
    root_source=$(findmnt -n -o SOURCE / 2>/dev/null || echo "")
    if echo "$root_source" | grep -q "@root"; then
        log "Root subvolume: @root detected"
    elif echo "$root_source" | grep -q "@"; then
        warn "Root subvolume is '@' instead of '@root' — Calamares prepare was not run."
        warn "Delta updates will still work if the subvolume is consistently named."
    else
        warn "No btrfs subvolume detected as root: $root_source"
    fi

    # ── GRUB konfigurieren ───────────────────────────────────────────

    log "Configuring GRUB..."

    if [ -f /etc/default/grub ]; then
        sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub
        sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' /etc/default/grub
        log "GRUB menu visible (2s timeout)"
    fi

    # grub-btrfs installieren
    if ! dpkg -s grub-btrfs &>/dev/null 2>&1; then
        if apt-cache show grub-btrfs &>/dev/null 2>&1; then
            log "Installing grub-btrfs..."
            apt-get install -y -qq grub-btrfs 2>/dev/null || warn "grub-btrfs could not be installed"
        else
            log "Installing grub-btrfs from GitHub..."
            apt-get install -y -qq git make 2>/dev/null || true
            cd /tmp && git clone https://github.com/Antynea/grub-btrfs.git && cd grub-btrfs && make install
            rm -rf /tmp/grub-btrfs
            cd /
        fi
    fi

    # mawk-Kompatibilitaet fuer 41_snapshots-btrfs (siehe install-debian-
    # minimal.sh fuer Begruendung — `\s` greift unter mawk nicht).
    local snap_script="/etc/grub.d/41_snapshots-btrfs"
    if [ -f "$snap_script" ] && grep -q '\\s' "$snap_script"; then
        sed -i 's|\\s|[[:space:]]|g' "$snap_script"
        log "41_snapshots-btrfs patched (mawk-compatible whitespace regex)"
    fi

    # /.snapshots = btrfs-Toplevel mounten
    local root_uuid
    root_uuid=$(findmnt -n -o UUID /)
    if [ -n "$root_uuid" ]; then
        mkdir -p /.snapshots
        if ! grep -q '/.snapshots' /etc/fstab; then
            echo "UUID=${root_uuid} /.snapshots btrfs subvolid=5,defaults,noauto 0 0" >> /etc/fstab
            log "/.snapshots toplevel mount added to fstab"
        fi
        mount /.snapshots 2>/dev/null || true
    fi

    # grub-btrfs: aktive Subvolumes ignorieren
    local grub_btrfs_conf="/etc/default/grub-btrfs/config"
    if [ -f "$grub_btrfs_conf" ]; then
        sed -i 's/^GRUB_BTRFS_IGNORE_SPECIFIC_PATH=.*/GRUB_BTRFS_IGNORE_SPECIFIC_PATH=("@" "@root" "@rootfs" "@data" "@root_old" "@rootfs_old" "@_old")/' "$grub_btrfs_conf"
        log "grub-btrfs: active subvolumes + ROOT_SV_old ignored"
    fi

    # grub-btrfsd DEAKTIVIEREN
    systemctl disable grub-btrfsd.service 2>/dev/null || true
    systemctl stop grub-btrfsd.service 2>/dev/null || true
    log "grub-btrfsd disabled (GRUB is updated by agent-apply-delta.sh)"


    # overlayfs in initramfs aktivieren — ermoeglicht das Booten von
    # read-only Snapshots aus dem GRUB-Menue mit overlayfs (tmpfs upper).
    if [ -d /etc/initramfs-tools ]; then
        local OVERLAY_CHANGED=false

        # Build-Time Hook: overlay Modul + btrfs Binary in initramfs
        if [ ! -f /etc/initramfs-tools/hooks/overlay-snap-ro ]; then
            cat > /etc/initramfs-tools/hooks/overlay-snap-ro <<'HOOKEOF'
#!/bin/sh
PREREQ=""
prereqs() { echo "$PREREQ"; }
case "$1" in prereqs) prereqs; exit 0;; esac
. /usr/share/initramfs-tools/hook-functions
manual_add_modules overlay
copy_exec /usr/bin/btrfs /usr/bin
HOOKEOF
            chmod +x /etc/initramfs-tools/hooks/overlay-snap-ro
            OVERLAY_CHANGED=true
        fi

        # Runtime Script: overlayfs bei read-only btrfs Root aktivieren
        mkdir -p /etc/initramfs-tools/scripts/local-bottom
        if [ ! -f /etc/initramfs-tools/scripts/local-bottom/overlay-snap-ro ]; then
            cat > /etc/initramfs-tools/scripts/local-bottom/overlay-snap-ro <<'RUNTIMEEOF'
#!/bin/sh
PREREQ=""
prereqs() { echo "$PREREQ"; }
case "$1" in prereqs) prereqs; exit 0;; esac

# Nur bei btrfs Root-Filesystem aktiv
ROOT_FSTYPE=$(awk -v mnt="${rootmnt}" '$2 == mnt {print $3}' /proc/mounts)
[ "$ROOT_FSTYPE" = "btrfs" ] || exit 0

# Nur bei read-only Snapshot (btrfs property ro=true)
RO_STATUS=$(btrfs property get "${rootmnt}" ro 2>/dev/null || echo "ro=false")
case "$RO_STATUS" in *ro=true*) ;; *) exit 0 ;; esac

# overlayfs: lower=ro Snapshot, upper=tmpfs
LOWER=$(mktemp -d -p /)
RAM=$(mktemp -d -p /)
mount --move "${rootmnt}" "${LOWER}"
mount -t tmpfs cowspace "${RAM}"
mkdir -p "${RAM}/upper" "${RAM}/work"
mount -t overlay -o "lowerdir=${LOWER},upperdir=${RAM}/upper,workdir=${RAM}/work" rootfs "${rootmnt}"
RUNTIMEEOF
            chmod +x /etc/initramfs-tools/scripts/local-bottom/overlay-snap-ro
            OVERLAY_CHANGED=true
        fi

        if [ "$OVERLAY_CHANGED" = true ]; then
            log "overlayfs hook files created (initramfs will be rebuilt at the end)"
        else
            log "overlayfs hook already installed"
        fi
    fi

    # GRUB-Config neu generieren
    update-grub 2>/dev/null
    log "GRUB config generated (update-grub)"

    # ── Data-Partition einhaengen ────────────────────────────────────
    # Die Data-Partition wurde bereits in prepare erstellt (Partition 3).
    # Hier wird sie nur in fstab eingetragen und gemountet.

    if mountpoint -q /data 2>/dev/null; then
        log "Data partition already mounted: /data"
    else
        # Data-Partition finden (Label "Daten" oder dritte Partition)
        local root_dev
        root_dev=$(findmnt -n -o SOURCE / | sed 's/\[.*//')
        local disk_dev
        disk_dev=$(echo "$root_dev" | sed 's/[0-9]*$//')
        local data_dev="${disk_dev}3"

        # Fallback: nach Label suchen
        if [ ! -b "$data_dev" ]; then
            data_dev=$(blkid -L "Daten" 2>/dev/null || true)
        fi

        if [ -b "$data_dev" ]; then
            local data_uuid
            data_uuid=$(blkid -s UUID -o value "$data_dev" 2>/dev/null)
            local data_fstype
            data_fstype=$(blkid -s TYPE -o value "$data_dev" 2>/dev/null)

            if [ "$data_fstype" = "btrfs" ] && [ -n "$data_uuid" ]; then
                mkdir -p /data
                if ! grep -q '/data' /etc/fstab; then
                    echo "UUID=${data_uuid}  /data  btrfs  subvol=@data,defaults  0  0" >> /etc/fstab
                    log "Data partition added to fstab: $data_dev (UUID=$data_uuid)"
                fi
                mount /data 2>/dev/null || mount -o subvol=@data "$data_dev" /data 2>/dev/null || true
                if mountpoint -q /data; then
                    log "Data partition mounted: /data"
                else
                    fatal "Data partition could not be mounted: $data_dev\nAgent install would write files into the root FS that would be shadowed by /data after reboot.\nCheck the partition (blkid, btrfs subvolume list) and run the script again."
                fi
            else
                fatal "Partition $data_dev is not btrfs (fstype='$data_fstype').\nAgent install would write files into the root FS that would be shadowed after reboot.\nCreate the data partition correctly (see create-data-partition.sh) and run the script again."
            fi
        else
            fatal "No data partition found (neither ${disk_dev}3 nor label 'Daten').\nAgent install would write files into the root FS that would be shadowed after reboot.\nCreate it manually: bash create-data-partition.sh, then run the script again."
        fi
    fi

    # Sanity-Check: ohne /data ist der gesamte Agent-State (Token, Cert,
    # Binary, Updates) im Reboot weg. Lieber jetzt abbrechen als spaeter
    # mit unverstaendlichen Heartbeat-Fehlern dastehen.
    mountpoint -q /data || fatal "/data not mounted — aborting before agent install."

    # ── Zusaetzliche Pakete ──────────────────────────────────────────

    log "Installing additional packages..."

    # NetBird-Repo wird hier nicht eingebunden — NetBird wird unten via
    # offiziellem Install-Skript installiert (Tools-ISO-Live-System hat
    # Internet; der spätere Klon-Betrieb läuft im LAN ohne Internet).
    local EXTRA_PKGS=(nfs-common zstd curl jq python3 x11-utils minisign chrony zenity yad)
    local TO_INSTALL=()

    for pkg in "${EXTRA_PKGS[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null 2>&1; then
            TO_INSTALL+=("$pkg")
        fi
    done

    if [ ${#TO_INSTALL[@]} -gt 0 ]; then
        log "Installing: ${TO_INSTALL[*]}"
        # Sync DBs einmal vorab, damit "package not found"-Errors echt sind und
        # nicht durch veraltete Repo-Caches kommen.
        apt-get update -qq || warn "apt-get update failed — package sources may not be reachable"
        # Pro Paket einzeln installieren + Erfolg tracken. Verhindert, dass ein
        # einzelner Fehler die ganze Liste zerreißt (war vorher: chrony fehlte
        # still, weil 2>/dev/null den pacman-Output verschluckte).
        local FAILED=()
        for pkg in "${TO_INSTALL[@]}"; do
            if apt-get install -y -qq "$pkg"; then
                log "  ✓ $pkg"
            else
                FAILED+=("$pkg")
                warn "  ✗ $pkg — installation failed"
            fi
        done
        if [ ${#FAILED[@]} -gt 0 ]; then
            warn "Packages not installed: ${FAILED[*]}"
            warn "Please install manually with 'apt-get install ${FAILED[*]}'."
        fi
    else
        log "All required packages already installed."
    fi

    # NetBird-Agent installieren — Tools-ISO-Live-System hat Internet,
    # daher offizielles Install-Skript. Idempotent (skip wenn schon da).
    if ! command -v netbird >/dev/null 2>&1; then
        log "Installing NetBird agent (official install script)..."
        curl -fsSL https://pkgs.netbird.io/install.sh | sh \
            || warn "NetBird installation failed — please check manually"
    fi

    # ThinVPN-Migration: NetBird-Daemon Default disabled. Aktivierung
    # erfolgt erst beim ersten `vpn.enroll`-Heartbeat-Command vom Backend.
    # Dienst nach der Standard-Installation umkonfigurieren: Force-Relay
    # (Clients ohne direkte P2P-Route bleiben über den Relay-Server erreichbar)
    # und IPv6 deaktivieren. Die Env-Vars landen in der systemd-Unit und
    # überleben das spätere Umlenken von /etc/netbird auf /data/netbird.
    netbird service reconfigure --service-env NB_FORCE_RELAY=true,NB_DISABLE_IPV6=true 2>/dev/null \
        || warn "NetBird service reconfigure (NB_FORCE_RELAY/NB_DISABLE_IPV6) failed"

    systemctl disable netbird.service 2>/dev/null || true
    systemctl stop netbird.service 2>/dev/null || true
    mkdir -p /data/netbird
    chmod 700 /data/netbird
    # NetBird 0.71+ hält Enrollment/PrivateKey in /var/lib/netbird (ältere
    # Versionen: /etc/netbird). Beide auf das persistente /data/netbird zeigen,
    # damit das Enrollment Delta-Updates überlebt — sonst läge der State auf der
    # OS-Subvolume @, die beim Update getauscht wird.
    rm -rf /etc/netbird /var/lib/netbird
    ln -s /data/netbird /etc/netbird
    ln -s /data/netbird /var/lib/netbird

    # ── NTP konfigurieren (Chrony → Management-Server) ─────────────
    # Ohne korrekte Uhrzeit schlaegt die TLS-Zertifikatspruefung fehl.
    # Der ThinForge-Server betreibt einen Chrony NTP-Server fuer die Clients.

    if command -v chronyd &>/dev/null; then
        local NTP_SERVER=""
        if [ -n "$THINFORGE_SERVER" ]; then
            NTP_SERVER=$(printf '%s' "$THINFORGE_SERVER" | sed -E 's|^[a-z]+://||; s|[/:].*$||')
        fi
        if [ -z "$NTP_SERVER" ]; then
            for su in "${SCRIPT_DIR_FINISH}/advanced/server_url" /mnt/advanced/server_url /mnt/iso/advanced/server_url /run/media/*/THINFORGE_TOOLS/advanced/server_url /media/*/THINFORGE_TOOLS/advanced/server_url; do
                if [ -f "$su" ]; then
                    NTP_SERVER=$(tr -d '[:space:]' < "$su" | sed -E 's|^[a-z]+://||; s|[/:].*$||')
                    [ -n "$NTP_SERVER" ] && break
                fi
            done
        fi
        if [ -z "$NTP_SERVER" ]; then
            NTP_SERVER=$(ip route | awk '/default/{print $3}')
        fi
        if [ -n "$NTP_SERVER" ]; then
            mkdir -p /etc/chrony/conf.d
            cat > /etc/chrony/conf.d/thinforge.conf <<NTPCONF
# ThinForge NTP — Management-Server als Zeitquelle
server ${NTP_SERVER} iburst prefer
NTPCONF
            # Default-Pool-Server entfernen (nur Server nutzen)
            sed -i '/^pool /d' /etc/chrony/chrony.conf 2>/dev/null || true
            sed -i '/^server .*pool\.ntp/d' /etc/chrony/chrony.conf 2>/dev/null || true
            log "NTP configured: server $NTP_SERVER"
        fi
        systemctl enable chrony 2>/dev/null || true
        systemctl restart chrony 2>/dev/null || true
        log "NTP enabled (chrony)"
    fi

    # ── SSH-Server installieren (Key kommt vom Agent) ──────────────

    if ! command -v sshd &>/dev/null; then
        log "Installing openssh-server..."
        apt-get update -qq
        apt-get install -y -qq openssh-server
    fi
    # Noch NICHT konfigurieren oder neustarten — der Agent installiert
    # zuerst den SSH-Key, dann wird sshd sicher konfiguriert.

    # ── ThinForge Agent installieren ─────────────────────────────────

    log "Installing ThinForge agent..."

    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    local INSTALL_SCRIPT="${SCRIPT_DIR}/advanced/1-create-client-management.sh"

    # Fallback: ISO-Mountpoints durchsuchen
    if [ ! -f "$INSTALL_SCRIPT" ]; then
        for mnt in /mnt /mnt/iso /run/media/*/THINFORGE_TOOLS /media/*/THINFORGE_TOOLS; do
            if [ -f "${mnt}/advanced/1-create-client-management.sh" ]; then
                INSTALL_SCRIPT="${mnt}/advanced/1-create-client-management.sh"
                break
            fi
        done
    fi

    if [ -f "$INSTALL_SCRIPT" ]; then
        log "Agent script found on ISO: $INSTALL_SCRIPT"
        if [ -n "$THINFORGE_SERVER" ]; then
            export THINFORGE_SERVER
        fi
        bash "$INSTALL_SCRIPT"
    else
        # Curl-Bootstrap-Modus wurde aus Sicherheitsgruenden entfernt
        # (siehe docs/security-audit-2026-04-18.md F-CR-01). Tools-ISO ist
        # die einzige Provisioning-Quelle.
        warn "Agent script not found on ISO ($INSTALL_SCRIPT)."
        warn "Tools ISO is incomplete — rebuild and reboot."
    fi

    # ── Initiale Version setzen ────────────────────────────────────
    # Ohne installed_version weiss der Server nicht welche Version
    # der Client hat und kann keine Delta-Updates zuweisen.

    if [ ! -f /data/thinforge/installed_version ]; then
        mkdir -p /data/thinforge
        echo "v1.000" > /data/thinforge/installed_version
        log "Initial version set: v1.000"
    fi

    # ── SSH haerten (Key wurde vom Agent installiert) ──────────────

    log "Configuring SSH..."
    if [ -f /etc/ssh/sshd_config ]; then
        sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
        sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
        sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    fi
    systemctl enable ssh 2>/dev/null || true
    systemctl restart ssh 2>/dev/null || true
    log "SSH key-only auth enabled"

    # ── System auf den neuesten Stand bringen ────────────────────────

    log "Updating system (apt-get dist-upgrade)..."
    apt-get update -qq
    apt-get dist-upgrade -y -qq 2>/dev/null || warn "System update failed"
    log "System updated."

    # ── Paket-Cache aufraeumen ───────────────────────────────────────

    log "Cleaning package cache..."
    apt-get clean
    apt-get autoremove -y -qq 2>/dev/null || true
    log "Package cache cleaned."

    # ── initramfs neu bauen (nach allen Paket-Updates) ──────────────
    # Muss am Ende laufen damit alle Hooks (overlay-snap-ro etc.)
    # und alle Kernel-Updates im initramfs enthalten sind.

    log "Rebuilding initramfs..."
    update-initramfs -u 2>/dev/null || warn "update-initramfs failed"
    log "initramfs updated."

    # ── ThinForge-Branding (Wallpaper + Boot-Splash) ─────────────────
    # tf-wall.png als Desktop-Hintergrund, GRUB-/Plymouth-Splash und Login-
    # Hintergrund setzen. Nicht-fatal — Branding-Fehler brechen das Setup nicht ab.
    local BRANDING_SCRIPT="${SCRIPT_DIR}/DistroTweaks/install-branding-debian.sh"
    if [ ! -f "$BRANDING_SCRIPT" ]; then
        for mnt in /mnt /mnt/iso /run/media/*/THINFORGE_TOOLS /media/*/THINFORGE_TOOLS; do
            if [ -f "${mnt}/DistroTweaks/install-branding-debian.sh" ]; then
                BRANDING_SCRIPT="${mnt}/DistroTweaks/install-branding-debian.sh"
                break
            fi
        done
    fi
    if [ -f "$BRANDING_SCRIPT" ]; then
        log "Applying ThinForge branding (wallpaper + boot splash)..."
        bash "$BRANDING_SCRIPT" || warn "Branding failed — skipped."
    else
        warn "Branding script not found — skipped."
    fi

    # ── Fertig ───────────────────────────────────────────────────────

    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  ThinForge configuration complete!${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  GRUB:       ThinForge boot logic with rollback"
    echo -e "  Agent:      Installed"
    echo -e "  SSH:        Key-only auth enabled"
    echo -e "  Data:       /data mounted"
    echo -e "  System:     Updated + cache cleaned"
    echo ""
    echo -e "  ${YELLOW}Next steps:${NC}"
    echo -e "  1. Customize system (drivers, software, configuration)"
    echo -e "  2. Shut down the VM"
    echo -e "  3. In ThinForge UI: 'Save update' → version v1.0"
    echo -e "  4. Deploy clone to clients"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════
# HAUPTPROGRAMM
# ══════════════════════════════════════════════════════════════════════════

ACTION="${1:-}"
shift 2>/dev/null || true

case "$ACTION" in
    prepare)
        [[ $EUID -ne 0 ]] && fatal "Must be run as root."
        DISK=""
        for arg in "$@"; do
            case "$arg" in
                /dev/*) DISK="$arg" ;;
            esac
        done
        [ -z "$DISK" ] && fatal "No disk specified.\nUsage: install-debian.sh prepare /dev/vda"
        [ ! -b "$DISK" ] && fatal "$DISK is not a block device."
        do_prepare "$DISK"
        ;;
    finish)
        [[ $EUID -ne 0 ]] && fatal "Must be run as root."
        SERVER=""
        for arg in "$@"; do
            case "$arg" in
                --server=*) SERVER="${arg#--server=}" ;;
            esac
        done
        do_finish "$SERVER"
        ;;
    --help|-h|"")
        echo "ThinForge Debian installation (live ISO with Calamares)"
        echo ""
        echo "Usage:"
        echo "  install-debian.sh prepare /dev/vda       Check disk layout + configure Calamares"
        echo "  install-debian.sh finish [--server=URL]  Set up GRUB + agent (after installer)"
        echo ""
        echo "Workflow:"
        echo "  0. Click 'Create Base HD' in ThinForge UI (cloning VM card)"
        echo "  1. Boot from Debian live ISO"
        echo "  2. Prepare:            sudo bash install-debian.sh prepare /dev/vda"
        echo "  3. Start Calamares → choose Manual Partitioning"
        echo "     Partition 1 → /boot/efi, Partition 2 → / (btrfs, subvol=@root)"
        echo "     Partition 3 → DO NOT ASSIGN (reserved for /data)"
        echo "  4. Boot into the new system"
        echo "  5. Finish:             sudo bash install-debian.sh finish"
        ;;
    *)
        fatal "Unknown action: $ACTION\nUse 'prepare /dev/vda' or 'finish'"
        ;;
esac
