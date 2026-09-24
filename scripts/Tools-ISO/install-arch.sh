#!/bin/bash
#
# ThinForge — Arch Linux Installation vorbereiten + nachbereiten
#
# Setzt voraus, dass die offizielle Arch-Live-ISO mit Calamares-Installer
# verwendet wird (verfuegbar seit der Calamares-Integration in archiso).
#
# Dieses Script hat zwei Modi:
#
#   VORHER (vor dem Calamares-Installer):
#     sudo bash install-arch.sh prepare
#     → Passt Calamares an: @root statt @, Daten-Partition
#     → Danach den Installer ganz normal starten
#
#   NACHHER (nach dem Calamares-Installer, im installierten System):
#     sudo bash install-arch.sh finish [--server=https://...]
#     → GRUB mit ThinForge Boot-Logik
#     → ThinForge Agent installieren
#
# Ausfuehrung von der Arch-Live-ISO oder vom eingerichteten System:
#   mount /dev/sr1 /mnt
#   sudo bash /mnt/install-arch.sh prepare
#   # → Installer starten, Arch installieren (btrfs!)
#   # → Ins neue System booten
#   sudo bash /mnt/install-arch.sh finish
#

set -euo pipefail

# -- Hilfsfunktionen ------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()   { echo -e "${GREEN}[thinforge]${NC} $*"; }
warn()  { echo -e "${YELLOW}[thinforge]${NC} $*"; }
error() { echo -e "${RED}[thinforge]${NC} $*" >&2; }
fatal() { error "$*"; exit 1; }


# ══════════════════════════════════════════════════════════════════════════
# PREPARE — Calamares fuer ThinForge anpassen
# ══════════════════════════════════════════════════════════════════════════

do_prepare() {
    # Disk-Layout entsteht im ThinForge-UI ('Basis HD erstellen'). Hier nur
    # noch Calamares-Konfiguration, Calamares meldet sich selbst, falls die
    # Disk nicht passt.
    log "Preparing Calamares for ThinForge..."

    # Calamares mount.conf — verschiedene Pfade je nach Arch-ISO-Variante
    local mount_conf=""
    for candidate in \
        /etc/calamares/modules/mount.conf \
        /usr/share/calamares/modules/mount.conf \
        /run/archiso/airootfs/usr/share/calamares/modules/mount.conf; do
        if [ -f "$candidate" ]; then
            mount_conf="$candidate"
            break
        fi
    done

    if [ -z "$mount_conf" ]; then
        fatal "Calamares mount.conf not found.\nAre you running on an Arch Live ISO with Calamares?"
    fi

    log "Found: $mount_conf"

    # Alle bekannten mount.conf Dateien anpassen (Calamares kann von verschiedenen Pfaden lesen)
    local changed=0
    for conf in \
        /etc/calamares/modules/mount.conf \
        /usr/share/calamares/modules/mount.conf; do
        [ -f "$conf" ] || continue
        cp "$conf" "${conf}.bak"
        # Single-Root-Layout: alles unter / (inkl. /home, /var/cache, /var/log)
        # gehoert zum gleichen Subvolume @root. Defaults legen separate
        # @home/@cache/@log an, die vom Btrfs-Send-Delta nicht erfasst
        # werden — Update bringt Programme mit, aber keine Desktop-Files
        # / User-Configs in /home.
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
        ' "$conf" > "${conf}.tmp" && mv "${conf}.tmp" "$conf"
        log "Adjusted: $conf (single-root layout, @home/@cache/@log removed)"
        changed=$((changed + 1))
    done

    if [ "$changed" -eq 0 ]; then
        warn "No mount.conf could be modified."
    fi

    # Zeige aktuelle Konfiguration
    echo ""
    echo -e "${CYAN}Subvolume configuration:${NC}"
    grep -E "subvolume:|mountPoint:" "$mount_conf" | head -20
    echo ""

    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Preparation complete!${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${YELLOW}Next steps:${NC}"
    echo ""
    echo -e "  1. Start Arch installer (Calamares)"
    echo -e "  2. During partitioning:"
    echo -e "     - Choose 'Erase disk' (recommended)"
    echo -e "     - OR 'Manual partitioning':"
    echo -e "       → Partition 1: 2 GB, FAT32, /boot/efi, flag: boot"
    echo -e "       → Partition 2: remainder, btrfs, /"
    echo -e "       → Partition 3: already present from UI — do NOT reassign (stays data partition)"
    echo -e "     - Choose btrfs as filesystem!"
    echo -e "     - Bootloader: ${YELLOW}GRUB${NC} (NOT systemd-boot/refind — ThinForge requires GRUB)"
    echo -e "  3. Complete installation"
    echo -e "  4. Boot into the new system (NOT Live ISO)"
    echo -e "  5. Mount Tools-ISO and run finish:"
    echo -e "     ${CYAN}sudo mount /dev/sr1 /mnt${NC}"
    echo -e "     ${CYAN}sudo bash /mnt/install-arch.sh finish${NC}"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════
# FINISH — GRUB + Agent im installierten System einrichten
# ══════════════════════════════════════════════════════════════════════════

do_finish() {
    local THINFORGE_SERVER="${1:-}"

    log "ThinForge configuration in installed system..."

    local SCRIPT_DIR_FINISH
    SCRIPT_DIR_FINISH="$(cd "$(dirname "$0")" && pwd)"

    # Pruefen ob wir im installierten System sind (nicht Live-ISO)
    if [ -d /run/archiso ] || [ -f /run/archiso/bootmnt/arch ]; then
        fatal "You are still on the Live ISO!\nPlease boot into the installed system and run from there."
    fi

    # Pruefen ob GRUB als Bootloader installiert ist
    if [ ! -d /boot/grub ] && [ ! -f /etc/default/grub ]; then
        fatal "GRUB not found — Arch appears to have been installed with systemd-boot/refind.\nThinForge requires GRUB for snapshot boot."
    fi

    # Pruefen ob btrfs mit @root
    local root_source
    root_source=$(findmnt -n -o SOURCE / 2>/dev/null || echo "")
    if echo "$root_source" | grep -q "@root"; then
        log "Root subvolume: @root detected"
    elif echo "$root_source" | grep -q "@"; then
        warn "Root subvolume is '@' instead of '@root' — Calamares prepare was not run."
        warn "Delta updates will still work if the subvolume is named consistently."
    else
        warn "No btrfs subvolume detected as root: $root_source"
    fi

    # ── GRUB: Arch-nativen Bootloader beibehalten ─────────────────────
    # Kein eigener GRUB-Bootloader. Arch's grub-mkconfig + grub-btrfs
    # erkennen btrfs-Snapshots automatisch und fuegen sie als Boot-Eintraege
    # im GRUB-Menue ein. Rollback = Snapshot im GRUB-Menue waehlen.

    log "Configuring GRUB (Arch-native + grub-btrfs)..."

    # GRUB-Timeout sichtbar machen (damit Snapshot-Auswahl moeglich ist)
    if [ -f /etc/default/grub ]; then
        sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub
        sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' /etc/default/grub
        log "GRUB menu visible (2s timeout)"
    fi

    # grub-btrfs installieren (fuegt Snapshot-Eintraege beim naechsten
    # grub-mkconfig hinzu, z.B. bei Kernel-Updates via pacman-Hook)
    if ! pacman -Qi grub-btrfs &>/dev/null; then
        log "Installing grub-btrfs..."
        pacman -S --noconfirm --needed grub-btrfs 2>/dev/null || warn "grub-btrfs could not be installed"
    fi

    # /.snapshots = btrfs-Toplevel mounten, damit grub-btrfs bei
    # grub-mkconfig die @snap_* Subvolumes als Boot-Eintraege findet.
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

    # grub-btrfs: Single-Root-Layout-Namen + ROOT_SV_old ignorieren.
    # @snap_*_home und der neueste @snap_* werden von agent-apply-delta.sh
    # dynamisch zur Liste hinzugefuegt, damit genau EIN Rollback sichtbar ist.
    local grub_btrfs_conf="/etc/default/grub-btrfs/config"
    if [ -f "$grub_btrfs_conf" ]; then
        sed -i 's/^GRUB_BTRFS_IGNORE_SPECIFIC_PATH=.*/GRUB_BTRFS_IGNORE_SPECIFIC_PATH=("@" "@root" "@rootfs" "@data" "@root_old" "@rootfs_old" "@_old")/' "$grub_btrfs_conf"
        log "grub-btrfs: active subvolumes + ROOT_SV_old ignored"
    fi

    # grub-btrfsd DEAKTIVIEREN — der Daemon ueberwacht /.snapshots und
    # triggert grub-mkconfig bei Snapshot-Aenderungen, was auf Thin Clients
    # mit wenig RAM das System einfriert. GRUB wird stattdessen beim
    # Shutdown von agent-apply-delta.sh aktualisiert (VOR dem Subvolume-Swap).
    systemctl disable grub-btrfsd.service 2>/dev/null || true
    systemctl stop grub-btrfsd.service 2>/dev/null || true
    log "grub-btrfsd disabled (GRUB will be updated by agent-apply-delta.sh)"


    # grub-btrfs-overlayfs in initramfs aktivieren — ermoeglicht das Booten
    # von read-only Snapshots aus dem GRUB-Menue. Der Hook legt automatisch
    # ein overlayfs ueber den Snapshot (Schreibzugriffe gehen in tmpfs/RAM).
    if [ -f /usr/lib/initcpio/hooks/grub-btrfs-overlayfs ]; then
        if ! grep -q "grub-btrfs-overlayfs" /etc/mkinitcpio.conf; then
            sed -i 's/^HOOKS=(\(.*\))/HOOKS=(\1 grub-btrfs-overlayfs)/' /etc/mkinitcpio.conf
            log "grub-btrfs-overlayfs hook configured (initramfs will be rebuilt at the end)"
        else
            log "grub-btrfs-overlayfs already present in mkinitcpio.conf"
        fi
    else
        warn "grub-btrfs-overlayfs hook not present — snapshot boot remains read-only"
    fi

    # Snapper / Timeshift deinstallieren falls vom Calamares-Profil mitgebracht;
    # nicht benoetigt — grub-btrfs + agent-apply-delta.sh decken Rollback ab.
    local snap_pkgs=()
    pacman -Qi timeshift &>/dev/null && snap_pkgs+=(timeshift)
    pacman -Qi snapper &>/dev/null && snap_pkgs+=(snapper)
    pacman -Qi snap-pac &>/dev/null && snap_pkgs+=(snap-pac)
    if [ ${#snap_pkgs[@]} -gt 0 ]; then
        pacman -Rns --noconfirm "${snap_pkgs[@]}" 2>/dev/null || true
        log "${snap_pkgs[*]} uninstalled"
    fi

    # GRUB-Config neu generieren (mit Snapshot-Eintraegen)
    grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null
    log "GRUB config generated (grub-mkconfig)"

    # ── Data-Partition anlegen (Groesse wird abgefragt) ──────────────

    local DATA_SCRIPT="${SCRIPT_DIR_FINISH}/advanced/create-data-partition.sh"

    # Fallback: ISO-Mountpoints durchsuchen
    if [ ! -f "$DATA_SCRIPT" ]; then
        for mnt in /mnt /mnt/iso /run/media/*/THINFORGE_TOOLS /media/*/THINFORGE_TOOLS; do
            if [ -f "${mnt}/advanced/create-data-partition.sh" ]; then
                DATA_SCRIPT="${mnt}/advanced/create-data-partition.sh"
                break
            fi
        done
    fi

    if [ -f "$DATA_SCRIPT" ]; then
        bash "$DATA_SCRIPT"
    else
        warn "create-data-partition.sh not found — data partition must be created manually"
    fi

    # Sanity-Check: ohne /data ist der gesamte Agent-State (Token, Cert,
    # Binary, Updates) beim naechsten Reboot weg. Ohne diesen Riegel legen die
    # `mkdir -p /data/...` weiter unten stillschweigend echte Verzeichnisse auf
    # dem @root-Subvolume an; die installierte systemd-Unit traegt aber
    # `Requires=data.mount` und ist damit nie erfuellbar — der Agent startet
    # nie, der Client taucht nie in der Flotte auf, und beim ersten
    # Delta-Update ist der ganze Zustand samt Token und Trust-Anchor fort.
    # Erreichbar ueber den warn-Zweig direkt darueber: liegt die Tools-ISO
    # ausserhalb der bekannten Mountpunkte, wird create-data-partition.sh nicht
    # gefunden und do_finish lief bisher trotzdem weiter. Gleicher Riegel wie
    # in install-debian.sh und install-debian-minimal.sh.
    mountpoint -q /data || fatal "/data not mounted — aborting before agent install.\nRun advanced/create-data-partition.sh first (or mount the data partition manually), then start this script again."

    # ── Zusaetzliche Pakete ──────────────────────────────────────────

    log "Installing additional packages..."

    # Pakete die Calamares evtl. nicht installiert hat
    local EXTRA_PKGS=(nfs-utils zstd curl jq python xorg-xdpyinfo minisign zenity yad)
    local TO_INSTALL=()

    for pkg in "${EXTRA_PKGS[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            TO_INSTALL+=("$pkg")
        fi
    done

    if [ ${#TO_INSTALL[@]} -gt 0 ]; then
        log "Installiere: ${TO_INSTALL[*]}"
        # Sync DBs einmal vorab, damit "package not found"-Errors echt sind und
        # nicht durch veraltete Repo-Caches kommen.
        pacman -Sy --noconfirm >/dev/null 2>&1 || warn "pacman -Sy failed — package sources may not be reachable"
        # Pro Paket einzeln installieren + Erfolg tracken. Verhindert, dass ein
        # einzelner Fehler die ganze Liste zerreißt (war vorher: chrony fehlte
        # still, weil 2>/dev/null den pacman-Output verschluckte).
        local FAILED=()
        for pkg in "${TO_INSTALL[@]}"; do
            if pacman -S --noconfirm --needed "$pkg"; then
                log "  ✓ $pkg"
            else
                FAILED+=("$pkg")
                warn "  ✗ $pkg — installation failed"
            fi
        done
        if [ ${#FAILED[@]} -gt 0 ]; then
            warn "Packages not installed: ${FAILED[*]}"
            warn "Please install manually with 'pacman -S ${FAILED[*]}'."
        fi
    else
        log "All required packages already present."
    fi

    # NetBird-Agent über offizielles Install-Skript installieren
    # (pacman-Repo hat netbird auf Arch-Familie nicht; Tools-ISO-Live-System
    # hat Internet, daher direkter Download). Idempotent.
    if ! command -v netbird >/dev/null 2>&1; then
        log "Installing NetBird agent (official install script)..."
        curl -fsSL https://pkgs.netbird.io/install.sh | sh \
            || warn "NetBird installation failed — please check manually"
    fi

    # ThinVPN-Migration: NetBird-Daemon Default disabled.
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

    # ── NTP konfigurieren (ThinForge-Server als Zeitquelle) ─────────
    # Ohne korrekte Uhrzeit schlaegt die TLS-Zertifikatspruefung fehl.
    # Klone haben kein Internet → Default-Pools (pool.ntp.org) sind tot,
    # System bleibt unsynchronisiert. ThinForge-Server stellt NTP bereit.

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
        # Primaer-Pfad: systemd-timesyncd (immer auf systemd-Distros vorhanden,
        # kein Extra-Paket noetig). Auch idempotent, ueberschreibt nur unsere
        # eigene drop-in-Datei.
        mkdir -p /etc/systemd/timesyncd.conf.d
        cat > /etc/systemd/timesyncd.conf.d/thinforge.conf <<TSYNC
[Time]
NTP=${NTP_SERVER}
FallbackNTP=
TSYNC
        # chrony deaktivieren falls vorhanden — sonst Konflikt mit timesyncd.
        if systemctl list-unit-files chronyd.service &>/dev/null; then
            systemctl disable --now chronyd 2>/dev/null || true
        fi
        systemctl enable --now systemd-timesyncd 2>/dev/null || true
        systemctl restart systemd-timesyncd 2>/dev/null || true
        log "NTP configured: server $NTP_SERVER (systemd-timesyncd)"
    else
        warn "Could not determine NTP server — clone will remain unsynchronised with default NTP pool without internet"
    fi

    # SSH wird NACH dem Agent konfiguriert (Key muss zuerst installiert sein)

    # ── ThinForge Agent installieren ─────────────────────────────────

    log "Installing ThinForge agent..."

    # Script-Verzeichnis (Tools-ISO) — pruefen ob ISO gemountet ist
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    local INSTALL_SCRIPT="${SCRIPT_DIR}/advanced/1-create-client-management.sh"

    # Fallback: ISO-Mountpoints durchsuchen falls Script nicht neben uns liegt
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
        # (siehe docs/security/security-audit-2026-04-18.md F-CR-01). Tools-ISO ist
        # die einzige Provisioning-Quelle.
        warn "Agent script not found on ISO ($INSTALL_SCRIPT)."
        warn "Tools ISO is incomplete — rebuild it and boot again."
    fi

    # ── Initiale Version setzen ────────────────────────────────────

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
    systemctl enable sshd 2>/dev/null || true
    log "SSH key-only auth enabled"

    # ── System auf den neuesten Stand bringen ────────────────────────

    log "Updating system (pacman -Syu)..."
    pacman -Syu --noconfirm 2>/dev/null || warn "System update failed"
    log "System updated."

    # ── Paket-Cache aufraeumen ───────────────────────────────────────

    log "Cleaning package cache..."
    pacman -Scc --noconfirm 2>/dev/null || true
    log "Package cache cleaned."

    # ── initramfs neu bauen (nach allen Paket-Updates) ──────────────
    # Muss am Ende laufen damit alle Hooks (grub-btrfs-overlayfs etc.)
    # und alle Kernel-Updates im initramfs enthalten sind.

    log "Rebuilding initramfs..."
    mkinitcpio -P 2>/dev/null || warn "mkinitcpio failed"
    log "initramfs updated."

    # ── ThinForge-Branding (Wallpaper + Boot-Splash) ─────────────────
    # tf-wall.png als Desktop-Hintergrund, GRUB-/Plymouth-Splash und Login-
    # Hintergrund setzen. Nicht-fatal — Branding-Fehler brechen das Setup nicht ab.
    local BRANDING_SCRIPT="${SCRIPT_DIR}/DistroTweaks/install-branding-arch.sh"
    if [ ! -f "$BRANDING_SCRIPT" ]; then
        for mnt in /mnt /mnt/iso /run/media/*/THINFORGE_TOOLS /media/*/THINFORGE_TOOLS; do
            if [ -f "${mnt}/DistroTweaks/install-branding-arch.sh" ]; then
                BRANDING_SCRIPT="${mnt}/DistroTweaks/install-branding-arch.sh"
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
    echo -e "  System:     Updated + cache cleaned"
    echo ""
    echo -e "  ${YELLOW}Next steps:${NC}"
    echo -e "  1. Customise system (drivers, software, configuration)"
    echo -e "  2. Shut down VM"
    echo -e "  3. In ThinForge UI: 'Save update' → version v1.0"
    echo -e "  4. Deploy clones to clients"
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
        do_prepare
        ;;
    finish)
        [[ $EUID -ne 0 ]] && fatal "Must be run as root."
        SERVER=""
        for arg in "$@"; do
            case "$arg" in
                --server=*) SERVER="${arg#--server=}" ;;
            esac
        done
        # Interaktive Abfrage direkt am Scriptanfang — User antwortet einmal,
        # danach laeuft do_finish unattended durch (Paket-Installs,
        # Agent-Setup, GRUB-Config etc.).
        do_finish "$SERVER"
        ;;
    --help|-h|"")
        echo "ThinForge Arch Linux Installation"
        echo ""
        echo "Usage:"
        echo "  install-arch.sh prepare              Prepare Calamares (before installer)"
        echo "  install-arch.sh finish [--server=URL] Set up GRUB + agent (after installer)"
        echo ""
        echo "Workflow:"
        echo "  1. Boot from Arch Live ISO (with Calamares)"
        echo "  2. Mount Tools ISO:    sudo mount /dev/sr1 /mnt"
        echo "  3. Prepare:            sudo bash /mnt/install-arch.sh prepare"
        echo "  4. Calamares installer: choose btrfs + GRUB!"
        echo "  5. Boot into new system"
        echo "  6. Mount Tools ISO:    sudo mount /dev/sr1 /mnt"
        echo "  7. Finish:             sudo bash /mnt/install-arch.sh finish"
        ;;
    *)
        fatal "Unknown action: $ACTION\nUse 'prepare' or 'finish'"
        ;;
esac
