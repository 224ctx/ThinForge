#!/bin/bash
#
# ThinForge — Agent-Check.sh
#
# Diagnose-Skript fuer eine VM, in der der ThinForge-Agent installiert
# wurde (via 1-create-client-management.sh). Prueft alle erwarteten
# Dateien, Pfade, Permissions und systemd-Units und gibt am Ende eine
# Zusammenfassung mit Pass/Fail-Bilanz aus.
#
# Verwendung (in der VM):
#   sudo bash /opt/thinforge/Agent-Check.sh
#   oder von der Tools-ISO:
#   sudo bash /mnt/advanced/Agent-Check.sh
#

set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0
FAIL_ITEMS=()
WARN_ITEMS=()

ok()   { echo -e "  ${GREEN}[OK]${NC}   $*"; PASS=$((PASS + 1)); }
bad()  { echo -e "  ${RED}[FAIL]${NC} $*"; FAIL=$((FAIL + 1)); FAIL_ITEMS+=("$*"); }
note() { echo -e "  ${YELLOW}[WARN]${NC} $*"; WARN=$((WARN + 1)); WARN_ITEMS+=("$*"); }
hdr()  { echo ""; echo -e "${CYAN}── $* ──${NC}"; }

# Prueft Existenz + nicht-leere Datei. $1 = Pfad, $2 = Beschreibung,
# $3 = optional erwartete Permission (z.B. "600").
check_file() {
    local path="$1" desc="$2" want_mode="${3:-}"
    if [ ! -e "$path" ]; then
        bad "$desc missing: $path"
        return
    fi
    if [ ! -s "$path" ]; then
        bad "$desc is empty: $path"
        return
    fi
    if [ -n "$want_mode" ]; then
        local mode
        mode=$(stat -c '%a' "$path" 2>/dev/null)
        if [ "$mode" != "$want_mode" ]; then
            note "$desc has mode $mode, expected $want_mode: $path"
        else
            ok "$desc present ($(stat -c '%s' "$path") Bytes, mode $mode)"
        fi
    else
        ok "$desc present ($(stat -c '%s' "$path") Bytes)"
    fi
}

echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  ThinForge Agent-Check${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"

# ── Root-Check ───────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    note "Not running as root — some checks (permission, systemctl) may fail."
fi

# ── 1. Mounts und Pfade ──────────────────────────────────────────────
hdr "Mounts & Paths"

if mountpoint -q /data; then
    src=$(findmnt -n -o SOURCE /data 2>/dev/null)
    fs=$(findmnt -n -o FSTYPE /data 2>/dev/null)
    ok "/data mounted ($src, $fs)"
else
    bad "/data is NOT mounted — Agent state would be volatile"
fi

if [ -L /opt/thinforge ]; then
    target=$(readlink -f /opt/thinforge)
    if [ "$target" = "/data/thinforge" ]; then
        ok "/opt/thinforge → /data/thinforge"
    else
        bad "/opt/thinforge points to $target (expected /data/thinforge)"
    fi
elif [ -d /opt/thinforge ]; then
    bad "/opt/thinforge is a directory instead of a symlink → symlink missing"
else
    bad "/opt/thinforge missing (symlink to /data/thinforge expected)"
fi

if [ -d /data/thinforge ]; then
    ok "/data/thinforge exists"
else
    bad "/data/thinforge missing"
fi

# ── 2. Agent-Binary + Konfiguration ──────────────────────────────────
hdr "Agent Binary & Configuration"

if [ -x /data/thinforge/thinforge-agent ]; then
    size=$(stat -c '%s' /data/thinforge/thinforge-agent)
    ok "thinforge-agent present and executable ($size Bytes)"
    # Schnelle Sanity-Check: ist das ein ELF-Binary?
    if head -c 4 /data/thinforge/thinforge-agent | grep -q $'\x7fELF'; then
        ok "thinforge-agent is an ELF binary"
    else
        bad "thinforge-agent is NOT an ELF binary (likely corrupted)"
    fi
    # Embedded Agent-Version: Go-Agent loggt beim Start
    # `version=vX.Y.Z` als strukturiertes Feld. Wir starten ihn mit
    # Timeout, parsen die Zeile, killen ihn wieder. HOME=/dev/null
    # stoppt den Agenten frueh genug bevor er Files in /data/thinforge
    # schreibt.
    agent_ver=$(timeout 2 /data/thinforge/thinforge-agent 2>&1 \
                  | grep -oE 'version=v[^ ]+' \
                  | head -1 \
                  | cut -d= -f2)
    if [ -n "$agent_ver" ]; then
        ok "Agent-Version (embedded): $agent_ver"
    else
        note "Agent version could not be read from the binary"
    fi
else
    bad "thinforge-agent missing or not executable: /data/thinforge/thinforge-agent"
fi

check_file /data/thinforge/agent.conf "agent.conf"
if [ -f /data/thinforge/agent.conf ]; then
    server_url=$(awk -F= '/^[[:space:]]*server_url/ {gsub(/[[:space:]]/, "", $2); print $2}' /data/thinforge/agent.conf)
    if [ -n "$server_url" ]; then
        ok "agent.conf: server_url = $server_url"
    else
        bad "agent.conf contains no server_url"
    fi
fi

# ── 3. Trust-Anchor (TLS) und Tokens ─────────────────────────────────
hdr "Secrets & Trust-Anchor"

check_file /data/thinforge/server.crt          "TLS certificate (trust anchor)" "644"
check_file /data/thinforge/heartbeat.token     "Heartbeat token"               "600"
check_file /data/thinforge/signing.pub         "Signing public key"            "644"

if [ -f /data/thinforge/server.crt ]; then
    if command -v openssl >/dev/null 2>&1; then
        subject=$(openssl x509 -in /data/thinforge/server.crt -noout -subject 2>/dev/null | sed 's/^subject=//')
        not_after=$(openssl x509 -in /data/thinforge/server.crt -noout -enddate 2>/dev/null | sed 's/^notAfter=//')
        if [ -n "$subject" ]; then
            ok "TLS cert subject: $subject"
            ok "TLS cert valid until: $not_after"
            # Restlaufzeit pruefen
            if openssl x509 -in /data/thinforge/server.crt -noout -checkend 604800 >/dev/null 2>&1; then
                :
            else
                note "TLS cert expires in less than 7 days"
            fi
        else
            bad "TLS cert cannot be parsed (not a valid X.509?)"
        fi
    else
        note "openssl not installed — cert contents cannot be verified"
    fi
fi

# Auch im System-CA-Store?
if [ -f /usr/local/share/ca-certificates/thinforge-server.crt ]; then
    ok "TLS cert in system CA store (Debian path)"
elif [ -f /etc/pki/ca-trust/source/anchors/thinforge-server.crt ]; then
    ok "TLS cert in system CA store (RHEL path)"
elif [ -f /etc/ca-certificates/trust-source/anchors/thinforge-server.crt ]; then
    ok "TLS cert in system CA store (Arch path)"
else
    note "TLS cert not in system CA store — other tools (curl, wget) will not trust it"
fi

# ── 4. Apply-Skripte ─────────────────────────────────────────────────
hdr "Apply Scripts"

check_file /data/thinforge/agent-apply-delta.sh       "agent-apply-delta.sh"
check_file /data/thinforge/agent-apply-update.sh      "agent-apply-update.sh"
check_file /data/thinforge/manual-manage-snapshots.sh "manual-manage-snapshots.sh"

[ -x /data/thinforge/agent-apply-delta.sh ]  || note "agent-apply-delta.sh not executable"
[ -x /data/thinforge/agent-apply-update.sh ] || note "agent-apply-update.sh not executable"

# ── 5. systemd-Units ─────────────────────────────────────────────────
hdr "systemd Units"

check_unit() {
    local unit="$1"
    if ! systemctl list-unit-files "$unit" >/dev/null 2>&1; then
        bad "$unit not installed"
        return
    fi

    local enabled active
    enabled=$(systemctl is-enabled "$unit" 2>/dev/null || echo "unknown")
    active=$(systemctl is-active  "$unit" 2>/dev/null || echo "unknown")

    case "$enabled" in
        enabled|enabled-runtime|static|alias) ok "$unit enabled ($enabled)" ;;
        *) bad "$unit not enabled (status: $enabled)" ;;
    esac

    case "$active" in
        active) ok "$unit active" ;;
        inactive)
            # apply-update ist oneshot — inactive ist normal solange kein Shutdown
            if [ "$unit" = "agent-apply-update.service" ]; then
                ok "$unit inactive (oneshot, normal)"
            else
                note "$unit inactive (not running — may be intentional on base VM)"
            fi
            ;;
        failed) bad "$unit failed — check journalctl -u $unit" ;;
        *)      note "$unit Status: $active" ;;
    esac
}

check_unit thinforge-agent.service
check_unit agent-apply-update.service

# data.mount muss existieren, damit Requires=data.mount greift
if systemctl list-units --all --type=mount 2>/dev/null | grep -q "^[[:space:]]*data\.mount"; then
    ok "data.mount von systemd erkannt"
else
    bad "data.mount missing in systemd — agent service dependency not satisfied"
fi

# ── 6. SSH (Server-Key + sshd) ───────────────────────────────────────
hdr "SSH (Provisioning Access)"

if [ -f /root/.ssh/authorized_keys ] && [ -s /root/.ssh/authorized_keys ]; then
    keys=$(grep -c '^ssh-' /root/.ssh/authorized_keys 2>/dev/null || echo 0)
    ok "/root/.ssh/authorized_keys present ($keys key(s))"
    mode=$(stat -c '%a' /root/.ssh/authorized_keys 2>/dev/null)
    [ "$mode" = "600" ] || note "/root/.ssh/authorized_keys has mode $mode (expected 600)"
else
    bad "/root/.ssh/authorized_keys missing or empty"
fi

if systemctl is-active ssh >/dev/null 2>&1 || systemctl is-active sshd >/dev/null 2>&1; then
    ok "sshd running"
else
    bad "sshd not running"
fi

# ── 7. Initiale Version ──────────────────────────────────────────────
hdr "Version State"

if [ -f /data/thinforge/installed_version ]; then
    ver=$(tr -d '[:space:]' < /data/thinforge/installed_version)
    ok "installed_version = $ver"
else
    bad "/data/thinforge/installed_version missing — server cannot assign delta updates"
fi

# ── 8. Konnektivitaet (best-effort) ──────────────────────────────────
hdr "Connectivity (best-effort)"

if [ -f /data/thinforge/agent.conf ]; then
    server_url=$(awk -F= '/^[[:space:]]*server_url/ {gsub(/[[:space:]]/, "", $2); print $2}' /data/thinforge/agent.conf)
    if [ -n "$server_url" ] && command -v curl >/dev/null 2>&1; then
        if curl --max-time 5 --cacert /data/thinforge/server.crt -fsSL -o /dev/null \
             "${server_url}/api/health" 2>/dev/null; then
            ok "TLS connection to ${server_url}/api/health successful"
        else
            note "TLS connection to ${server_url}/api/health failed (server offline / route missing / cert mismatch)"
        fi
    fi
fi

# ── Auswertung ───────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Summary${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}OK:${NC}    $PASS"
echo -e "  ${YELLOW}WARN:${NC}  $WARN"
echo -e "  ${RED}FAIL:${NC}  $FAIL"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}Failures:${NC}"
    for item in "${FAIL_ITEMS[@]}"; do
        echo -e "  - $item"
    done
    echo ""
fi

if [ "$WARN" -gt 0 ]; then
    echo -e "${YELLOW}Warnings:${NC}"
    for item in "${WARN_ITEMS[@]}"; do
        echo -e "  - $item"
    done
    echo ""
fi

if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}Agent installation complete.${NC}"
    exit 0
else
    echo -e "${RED}Agent installation incomplete — see failure list above.${NC}"
    exit 1
fi
