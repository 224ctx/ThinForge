#!/bin/bash
#
# ThinForge — Debian-Minimal-Installation (debian-13.4.0-amd64-netinst)
#
# Variante fuer die netinst-ISO: kein Live-System, kein Calamares — nur der
# klassische Debian-Installer (d-i). Workflow gespiegelt zu install-debian.sh,
# Calamares-spezifische Schritte entfernt; prepare laeuft aus dem d-i-
# Rescue-Mode statt aus Live-Env.
#
# Zwei Modi:
#
#   VORHER (vor dem d-i-Partitionierer, aus dem Rescue-Mode):
#     sudo bash install-debian-minimal.sh prepare /dev/vda
#     → Partitioniert die Disk: ESP + System (btrfs) + Data (btrfs)
#     → Erstellt das Root-Subvolume (Single-Root-Layout) auf System,
#       @data auf der Data-Partition (d-i kann das nicht ootb).
#     → Danach den d-i fortfahren lassen, "Manuell" waehlen,
#       Partitionen wie von prepare angelegt zuweisen (KEIN Reformat).
#
#   NACHHER (nach d-i-Installation, im installierten System):
#     sudo bash install-debian-minimal.sh finish [--server=https://...]
#     → GRUB mit ThinForge Boot-Logik
#     → ThinForge Agent installieren
#     → Identisch zu install-debian.sh finish
#
# Workflow von debian-13.4.0-amd64-netinst.iso:
#   1. Boot-Menue → "Advanced options" → "Rescue mode"
#   2. Rescue-Schritte durchklicken bis "Execute a shell in the installer
#      environment" → "Continue"
#   3. Im BusyBox-Shell:
#        modprobe btrfs
#        # SCRIPT_QUELLE: USB-Stick mounten oder via wget aus Mgmt-Netz holen
#        bash install-debian-minimal.sh prepare /dev/vda
#   4. Reboot, normaler d-i-Boot
#   5. Im d-i: "Partitionen manuell aendern":
#        Partition 1 → /boot/efi  (FAT32 erhalten, NICHT formatieren)
#        Partition 2 → /          (btrfs erhalten, KEIN Reformat,
#                                  Subvolume-Mount-Option: subvol=@root)
#        Partition 3 → NICHT verwenden (bleibt fuer /data)
#   6. Installation durchlaufen, ins neue System booten
#   7. sudo bash install-debian-minimal.sh finish
#

set -euo pipefail

# Alle apt/dpkg-Aufrufe nicht-interaktiv: ohne TTY versucht debconf sonst
# Dialog/Readline/Teletype-Frontends und gibt seitenweise Fallback-Warnungen
# aus (oder haengt im schlimmsten Fall an einem Prompt). Gilt prozessweit fuer
# alle hier gestarteten apt-/dpkg-/Sub-Skript-Aufrufe.
export DEBIAN_FRONTEND=noninteractive

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


# Tools-ISO dynamisch finden und gewuenschte Datei darauf lokalisieren.
# $1 = relativer Pfad innerhalb der ISO (z.B. "advanced/1-...sh")
# Druckt absoluten Pfad auf stdout, leer wenn nicht gefunden.
#
# Suchreihenfolge:
#   1. Verzeichnis dieses Skripts (Standard: User hat ISO gemountet und das
#      install-debian-minimal.sh direkt von dort gestartet).
#   2. Bereits gemountete Volumes mit Label 'THINFORGE_TOOLS' (genisoimage
#      setzt dieses Label per -V beim ISO-Build, siehe rebuild_tools_iso()).
#   3. Noch nicht gemountete Block-Devices mit Label 'THINFORGE_TOOLS'
#      (CD/DVD/USB) — werden read-only nach /mnt/thinforge-tools gemountet.
find_tools_iso_script() {
    local relpath="$1"
    local script_self_dir
    script_self_dir="$(cd "$(dirname "$0")" && pwd)"

    # 1. Eigenes Script-Verzeichnis
    if [ -f "${script_self_dir}/${relpath}" ]; then
        echo "${script_self_dir}/${relpath}"
        return 0
    fi

    # 2. Bereits gemountetes THINFORGE_TOOLS-Volume
    local mnt
    if command -v findmnt >/dev/null 2>&1; then
        mnt=$(findmnt -n -o TARGET -S "LABEL=THINFORGE_TOOLS" 2>/dev/null | head -n1)
        if [ -n "$mnt" ] && [ -f "${mnt}/${relpath}" ]; then
            echo "${mnt}/${relpath}"
            return 0
        fi
    fi

    # 3. Unmountede Block-Devices nach Label durchsuchen und mounten
    local dev label
    for dev in /dev/sr0 /dev/sr1 /dev/sr2 /dev/cdrom /dev/dvd /dev/disk/by-label/THINFORGE_TOOLS; do
        [ -b "$dev" ] || continue
        label=$(blkid -s LABEL -o value "$dev" 2>/dev/null)
        if [ "$label" = "THINFORGE_TOOLS" ]; then
            mkdir -p /mnt/thinforge-tools
            if mountpoint -q /mnt/thinforge-tools || mount -o ro "$dev" /mnt/thinforge-tools 2>/dev/null; then
                if [ -f "/mnt/thinforge-tools/${relpath}" ]; then
                    echo "/mnt/thinforge-tools/${relpath}"
                    return 0
                fi
            fi
        fi
    done

    return 1
}

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
# sudo-Berechtigung: lokale User per Checkbox auswaehlen
# ══════════════════════════════════════════════════════════════════════════
# Ganz zu Beginn von finish: der Operator waehlt aus, welche lokalen Login-User
# sudo-Rechte bekommen. Die Auswahl erscheint als GUI-Checkliste (yad, sonst
# zenity) auf dem Desktop, unter dem DIESES Skript laeuft — also als root-Prozess
# auf dem Display dieser root-Session (:0 oder :1, dynamisch ermittelt; ein
# parallel laufender Autologin-User kann :0 belegen, root landet dann auf :1).
# Den noetigen X-Cookie liefert das -auth-File des Xorg, der genau diesen Display
# bedient (fuer einen lokalen root-Client immer gueltig). Ohne X-Server faellt es
# auf eine whiptail-Checkliste am Terminal zurueck; ohne beides passiert nichts.
# Wird nichts ausgewaehlt, wird auch nichts angelegt. Ausgewaehlte User landen
# validiert (visudo -c) in /etc/sudoers.d/thinforge-admins.
configure_sudo_users() {
    log "Selecting local users for sudo access..."

    # 1. Lokale Login-User sammeln (UID 1000..64999, echtes Login-Shell).
    local users=() name pw uid gid gecos home shell
    while IFS=: read -r name pw uid gid gecos home shell; do
        [[ "$uid" =~ ^[0-9]+$ ]] || continue
        { [ "$uid" -ge 1000 ] && [ "$uid" -lt 65000 ]; } || continue
        case "$shell" in */nologin|*/false|"") continue ;; esac
        users+=("$name")
    done < /etc/passwd

    if [ ${#users[@]} -eq 0 ]; then
        log "  no local login users present — skipping."
        return 0
    fi

    # 2. Display + X-Cookie der Sitzung bestimmen, unter der dieses Skript laeuft
    #    (Script-Runner = root). Der Operator kann als root auf :0 ODER :1 sitzen
    #    (z.B. wenn daneben noch ein Autologin-User auf :0 laeuft), daher den
    #    Display NICHT hart auf :0 setzen:
    #      1. geerbtes $DISPLAY (Skript aus root's Desktop-Terminal gestartet),
    #      2. sonst die aktive x11/wayland-Session des Runner-Users via loginctl.
    #    Cookie dazu: geerbtes $XAUTHORITY, sonst das -auth-File des Xorg, der
    #    GENAU diesen Display bedient, sonst Session-Leader-Env, sonst ~/.Xauthority.
    local run_uid disp xauth leader=""
    run_uid=$(id -u)
    disp="${DISPLAY:-}"
    xauth="${XAUTHORITY:-}"
    if [ -z "$disp" ]; then
        local sid s_type s_user s_state
        while read -r sid; do
            [ -n "$sid" ] || continue
            s_type=$(loginctl show-session "$sid" -p Type --value 2>/dev/null)
            case "$s_type" in x11|wayland) ;; *) continue ;; esac
            s_user=$(loginctl show-session "$sid" -p User --value 2>/dev/null)
            [ "$s_user" = "$run_uid" ] || continue
            s_state=$(loginctl show-session "$sid" -p State --value 2>/dev/null)
            { [ "$s_state" = "active" ] || [ "$s_state" = "online" ]; } || continue
            disp=$(loginctl show-session "$sid" -p Display --value 2>/dev/null)
            leader=$(loginctl show-session "$sid" -p Leader --value 2>/dev/null)
            break
        done < <(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}')
    fi
    [ -z "$disp" ] && disp=":0"
    if [ -z "$xauth" ] || [ ! -s "$xauth" ]; then
        # -auth-File des Xorg, der genau $disp bedient (z.B. ".. :1 .. -auth FILE").
        xauth=$(ps -o args= -C Xorg 2>/dev/null | grep -E "(^| )${disp}( |\$)" | sed -n 's/.*-auth \([^ ]*\).*/\1/p' | head -1)
    fi
    if { [ -z "$xauth" ] || [ ! -s "$xauth" ]; } && [ -n "$leader" ]; then
        xauth=$(tr '\0' '\n' < "/proc/$leader/environ" 2>/dev/null | sed -n 's/^XAUTHORITY=//p' | head -1)
    fi
    if { [ -z "$xauth" ] || [ ! -s "$xauth" ]; } && [ -s "$HOME/.Xauthority" ]; then
        xauth="$HOME/.Xauthority"
    fi

    # GUI-Dialog-Tool sicherstellen (dieser Block laeuft vor der spaeteren
    # Paketinstallation; auf einem frischen System fehlt yad evtl. noch).
    if [ -n "$xauth" ] && [ -s "$xauth" ] \
       && ! command -v yad >/dev/null 2>&1 && ! command -v zenity >/dev/null 2>&1; then
        apt-get update -qq || true
        apt-get install -y -qq yad || true
    fi

    # 3. Auswahl einholen.
    local selected=() rc=0 raw="" ucol
    if [ -n "$xauth" ] && [ -s "$xauth" ] \
       && { command -v yad >/dev/null 2>&1 || command -v zenity >/dev/null 2>&1; }; then
        # Checkbox-Zeilen einmal bauen (FALSE = unmarkiert), fuer yad wie zenity.
        local rows=()
        for ucol in "${users[@]}"; do rows+=(FALSE "$ucol"); done
        if command -v yad >/dev/null 2>&1; then
            # WICHTIG: yad gibt bei OK nur die MARKIERTE Cursor-Zeile aus,
            # nicht die angehakten Checkboxen. Daher --print-all und danach
            # die TRUE-Zeilen filtern — mit --print-column=2 kam die Auswahl
            # nie an (Dialog erschien, Ergebnis blieb leer, kein sudo-Grant).
            raw=$(DISPLAY="$disp" XAUTHORITY="$xauth" LANG=C.UTF-8 NO_AT_BRIDGE=1 \
                    yad --list --checklist --center --width=460 --height=380 \
                        --title="ThinForge — sudo-Rechte" \
                        --text="Welche lokalen Benutzer sollen sudo-Rechte erhalten?\n(nichts auswaehlen = niemand)" \
                        --column="Auswahl:CHK" --column="Benutzer:TEXT" \
                        --separator="|" --print-all \
                        "${rows[@]}") && rc=0 || rc=$?
            if [ "$rc" -eq 0 ] && [ -n "$raw" ]; then
                local chk uname rest
                while IFS='|' read -r chk uname rest; do
                    [ "$chk" = "TRUE" ] && [ -n "$uname" ] && selected+=("$uname")
                done <<< "$raw"
            fi
        else
            raw=$(DISPLAY="$disp" XAUTHORITY="$xauth" LANG=C.UTF-8 NO_AT_BRIDGE=1 \
                    zenity --list --checklist --width=460 --height=380 \
                        --title="ThinForge — sudo-Rechte" \
                        --text="Welche lokalen Benutzer sollen sudo-Rechte erhalten?" \
                        --column="Auswahl" --column="Benutzer" \
                        --separator=$'\n' "${rows[@]}") && rc=0 || rc=$?
            [ "$rc" -eq 0 ] && [ -n "$raw" ] && mapfile -t selected <<< "$raw"
        fi
        log "  selection shown on display ${disp} (as $(id -un))."
    elif [ -t 0 ] && command -v whiptail >/dev/null 2>&1; then
        local wt=()
        for ucol in "${users[@]}"; do wt+=("$ucol" "" OFF); done
        raw=$(whiptail --title "ThinForge — sudo-Rechte" \
                --checklist "Welche lokalen Benutzer sollen sudo-Rechte erhalten?\n(Leertaste = an/aus, Enter = OK)" \
                20 64 10 "${wt[@]}" 3>&1 1>&2 2>&3) && rc=0 || rc=$?
        if [ "$rc" -eq 0 ] && [ -n "$raw" ]; then
            raw=${raw//\"/}
            read -r -a selected <<< "$raw"
        fi
    else
        warn "  no graphical session and no terminal — skipping (no sudo granted)."
        return 0
    fi

    # 4. Ergebnis -> sudoers (validiert). Leere Auswahl = nichts anlegen.
    if [ ${#selected[@]} -eq 0 ]; then
        log "  no users selected — no sudo rights granted."
        return 0
    fi

    local sudoers_file="/etc/sudoers.d/thinforge-admins"
    local tmp; tmp=$(mktemp)
    {
        echo "# ThinForge — sudo grants written by install-debian-minimal.sh"
        local s
        for s in "${selected[@]}"; do
            [ -n "$s" ] || continue
            echo "${s} ALL=(ALL:ALL) ALL"
        done
    } > "$tmp"
    chmod 0440 "$tmp"
    if visudo -cf "$tmp" >/dev/null 2>&1; then
        install -m 0440 -o root -g root "$tmp" "$sudoers_file"
        log "  sudo granted to: ${selected[*]} (-> $sudoers_file)"
        # Zusaetzlich in die Gruppe 'sudo' aufnehmen (wie Beta-installer.sh):
        # polkit/Desktop-Komponenten pruefen die Gruppenmitgliedschaft, nicht
        # sudoers.d. Auf Minimal-Installationen mit gesetztem root-Passwort
        # fehlt das sudo-Paket selbst — dann nachinstallieren.
        command -v sudo >/dev/null 2>&1 \
            || apt-get install -y -qq sudo \
            || warn "  'sudo' package could not be installed."
        for s in "${selected[@]}"; do
            [ -n "$s" ] || continue
            if usermod -aG sudo "$s" 2>/dev/null; then
                log "  '$s' added to group 'sudo' (effective at next login)."
            else
                warn "  could not add '$s' to group 'sudo'."
            fi
        done
        # Den (ersten) ausgewaehlten sudo-User zugleich als Autologin einrichten.
        local autologin_user="${selected[0]}"
        [ "${#selected[@]}" -gt 1 ] && warn "  autologin targets one user -> '${autologin_user}' (others: sudo only)."
        configure_autologin "$autologin_user"
    else
        warn "  sudoers validation failed — nothing written (autologin skipped)."
    fi
    rm -f "$tmp"
}

# Richtet LightDM-Autologin fuer $1 ein (Debian/XFCE). Wird aus
# configure_sudo_users fuer den ausgewaehlten sudo-User aufgerufen: Drop-in in
# /etc/lightdm/lightdm.conf.d/, wirkt beim naechsten Boot/DM-Start. Die
# autologin-Gruppe wird best-effort angelegt + zugewiesen (manche PAM-Setups
# verlangen die Mitgliedschaft).
configure_autologin() {
    local user="$1"
    [ -n "$user" ] || return 0
    if [ ! -d /etc/lightdm ] && ! command -v lightdm >/dev/null 2>&1; then
        warn "  LightDM not found — autologin for '${user}' skipped."
        return 0
    fi
    getent group autologin >/dev/null 2>&1 || groupadd autologin 2>/dev/null || true
    usermod -aG autologin "$user" 2>/dev/null || true
    install -d -m0755 /etc/lightdm/lightdm.conf.d
    cat > /etc/lightdm/lightdm.conf.d/20-thinforge-autologin.conf <<AUTOLOGIN
# ThinForge — Autologin fuer den ausgewaehlten sudo-User (install-debian-minimal.sh)
[Seat:*]
autologin-user=${user}
autologin-user-timeout=0
AUTOLOGIN
    log "  Autologin configured for '${user}' (LightDM; effective next boot)."
}

# ══════════════════════════════════════════════════════════════════════════
# Wallpaper sofort in laufenden Desktop-Sessions anwenden
# ══════════════════════════════════════════════════════════════════════════
# Das Branding (DistroTweaks) installiert /usr/local/bin/thinforge-set-
# wallpaper.sh als XDG-Autostart — der greift aber erst beim NAECHSTEN Login.
# xfconf/gsettings wirken nur innerhalb der User-Session (als root gestartet
# landen sie auf dem falschen DBus). Diese Funktion startet den Helper daher
# einmal pro bereits laufender grafischer Session: als der jeweilige User,
# mit der Umgebung (DISPLAY, DBus, XDG_CURRENT_DESKTOP) seiner Session.
apply_wallpaper_to_active_sessions() {
    local helper=/usr/local/bin/thinforge-set-wallpaper.sh
    if [ ! -x "$helper" ]; then
        warn "  wallpaper helper not installed ($helper) — immediate apply skipped."
        return 0
    fi
    command -v loginctl >/dev/null 2>&1 || return 0

    local sid s_type s_state s_user uname leader envpid
    while read -r sid; do
        [ -n "$sid" ] || continue
        s_type=$(loginctl show-session "$sid" -p Type --value 2>/dev/null)
        case "$s_type" in x11|wayland) ;; *) continue ;; esac
        s_state=$(loginctl show-session "$sid" -p State --value 2>/dev/null)
        { [ "$s_state" = "active" ] || [ "$s_state" = "online" ]; } || continue
        s_user=$(loginctl show-session "$sid" -p User --value 2>/dev/null)
        [ "$s_user" -ge 1000 ] 2>/dev/null || continue
        uname=$(loginctl show-session "$sid" -p Name --value 2>/dev/null)
        [ -n "$uname" ] || uname=$(getent passwd "$s_user" | cut -d: -f1 2>/dev/null)
        [ -n "$uname" ] || continue

        # Session-Umgebung besorgen: bevorzugt aus dem Session-Prozess der DE
        # (xfce4-session kennt DISPLAY/DBus sicher), sonst Session-Leader.
        envpid=$(pgrep -u "$uname" -x xfce4-session 2>/dev/null | head -1)
        [ -n "$envpid" ] || envpid=$(pgrep -u "$uname" -x xfdesktop 2>/dev/null | head -1)
        if [ -z "$envpid" ]; then
            leader=$(loginctl show-session "$sid" -p Leader --value 2>/dev/null)
            [ -n "$leader" ] && envpid="$leader"
        fi
        [ -n "$envpid" ] && [ -r "/proc/$envpid/environ" ] || continue

        local envargs=() var val
        for var in DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS XDG_CURRENT_DESKTOP XDG_RUNTIME_DIR; do
            val=$(tr '\0' '\n' < "/proc/$envpid/environ" 2>/dev/null | sed -n "s/^${var}=//p" | head -1)
            [ -n "$val" ] && envargs+=("${var}=${val}")
        done
        # Fallbacks: ohne DISPLAY kann der Helper nichts tun; ohne
        # XDG_CURRENT_DESKTOP wuerde er den falschen DE-Zweig waehlen.
        case " ${envargs[*]-} " in *" DISPLAY="*) ;; *)
            val=$(loginctl show-session "$sid" -p Display --value 2>/dev/null)
            [ -n "$val" ] && envargs+=("DISPLAY=${val}") || continue ;;
        esac
        case " ${envargs[*]-} " in *" XDG_CURRENT_DESKTOP="*) ;; *)
            pgrep -u "$uname" -x xfce4-session >/dev/null 2>&1 && envargs+=("XDG_CURRENT_DESKTOP=XFCE") ;;
        esac
        case " ${envargs[*]-} " in *" DBUS_SESSION_BUS_ADDRESS="*) ;; *)
            envargs+=("DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${s_user}/bus") ;;
        esac

        if runuser -u "$uname" -- env "${envargs[@]}" "$helper" 2>/dev/null; then
            log "  wallpaper applied in running session of '$uname' (session $sid)."
        else
            warn "  wallpaper helper failed for '$uname' (will apply at next login)."
        fi
    done < <(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}')
    return 0
}

# ══════════════════════════════════════════════════════════════════════════
# Cleanup + VDI-Clients (lagern in eigene Tools-ISO-Skripte aus)
# ══════════════════════════════════════════════════════════════════════════

# Ganz zu Beginn von finish: nicht mehr benoetigte vorinstallierte Desktop-Apps
# entfernen (DistroTweaks/cleanup-debian.sh). Unbedingter Aufruf, nicht-fatal.
run_debian_cleanup() {
    local CLEANUP_SCRIPT
    CLEANUP_SCRIPT="$(find_tools_iso_script DistroTweaks/cleanup-debian.sh || true)"
    if [ -n "$CLEANUP_SCRIPT" ] && [ -f "$CLEANUP_SCRIPT" ]; then
        log "Running Debian cleanup (removing unneeded preinstalled apps)..."
        bash "$CLEANUP_SCRIPT" || warn "Cleanup reported an issue — continuing."
    else
        warn "Cleanup script not found on Tools-ISO — skipping."
    fi
}

# Am Ende von finish: VDI-Client-Installation anbieten (interaktiv). Liegt der
# Installer auf der Tools-ISO, wird gefragt; ohne TTY (z.B. via SSH) wird nur
# der Pfad ausgegeben statt zu blockieren.
offer_vdi_install() {
    local VDI_SCRIPT
    VDI_SCRIPT="$(find_tools_iso_script DebianVDIClients/install-vdi-clients-debian.sh || true)"
    [ -n "$VDI_SCRIPT" ] && [ -f "$VDI_SCRIPT" ] || return 0
    echo ""
    if [ -t 0 ]; then
        local ans=""
        read -r -p "$(echo -e "${YELLOW}Install VDI clients (Citrix/Parallels/Omnissa) now? [y/N] ${NC}")" ans || true
        case "$ans" in
            y|Y|j|J) bash "$VDI_SCRIPT" || warn "VDI client installation reported an issue." ;;
            *)       log "VDI clients skipped. Run later: sudo bash $VDI_SCRIPT" ;;
        esac
    else
        log "VDI client installer available: sudo bash $VDI_SCRIPT"
    fi
}

# ══════════════════════════════════════════════════════════════════════════
# FINISH — GRUB + Agent im installierten System einrichten
# ══════════════════════════════════════════════════════════════════════════
# (Kein prepare-Step: Layout entsteht ausschliesslich im UI 'Basis HD
# erstellen', der netinst-d-i nutzt es direkt — kein Calamares-Zwischen-
# schritt noetig wie bei der Live-ISO-Variante.)

do_finish() {
  
# --- SUDO BOOTSTRAP BLOCK ---
    # Fängt Aufrufe über "su root" ab, richtet sudo ein und startet das Skript via "sudo" neu.
    if [ "$EUID" -eq 0 ] && [ -z "${SUDO_USER:-}" ]; then
        local orig_user
        orig_user=$(logname 2>/dev/null || true)
        
        if [ -n "$orig_user" ] && [ "$orig_user" != "root" ]; then
            log "Aufruf über 'su' erkannt. Richte sudo für '$orig_user' ein..."
            
            # Sudo sicherstellen (auf minimalen Installationen oft nicht vorhanden)
            command -v sudo >/dev/null 2>&1 || { apt-get update -qq && apt-get install -y -qq sudo; }
            
            # User in die Sudo-Gruppe aufnehmen
            usermod -aG sudo "$orig_user" 2>/dev/null || true
            
            # Temporär NOPASSWD vergeben, damit der Neustart ohne TTY/Passwort-Prompt sofort durchläuft
            echo "$orig_user ALL=(ALL:ALL) NOPASSWD: ALL" > "/etc/sudoers.d/thinforge-bootstrap"
            chmod 0440 "/etc/sudoers.d/thinforge-bootstrap"
            
            log "Stelle Umgebungsvariablen für die grafische Oberfläche wieder her..."
            local envpid
            envpid=$(pgrep -u "$orig_user" -x xfce4-session 2>/dev/null | head -1)
            [ -z "$envpid" ] && envpid=$(pgrep -u "$orig_user" -x xfdesktop 2>/dev/null | head -1)
            [ -z "$envpid" ] && envpid=$(pgrep -u "$orig_user" systemd 2>/dev/null | head -1)
            
            if [ -n "$envpid" ] && [ -r "/proc/$envpid/environ" ]; then
                export DISPLAY=$(tr '\0' '\n' < "/proc/$envpid/environ" 2>/dev/null | sed -n 's/^DISPLAY=//p' | head -1)
                export XAUTHORITY=$(tr '\0' '\n' < "/proc/$envpid/environ" 2>/dev/null | sed -n 's/^XAUTHORITY=//p' | head -1)
            fi
            
            # Fallbacks, falls der Grep fehlschlägt
            [ -z "$DISPLAY" ] && export DISPLAY=":0"
            [ -z "$XAUTHORITY" ] && export XAUTHORITY="/home/$orig_user/.Xauthority"
            
            log "Starte Skript als '$orig_user' über 'sudo' neu..."
            
            # Neustart via sudo (passiert dank NOPASSWD nun unsichtbar und ohne TTY-Error)
            exec su -s /bin/bash "$orig_user" -c "sudo -E bash \"$0\" finish ${THINFORGE_SERVER:+--server=\"$THINFORGE_SERVER\"}"
        fi
    fi
    
    # Temporäre Bootstrap-Rechte sofort nach erfolgreichem Neustart wieder aufräumen!
    # (Dieser Code wird erst erreicht, wenn das Skript erfolgreich über sudo neu gestartet wurde)
    [ -f /etc/sudoers.d/thinforge-bootstrap ] && rm -f /etc/sudoers.d/thinforge-bootstrap
    # --- ENDE SUDO BOOTSTRAP BLOCK ---
  
  
    local THINFORGE_SERVER="${1:-}"

    log "ThinForge configuration in the installed system..."

    local SCRIPT_DIR_FINISH
    SCRIPT_DIR_FINISH="$(cd "$(dirname "$0")" && pwd)"

    # Pruefen ob wir im installierten System sind (nicht Live-ISO)
    if [ -d /run/live/medium ] || [ -d /run/live/rootfs ]; then
        fatal "You are still on the Live-ISO!\nPlease boot into the installed system and run from there."
    fi

    # Ganz zu Beginn: lokale User per Checkbox fuer sudo-Rechte auswaehlen,
    # dann nicht mehr benoetigte vorinstallierte Apps entfernen.
    configure_sudo_users
    run_debian_cleanup

    # Pruefen ob btrfs mit @root
    local root_source
    root_source=$(findmnt -n -o SOURCE / 2>/dev/null || echo "")
    if echo "$root_source" | grep -q "@root"; then
        log "Root subvolume: @root detected"
    elif echo "$root_source" | grep -q "@"; then
        warn "Root subvolume is '@' instead of '@root' — minimal prepare was not executed."
        warn "Delta updates still work if the subvolume is named consistently."
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

    # 41_snapshots-btrfs benutzt `\s` in awk-Regex, was nur gawk/Perl-Style
    # versteht. Debian-Default ist mawk — `\s` matcht nichts → Detection
    # liefert "UUID of the root subvolume is not available", keine
    # Rollback-Boot-Einträge in /boot/grub/grub-btrfs.cfg.
    # Wir patchen das Skript inline (\s → [[:space:]]), kein zusaetzliches
    # apt-Paket noetig — funktioniert auch im LAN-only-Setup ohne Internet.
    local snap_script="/etc/grub.d/41_snapshots-btrfs"
    if [ -f "$snap_script" ] && grep -q '\\s' "$snap_script"; then
        sed -i 's|\\s|[[:space:]]|g' "$snap_script"
        log "41_snapshots-btrfs patched (mawk-compatible whitespace-regex)"
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
        log "All required packages already present."
    fi

    # NetBird-Agent installieren — Tools-ISO-Live-System hat Internet,
    # daher offizielles Install-Skript. Idempotent.
    if ! command -v netbird >/dev/null 2>&1; then
        log "Installing NetBird agent (official install script)..."
        curl -fsSL https://pkgs.netbird.io/install.sh | sh \
            || warn "NetBird installation failed — please check manually"
    fi

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

    local INSTALL_SCRIPT
    INSTALL_SCRIPT="$(find_tools_iso_script advanced/1-create-client-management.sh)"

    if [ -n "$INSTALL_SCRIPT" ] && [ -f "$INSTALL_SCRIPT" ]; then
        log "Agent script found: $INSTALL_SCRIPT"
        if [ -n "$THINFORGE_SERVER" ]; then
            export THINFORGE_SERVER
        fi
        bash "$INSTALL_SCRIPT"
    else
        # Curl-Bootstrap-Modus wurde aus Sicherheitsgruenden entfernt
        # (siehe docs/security/security-audit-2026-04-18.md F-CR-01). Tools-ISO ist
        # die einzige Provisioning-Quelle.
        fatal "Agent script (advanced/1-create-client-management.sh) not found.\nNeither next to this script nor on a volume with label 'THINFORGE_TOOLS'.\nMount the Tools-ISO (mount /dev/sr1 /mnt) and run the script again."
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
    # --force-confdef/--force-confold: bei geaenderten conffiles ohne Rueckfrage
    # die installierte Version behalten (kein dpkg-Prompt, der ohne TTY haengt).
    apt-get dist-upgrade -y -qq \
        -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold \
        2>/dev/null || warn "System update failed"
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
    # (find_tools_iso_script mountet die Tools-ISO bei Bedarf read-only.)
    # `|| true`: find_tools_iso_script liefert 1 wenn nichts gefunden — ohne
    # Guard wuerde die Zuweisung unter `set -e` do_finish abbrechen (das waere
    # nicht "nicht-fatal" wie unten versprochen).
    local BRANDING_SCRIPT
    BRANDING_SCRIPT="$(find_tools_iso_script DistroTweaks/install-branding-debian-minimal.sh || true)"
    if [ -n "$BRANDING_SCRIPT" ] && [ -f "$BRANDING_SCRIPT" ]; then
        log "Applying ThinForge branding (wallpaper + boot splash)..."
        if bash "$BRANDING_SCRIPT"; then
            # Der vom Branding installierte Autostart-Helper setzt das
            # Wallpaper erst beim NAECHSTEN Login. xfconf wirkt nur in der
            # Session des angemeldeten Users (nicht als root) — daher den
            # Helper jetzt einmal in allen laufenden Desktop-Sessions starten.
            apply_wallpaper_to_active_sessions
        else
            warn "Branding failed — skipped."
        fi
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
    echo -e "  3. In the ThinForge UI: 'Save update' → version v1.0"
    echo -e "  4. Deploy clone to clients"
    echo ""

    # Am Ende: optionale VDI-Client-Installation anbieten.
    offer_vdi_install
}

# ══════════════════════════════════════════════════════════════════════════
# HAUPTPROGRAMM
# ══════════════════════════════════════════════════════════════════════════

ACTION="${1:-}"
shift 2>/dev/null || true

case "$ACTION" in
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
        echo "ThinForge Debian minimal installation (debian-13.4.0-amd64-netinst)"
        echo ""
        echo "Usage:"
        echo "  install-debian-minimal.sh finish [--server=URL]  Set up GRUB + agent (after d-i)"
        echo ""
        echo "Workflow (debian-13.4.0-amd64-netinst.iso):"
        echo "  0. Click 'Create base HD' in the ThinForge UI (cloning VM card)"
        echo "  1. Boot VM with netinst-ISO, normal d-i"
        echo "  2. Manual partitioning, partition 2 with mount option subvol=@root"
        echo "  3. Tasksel: only 'standard system utilities' (minimal)"
        echo "  4. Boot into the new system"
        echo "  5. Finish:             sudo bash install-debian-minimal.sh finish"
        ;;
    *)
        fatal "Unknown action: $ACTION\nUse 'finish'"
        ;;
esac
#
