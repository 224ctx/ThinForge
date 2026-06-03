#!/bin/bash
#
# ThinForge Client-Migration
#
# Wird vom Agent heruntergeladen und ausgefuehrt wenn sich der
# SHA256-Hash aendert. Installiert neue Dienste, entfernt veraltete,
# und aktualisiert die Client-Konfiguration.
#
# Jeder Migrationsschritt ist idempotent — kann gefahrlos mehrfach
# ausgefuehrt werden.
#
# Version: 2026-05-17
#

set -euo pipefail

LOG_TAG="agent-migrate"
log() { echo "$*" | systemd-cat -t "$LOG_TAG" -p info 2>/dev/null; echo "[migrate] $*"; }
warn() { echo "$*" | systemd-cat -t "$LOG_TAG" -p warning 2>/dev/null; echo "[migrate] WARN: $*"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ══════════════════════════════════════════════════════════════════════════
# Migration: agent-home-mount-generator entfernen (Single-Root-Layout)
# ══════════════════════════════════════════════════════════════════════════
# Vor dem Single-Root-Layout-Switch (2026-04-29) installierte agent-migrate
# einen systemd-Generator der beim Rollback-Boot @snap_*_home als /home
# mountete. Wir snapshotten /home jetzt als Verzeichnis innerhalb des
# Root-Subvolumes — der Generator ist nicht nur unnoetig sondern bricht
# Rollback-Boots, weil er auf nicht-existierende _home-Snapshots zielt.
# Idempotente Loeschung der lokal installierten Datei.

for stale in \
    /etc/systemd/system-generators/agent-home-mount-generator \
    /etc/systemd/system-generators/thinforge-home-mount-generator \
    /data/thinforge/agent-home-mount-generator; do
    if [ -e "$stale" ]; then
        rm -f "$stale"
        log "Veralteter Home-Mount-Generator entfernt: $stale"
    fi
done

# ══════════════════════════════════════════════════════════════════════════
# Migration: thinforge-grub-update Service entfernen
# ══════════════════════════════════════════════════════════════════════════
# Nicht mehr noetig — grub-mkconfig laeuft in agent-apply-delta.sh beim Shutdown.

if systemctl is-enabled thinforge-grub-update.service &>/dev/null; then
    systemctl disable thinforge-grub-update.service 2>/dev/null || true
    systemctl stop thinforge-grub-update.service 2>/dev/null || true
    log "thinforge-grub-update.service deaktiviert"
fi

if [ -f /etc/systemd/system/thinforge-grub-update.service ]; then
    rm -f /etc/systemd/system/thinforge-grub-update.service
    systemctl daemon-reload 2>/dev/null || true
    log "thinforge-grub-update.service entfernt"
fi

rm -f /data/thinforge/thinforge-grub-update.sh 2>/dev/null
rm -f /opt/thinforge/thinforge-grub-update.sh 2>/dev/null

# ══════════════════════════════════════════════════════════════════════════
# Migration: grub-btrfs Ignore-Liste auf Single-Root-Layout normieren
# ══════════════════════════════════════════════════════════════════════════
# Idempotent: setzt die Ignore-Liste auf den Single-Root-Stand. Aktuelle
# @snap_*-Eintraege werden zur Laufzeit von agent-apply-delta.sh ergaenzt
# (nur der vorherige Snapshot bleibt sichtbar = Rollback). Diese Migration
# kuemmert sich nur um die statischen Layout-Namen.

GRUB_BTRFS_CONF="/etc/default/grub-btrfs/config"
TARGET_IGNORE='GRUB_BTRFS_IGNORE_SPECIFIC_PATH=("@" "@root" "@rootfs" "@data" "@root_old" "@rootfs_old" "@_old")'
if [ -f "$GRUB_BTRFS_CONF" ]; then
    current=$(grep '^GRUB_BTRFS_IGNORE_SPECIFIC_PATH=' "$GRUB_BTRFS_CONF" || true)
    if [ "$current" != "$TARGET_IGNORE" ]; then
        sed -i "s|^GRUB_BTRFS_IGNORE_SPECIFIC_PATH=.*|$TARGET_IGNORE|" "$GRUB_BTRFS_CONF"
        log "grub-btrfs Ignore-Liste auf Single-Root-Layout normiert"
    fi
fi

# ══════════════════════════════════════════════════════════════════════════
# Migration: grub-btrfsd sicherheitshalber deaktivieren
# ══════════════════════════════════════════════════════════════════════════

if systemctl is-enabled grub-btrfsd.service &>/dev/null; then
    systemctl disable grub-btrfsd.service 2>/dev/null || true
    systemctl stop grub-btrfsd.service 2>/dev/null || true
    log "grub-btrfsd deaktiviert"
fi

# ══════════════════════════════════════════════════════════════════════════
# Migration: 41_snapshots-btrfs für mawk patchen
# ══════════════════════════════════════════════════════════════════════════
# Das Antynea-grub-btrfs-Skript benutzt `\s` in awk-Patterns, was nur
# gawk/Perl-Style versteht. Debian-Default ist mawk → `\s` matcht nichts →
# "UUID of the root subvolume is not available" → keine Rollback-Boot-
# Einträge im GRUB. Inline-Patch auf POSIX-Klasse [[:space:]], die mawk
# auch versteht. Idempotent: grep prüft, ob noch ungepatchte `\s` drin sind.

SNAP_SCRIPT="/etc/grub.d/41_snapshots-btrfs"
if [ -f "$SNAP_SCRIPT" ] && grep -q '\\s' "$SNAP_SCRIPT"; then
    sed -i 's|\\s|[[:space:]]|g' "$SNAP_SCRIPT"
    log "41_snapshots-btrfs gepatcht (mawk-kompatibles whitespace-regex)"
fi

# ══════════════════════════════════════════════════════════════════════════
# Migration: NSSwitch mDNS-Block reparieren
# ══════════════════════════════════════════════════════════════════════════
# mdns_minimal [NOTFOUND=return] in /etc/nsswitch.conf verhindert dass
# DNS-Lookups den konfigurierten Nameserver erreichen — Go, curl und
# andere Programme die ueber libc aufloesen brechen bei NOTFOUND ab
# bevor der DNS-Server gefragt wird. Fix: dns VOR mdns_minimal setzen.

NSSWITCH="/etc/nsswitch.conf"
if [ -f "$NSSWITCH" ] && grep -q 'mdns_minimal.*\[NOTFOUND=return\].*dns' "$NSSWITCH"; then
    # Move dns before mdns_minimal so the configured nameserver is queried first
    sed -i '/^hosts:/ s/mdns_minimal \[NOTFOUND=return\] //' "$NSSWITCH"
    sed -i '/^hosts:/ s/dns/mdns_minimal dns/' "$NSSWITCH"
    log "NSSwitch repariert: dns vor mdns_minimal gesetzt"
fi

# ══════════════════════════════════════════════════════════════════════════
# Migration: agent-apply-update.service ExecStop auf Agent-Binary umschalten
# ══════════════════════════════════════════════════════════════════════════
# Ab Agent v2.13.0 ruft die systemd-Unit das Binary direkt auf
# (ExecStop=/data/thinforge/thinforge-agent apply-update). Frueher zeigte
# ExecStop auf den Shim /data/thinforge/agent-apply-update.sh, der das
# Binary delegiert hat — ein ueberfluessiger fork/exec-Hop. Diese Migration
# ueberschreibt die Unit idempotent + reload + cleanup der toten Shim-
# Datei + agent-notify-reboot.sh-Shim (delta/notify.go ruft notify.Reboot
# in-process auf, der Shim wird auch nicht mehr gebraucht).

NEW_APPLY_EXECSTOP="/data/thinforge/thinforge-agent apply-update"
APPLY_UNIT="/etc/systemd/system/agent-apply-update.service"

if [ -f "$APPLY_UNIT" ] && ! grep -qF "ExecStop=${NEW_APPLY_EXECSTOP}" "$APPLY_UNIT"; then
    cat > "$APPLY_UNIT" <<'APPLYSERVICE'
[Unit]
Description=ThinForge Apply Delta Update on Shutdown
After=local-fs.target data.mount
Requires=data.mount

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true
ExecStop=/data/thinforge/thinforge-agent apply-update
TimeoutStopSec=600

[Install]
WantedBy=multi-user.target
APPLYSERVICE
    systemctl daemon-reload
    systemctl enable agent-apply-update.service 2>/dev/null || true
    log "agent-apply-update.service ExecStop direkt auf Agent-Binary umgeschaltet"
fi

# ══════════════════════════════════════════════════════════════════════════
# Migration: thinforge-agent.service Drift-Repair
# ══════════════════════════════════════════════════════════════════════════
# Aelter installierte Clients koennen eine veraltete Unit-Definition tragen
# (z.B. ExecStart=/opt/thinforge/thinforge-agent oder ohne Requires=data.mount).
# Diese Migration vergleicht die installierte Unit mit dem kanonischen Stand
# aus 1-create-client-management.sh und schreibt sie bei Drift neu.
#
# Kein systemctl restart: der Agent fuehrt diese Migration selbst aus
# (recursive bootstrap waere fatal). Stattdessen nur daemon-reload — die
# neue Definition greift beim naechsten natuerlichen Restart (Reboot oder
# delta-apply).

AGENT_UNIT="/etc/systemd/system/thinforge-agent.service"
read -r -d '' AGENT_UNIT_CANONICAL <<'AGENTUNIT' || true
[Unit]
Description=ThinForge Agent (Heartbeat + Updates)
After=network-online.target data.mount
Wants=network-online.target
Requires=data.mount

[Service]
Type=simple
ExecStart=/data/thinforge/thinforge-agent
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
AGENTUNIT

if [ -f "$AGENT_UNIT" ]; then
    current_unit=$(cat "$AGENT_UNIT")
    if [ "$current_unit" != "$AGENT_UNIT_CANONICAL" ]; then
        printf '%s\n' "$AGENT_UNIT_CANONICAL" > "$AGENT_UNIT"
        systemctl daemon-reload 2>/dev/null || true
        log "thinforge-agent.service Drift repariert (greift beim naechsten Restart)"
    fi
fi

# ══════════════════════════════════════════════════════════════════════════
# Migration: /var/cache/thinforge Stale-Delta-Cleanup
# ══════════════════════════════════════════════════════════════════════════
# Fehlgeschlagene oder abgebrochene Delta-Downloads hinterlassen delta_*.zst
# und delta_*.json im Cache. Aelter als 14 Tage ist ein klares Signal dass
# der Update-Zyklus weitergelaufen ist und das Artefakt nie konsumiert wurde.
#
# Explizit NICHT geloescht: pending-delta und pending-rollback Marker —
# das sind Steuerdateien fuer agent-apply-delta, kein Cache-Muell.

if [ -d /var/cache/thinforge ]; then
    while IFS= read -r stale_artifact; do
        rm -f "$stale_artifact"
        log "Stale Delta-Cache-Datei entfernt: $stale_artifact"
    done < <(find /var/cache/thinforge -maxdepth 1 -type f -mtime +14 \
        \( -name 'delta_*.zst' -o -name 'delta_*.json' -o -name 'delta_*_home.zst' \) \
        2>/dev/null || true)
fi

# Tote Shim-Dateien aufraeumen (kein Caller mehr).
# Operators die `agent-apply-delta.sh --status` aus Muscle-Memory tippen
# muessen ab Agent v2.13.1 auf `thinforge-agent apply-delta --status`
# umsteigen — same logic, ein Hop weniger.
for stale in \
    /data/thinforge/agent-apply-update.sh \
    /data/thinforge/agent-apply-delta.sh \
    /data/thinforge/agent-notify-reboot.sh \
    /data/thinforge/agent-notify-vpn-overlap.sh \
    /opt/thinforge/agent-notify-reboot.sh \
    /opt/thinforge/agent-notify-vpn-overlap.sh; do
    if [ -f "$stale" ]; then
        rm -f "$stale"
        log "Veralteter Shim entfernt: $stale"
    fi
done

log "Migration abgeschlossen"
