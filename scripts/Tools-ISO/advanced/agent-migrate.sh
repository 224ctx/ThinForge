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
# Version: 2026-10-22
#
# Aufbau: jeder Schritt ist eine Funktion, main() ruft sie der Reihe nach.
# Der Skripttest tests/agent-migrate-unit-gate.sh lenkt ETC, JOURNAL_DIR,
# SYSTEMCTL und JOURNALCTL um und ruft die Unit- und Journal-Funktionen
# direkt (er `source`t die Datei; main laeuft nur beim Aufruf als Skript).
#

set -euo pipefail

LOG_TAG="agent-migrate"
log() { echo "$*" | systemd-cat -t "$LOG_TAG" -p info 2>/dev/null; echo "[migrate] $*"; }
warn() { echo "$*" | systemd-cat -t "$LOG_TAG" -p warning 2>/dev/null; echo "[migrate] WARN: $*"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Naehte fuer den Skripttest (im Betrieb unveraendert).
ETC=""                              # Praefix vor /etc und /var
JOURNAL_DIR="/data/log/journal"     # das dauerhafte Journal-Verzeichnis
SYSTEMCTL="systemctl"
JOURNALCTL="journalctl"

# Versionstor (Spec §5.1): die gehaertete Unit (Type=notify, Watchdog,
# OnFailure) bekommt nur ein Agent ab v2.28.0 — er setzt
# THINFORGE_AGENT_VERSION in die Umgebung dieses Skripts
# (scripts.RunMigrationIfNeeded). Ein Agent bis v2.27.0 setzt die Variable
# nicht, schickt nie READY=1 und wuerde unter der neuen Unit nach
# TimeoutStartSec beendet; er bekommt die bisherige Unit — in beide
# Richtungen, damit auch ein Rollback der Flotte unter v2.28.0 den Agenten
# nicht unter einer Notify-Unit stehen laesst. Vergleich rein ueber sort -V
# (`dev` eines unmarkierten Baus zaehlt als alt).
AGENT_VERSION="${THINFORGE_AGENT_VERSION:-}"
UNIT_HARDENED_FROM="v2.28.0"

unit_hardened_for_version() {
    local v="$1"
    [ -n "$v" ] || return 1
    [ "$(printf '%s\n' "$UNIT_HARDENED_FROM" "$v" | sort -V | head -n1)" = "$UNIT_HARDENED_FROM" ]
}

migrate_legacy_units_and_tweaks() {
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
    # bevor der DNS-Server gefragt wird. Fix: die Aktion [NOTFOUND=return]
    # hinter dem mDNS-Modul streichen, dann geht die Suche weiter zu dns.
    #
    # Beide Schreibweisen des Moduls: Debian (libnss-mdns) schreibt
    # mdns4_minimal, Arch/Manjaro mdns_minimal (mdns6_minimal gibt es auch),
    # Leerraum dazwischen beliebig. Bis 2026-09-15 kannte die Pruefung nur
    # `mdns_minimal` mit genau einem Leerzeichen: auf Debian lief die Reparatur
    # still ins Leere, und bei Tab oder doppeltem Leerzeichen machte das zweite,
    # nicht verankerte sed aus `mdns_minimal` zwei unbekannte Module
    # (`mmdns_minimal dns_minimal`). Die Nachpruefung meldet, wenn es nicht
    # gegriffen hat.

    NSSWITCH="/etc/nsswitch.conf"
    MDNS_NOTFOUND='^hosts:.*mdns[46]?_minimal[[:space:]]+\[NOTFOUND=return\]'
    if [ -f "$NSSWITCH" ] && grep -qE "$MDNS_NOTFOUND" "$NSSWITCH"; then
        sed -i -E '/^hosts:/ s/(mdns[46]?_minimal)[[:space:]]+\[NOTFOUND=return\]/\1/g' "$NSSWITCH"
        if grep -qE "$MDNS_NOTFOUND" "$NSSWITCH"; then
            warn "NSSwitch: [NOTFOUND=return] hinter mdns_minimal nicht entfernt: $(grep '^hosts:' "$NSSWITCH")"
        else
            log "NSSwitch repariert: [NOTFOUND=return] hinter mdns_minimal entfernt, dns wird danach gefragt"
        fi
    fi
}

# ══════════════════════════════════════════════════════════════════════════
# Migration: agent-apply-update.service Drift-Repair
# ══════════════════════════════════════════════════════════════════════════
# Kanonisch ist scripts/Tools-ISO/advanced/agent-apply-update.service; der
# Installer (1-create-client-management.sh, Schritt 6c) schreibt genau diese
# Datei von der Tools-ISO. Dieses Skript wird einzeln ausgeliefert
# (GET /klon/agent-migrate.sh) und traegt deshalb eine Kopie — dass sie der
# Datei Byte fuer Byte gleicht, prueft cloningvm_service::tools_iso_unit_tests.
#
# Bis 2026-10-01 schrieb dieser Schritt die Unit nur neu, wenn ExecStop noch
# auf den Shim agent-apply-update.sh zeigte (vor Agent v2.13.0). Eine Unit
# mit richtigem ExecStop, aber ohne `After=data.mount`/`Requires=data.mount`
# — so stand sie bis dahin in der Repo-Datei — blieb stehen. Jetzt wie beim
# thinforge-agent.service unten: Inhalt vergleichen, bei Abweichung neu
# schreiben. Ein daemon-reload genuegt: die neue Ordnung gilt sofort fuer
# das naechste Herunterfahren, die Unit laeuft ohnehin nur ExecStart=/bin/true.

APPLY_UNIT="/etc/systemd/system/agent-apply-update.service"
read -r -d '' APPLY_UNIT_CANONICAL <<'APPLYSERVICE' || true
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

migrate_apply_unit() {
    local unit="$ETC$APPLY_UNIT"
    [ -f "$unit" ] || return 0
    local current_apply_unit
    current_apply_unit=$(cat "$unit")
    if [ "$current_apply_unit" != "$APPLY_UNIT_CANONICAL" ]; then
        printf '%s\n' "$APPLY_UNIT_CANONICAL" > "$unit"
        "$SYSTEMCTL" daemon-reload 2>/dev/null || true
        "$SYSTEMCTL" enable agent-apply-update.service 2>/dev/null || true
        log "agent-apply-update.service Drift repariert (kanonische Fassung mit data.mount)"
        # Ereigniszeile fuer den Agenten (Agent-Erkennungspaket): stdout liest
        # scripts.RunMigrationIfNeeded, daraus wird unit_drift_repaired {unit}.
        echo "@@tf-event unit_drift_repaired unit=${APPLY_UNIT##*/}"
    fi
}

# ══════════════════════════════════════════════════════════════════════════
# Migration: thinforge-agent.service Drift-Repair mit Versionstor
# ══════════════════════════════════════════════════════════════════════════
# Aelter installierte Clients koennen eine veraltete Unit-Definition tragen
# (z.B. ExecStart=/opt/thinforge/thinforge-agent oder ohne Requires=data.mount).
# Diese Migration vergleicht die installierte Unit mit dem kanonischen Stand
# aus 1-create-client-management.sh und schreibt sie bei Drift neu.
#
# Seit Haertungspaket 2 (2026-10-22, V6/V7) gibt es zwei kanonische
# Fassungen: AGENTUNIT (bis v2.27.0, Type=simple) und AGENTUNIT_V2 (ab
# v2.28.0: Type=notify, Watchdog, Capability-Grenzen,
# OnFailure=thinforge-agent-recover.service). Welche gilt, entscheidet
# unit_hardened_for_version mit THINFORGE_AGENT_VERSION. Die Recover-Unit
# (RECOVERUNIT) kommt nur mit der neuen Fassung und geht mit ihr wieder.
# Alle drei Texte stehen byte-gleich in agent-go/*.service und im
# Installer; cloningvm_service::tools_iso_unit_tests prueft das.
#
# Kein systemctl restart: der Agent fuehrt diese Migration selbst aus
# (recursive bootstrap waere fatal). Stattdessen nur daemon-reload — die
# neue Definition greift beim naechsten natuerlichen Restart (Reboot oder
# delta-apply).

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

read -r -d '' AGENT_UNIT_V2_CANONICAL <<'AGENTUNIT_V2' || true
[Unit]
Description=ThinForge Agent (Heartbeat + Updates)
After=network-online.target data.mount
Wants=network-online.target
Requires=data.mount
StartLimitBurst=5
StartLimitIntervalSec=300
OnFailure=thinforge-agent-recover.service

[Service]
Type=notify
NotifyAccess=main
ExecStart=/data/thinforge/thinforge-agent
Restart=always
RestartSec=10
WatchdogSec=120
TimeoutStartSec=300
CapabilityBoundingSet=CAP_SYS_ADMIN CAP_DAC_OVERRIDE CAP_DAC_READ_SEARCH CAP_CHOWN CAP_FOWNER CAP_FSETID CAP_SETUID CAP_SETGID CAP_SETFCAP CAP_MKNOD CAP_AUDIT_WRITE CAP_SYS_CHROOT CAP_KILL CAP_SYS_PTRACE
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictRealtime=yes
LockPersonality=yes
SystemCallArchitectures=native
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6 AF_NETLINK
TasksMax=512
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
AGENTUNIT_V2

read -r -d '' RECOVER_UNIT_CANONICAL <<'RECOVERUNIT' || true
[Unit]
Description=ThinForge Agent Recovery (restores the signed previous binary, else retries in 5 min)
After=data.mount
Requires=data.mount

[Service]
Type=oneshot
TimeoutStartSec=400
ExecStart=/bin/bash -c ' \
    set -u; D=/data/thinforge; B=$$D/thinforge-agent; P=$$B.prev; A=thinforge-agent.service; \
    retry() { echo "agent-recover: retrying $$A in 5 min"; sleep 300; \
        if systemctl is-failed --quiet $$A; then systemctl reset-failed $$A; systemctl start --no-block $$A; echo "agent-recover: $$A started again"; \
        else echo "agent-recover: $$A is no longer failed - no retry"; fi; exit 0; }; \
    K=$$(grep -v "^untrusted comment:" "$$D/signing.pub" | grep -m1 . | tr -d "[:space:]"); \
    if [ ! -s "$$P" ] || [ ! -s "$$P.minisig" ] || [ -z "$$K" ]; then \
        echo "agent-recover: no signed previous binary - nothing to restore"; retry; fi; \
    if ! minisign -V -q -P "$$K" -m "$$P" -x "$$P.minisig"; then \
        echo "agent-recover: previous binary fails its signature check - not restored"; retry; fi; \
    F=$$(sha256sum "$$B" | cut -c1-8); \
    V=$$("$$P" version 2>/dev/null || grep -a -o -E "config[.]AgentVersion=v[0-9][0-9A-Za-z.-]*" "$$P" | head -1 | cut -d= -f2); \
    mv -f "$$B" "$$B.failed"; mv -f "$$P" "$$B"; mv -f "$$P.minisig" "$$B.minisig"; \
    { echo "restored=$$V"; echo "failed=$$F"; } > "$$D/agent-recovered"; \
    echo "agent-recover: restored agent $$V, failed binary $$F kept as thinforge-agent.failed"; \
    systemctl reset-failed $$A; systemctl start --no-block $$A'
RECOVERUNIT

migrate_agent_unit() {
    local unit="$ETC/etc/systemd/system/thinforge-agent.service"
    local recover="$ETC/etc/systemd/system/thinforge-agent-recover.service"
    local wanted fassung reload=0
    if unit_hardened_for_version "$AGENT_VERSION"; then
        wanted="$AGENT_UNIT_V2_CANONICAL"; fassung="gehaertete Fassung ab $UNIT_HARDENED_FROM"
    else
        wanted="$AGENT_UNIT_CANONICAL"; fassung="bisherige Fassung (Agent ${AGENT_VERSION:-vor v2.28.0})"
    fi

    # Nur ein verwaltetes Geraet (Unit vorhanden) wird repariert.
    [ -f "$unit" ] || return 0

    local current_unit
    current_unit=$(cat "$unit")
    if [ "$current_unit" != "$wanted" ]; then
        printf '%s\n' "$wanted" > "$unit"
        reload=1
        log "thinforge-agent.service Drift repariert: $fassung (greift beim naechsten Restart)"
        # Ereigniszeile fuer den Agenten (Agent-Erkennungspaket): stdout liest
        # scripts.RunMigrationIfNeeded, daraus wird unit_drift_repaired {unit}.
        echo "@@tf-event unit_drift_repaired unit=${unit##*/}"
    fi

    if unit_hardened_for_version "$AGENT_VERSION"; then
        if [ ! -f "$recover" ]; then
            printf '%s\n' "$RECOVER_UNIT_CANONICAL" > "$recover"
            reload=1
            log "thinforge-agent-recover.service angelegt (Rueckfall auf die vorige Binary nach Fehlstarts)"
        elif [ "$(cat "$recover")" != "$RECOVER_UNIT_CANONICAL" ]; then
            printf '%s\n' "$RECOVER_UNIT_CANONICAL" > "$recover"
            reload=1
            log "thinforge-agent-recover.service Drift repariert"
            echo "@@tf-event unit_drift_repaired unit=${recover##*/}"
        fi
    elif [ -f "$recover" ]; then
        rm -f "$recover"
        reload=1
        log "thinforge-agent-recover.service entfernt (Agent vor $UNIT_HARDENED_FROM)"
    fi

    if [ "$reload" = 1 ]; then
        "$SYSTEMCTL" daemon-reload 2>/dev/null || true
    fi
}

# ══════════════════════════════════════════════════════════════════════════
# Migration: Journal dauerhaft auf /data (Haertungspaket 2, V15)
# ══════════════════════════════════════════════════════════════════════════
# Ein Subvolume-Tausch (Delta-Update) ersetzt @rootfs samt /var/log/journal:
# das Journal des alten Stands ist weg, und mit ihm die Spur eines
# Eingriffs. Deshalb liegt das Journal unter /data/log/journal (0755, root),
# /var/log/journal ist ein Symlink dorthin, und ein Drop-in erzwingt
# Storage=persistent (200 MB Deckel). Ein vorhandenes echtes Verzeichnis
# wird verschoben (Inhalt bleibt), nicht geloescht. Danach journalctl
# --rotate (journald schreibt ab sofort am neuen Ort) und --flush (das
# Laufzeit-Journal des Bootvorgangs kommt nach) — kein Neustart von
# journald. Idempotent: ohne Abweichung passiert nichts.

JOURNAL_LINK_TARGET="/data/log/journal"
read -r -d '' JOURNALD_DROPIN_CANONICAL <<'JOURNALD' || true
[Journal]
Storage=persistent
SystemMaxUse=200M
JOURNALD

migrate_journal() {
    local link="$ETC/var/log/journal"
    local dropin_dir="$ETC/etc/systemd/journald.conf.d"
    local dropin="$dropin_dir/thinforge.conf"
    local changed=0 moved=""

    mkdir -p "$JOURNAL_DIR"

    if [ -L "$link" ]; then
        if [ "$(readlink "$link")" != "$JOURNAL_LINK_TARGET" ]; then
            rm -f "$link"
            ln -s "$JOURNAL_LINK_TARGET" "$link"
            changed=1
            log "Journal: /var/log/journal zeigt jetzt auf $JOURNAL_LINK_TARGET (Symlink korrigiert)"
        fi
    elif [ -d "$link" ]; then
        moved="$link.migrated"
        rm -rf "$moved"
        cp -a "$link/." "$JOURNAL_DIR/"
        mv "$link" "$moved"
        ln -s "$JOURNAL_LINK_TARGET" "$link"
        changed=1
        log "Journal: /var/log/journal nach $JOURNAL_LINK_TARGET verschoben, Symlink gesetzt"
    else
        mkdir -p "$(dirname "$link")"
        rm -f "$link"
        ln -s "$JOURNAL_LINK_TARGET" "$link"
        changed=1
        log "Journal: /var/log/journal als Symlink auf $JOURNAL_LINK_TARGET angelegt"
    fi

    # root, nicht gruppen- oder weltbeschreibbar. journald selbst setzt das
    # Verzeichnis auf 2755 root:systemd-journal (setgid fuer die Lesegruppe)
    # — das gilt; nur ein anderer Modus (etwa aus cp -a einer fremden Quelle)
    # wird auf 0755 gebracht.
    case "$(stat -c %a "$JOURNAL_DIR")" in
        755|2755) ;;
        *) chmod 0755 "$JOURNAL_DIR"; changed=1 ;;
    esac

    if [ ! -f "$dropin" ] || [ "$(cat "$dropin")" != "$JOURNALD_DROPIN_CANONICAL" ]; then
        mkdir -p "$dropin_dir"
        printf '%s\n' "$JOURNALD_DROPIN_CANONICAL" > "$dropin"
        changed=1
        log "Journal: Drop-in $dropin geschrieben (Storage=persistent, SystemMaxUse=200M)"
    fi

    if [ "$changed" = 1 ]; then
        "$JOURNALCTL" --rotate 2>/dev/null || warn "journalctl --rotate fehlgeschlagen"
        "$JOURNALCTL" --flush 2>/dev/null || warn "journalctl --flush fehlgeschlagen"
        if [ -n "$moved" ]; then
            rm -rf "$moved"
        fi
    fi
}

migrate_cache_and_shims() {
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
}

main() {
    migrate_legacy_units_and_tweaks
    migrate_apply_unit
    migrate_agent_unit
    migrate_journal
    migrate_cache_and_shims
    log "Migration abgeschlossen"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
