#!/bin/bash
# thinforge-vpn-reset.sh
#
# Remove the WireGuard-era (pre-NetBird) VPN artefacts from a ThinForge
# client. Removes every artefact that could pin the client to a stale
# WireGuard identity:
#
#   - Stops wg-quick@thinvpn so nothing holds /run/thinforge-wg open
#   - Evicts the TPM-sealed key at handle 0x81020001 (only if it's our
#     own keyedhash object — refuses to touch foreign TPM content
#     unless --force is given)
#   - Removes all TPM-mode artefacts on /data and /etc + /run tmpfs
#   - Removes plaintext-mode artefacts on /data and the /etc symlink
#   - daemon-reload so systemd forgets the dropin
#
# NetBird is NOT touched: the enrollment under /data/netbird, the netbird
# unit and the agent's /data/thinforge/vpn-pending.json stay as they are.
# Since the NetBird cutover the kernel link named `thinvpn` is NetBird's
# WireGuard interface (the agent runs `netbird up --interface-name thinvpn`),
# so the link is only torn down when it belongs to wg-quick — never under a
# running netbird daemon. A fresh NetBird enrollment is a server-side action
# ("VPN aktivieren" / re-enroll in ThinForge), not something this script
# prepares.
#
# Idempotent: safe to re-run, no-op on clean clients.
#
# Exit codes:
#   0  WireGuard-era artefacts are gone (whether something was removed or not)
#   1  refused to touch foreign TPM content; pass --force to override
#   2  a step failed (tpm2_evictcontrol error, unwritable filesystem, …)

set -u

FORCE=0
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=1 ;;
        -h|--help)
            sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "unknown argument: $arg" >&2
            exit 64
            ;;
    esac
done

if [ "$(id -u)" -ne 0 ]; then
    echo "must run as root" >&2
    exit 2
fi

TPM_HANDLE="0x81020001"
WG_IFACE="thinvpn"
# NetBird's persisted enrollment (agent-go: netbird.NetBirdStateDir); the
# daemon keeps its profile in default.json (0.71+), older versions in
# config.json.
NETBIRD_STATE_DIR="/data/netbird"

log() { printf '[vpn-reset] %s\n' "$*"; }

# netbird_owns_link: is the thinvpn link the NetBird daemon's? True when the
# daemon runs, or when a persisted enrollment exists (a stopped daemon comes
# back with it — deleting the link would not stop that, only break it now).
netbird_owns_link() {
    if systemctl is-active --quiet netbird.service 2>/dev/null; then
        return 0
    fi
    [ -e "$NETBIRD_STATE_DIR/default.json" ] || [ -e "$NETBIRD_STATE_DIR/config.json" ]
}

# ---------------------------------------------------------------------------
# 1) Stop the wg-quick tunnel — release tmpfs and any wg-quick post-up state
# ---------------------------------------------------------------------------
WG_UNIT_WAS_ACTIVE=0
if systemctl is-active --quiet "wg-quick@${WG_IFACE}.service" 2>/dev/null; then
    WG_UNIT_WAS_ACTIVE=1
    log "stopping wg-quick@${WG_IFACE}"
    systemctl stop "wg-quick@${WG_IFACE}.service" || true
fi
# Belt-and-braces for a zombie link wg-quick left behind — but ONLY when the
# link is wg-quick's. The very same name is NetBird's WireGuard interface
# on every enrolled client; deleting it under the daemon cuts the live
# tunnel, and nothing restarts it: the agent reconnects on the daemon's
# status, not on the interface, and a `Connected` daemon with a missing
# link stays that way until someone restarts netbird.
if ip link show "$WG_IFACE" >/dev/null 2>&1; then
    if [ "$WG_UNIT_WAS_ACTIVE" -eq 1 ] || ! netbird_owns_link; then
        log "deleting leftover ${WG_IFACE} link"
        ip link del "$WG_IFACE" 2>/dev/null || true
    else
        log "${WG_IFACE} link belongs to the NetBird daemon — left untouched"
    fi
fi

# ---------------------------------------------------------------------------
# 2) Evict TPM-sealed key (only if it's keyedhash; --force overrides)
# ---------------------------------------------------------------------------
tpm_reset() {
    if ! command -v tpm2_getcap >/dev/null 2>&1; then
        log "tpm2-tools not installed — skipping TPM eviction"
        return 0
    fi
    if [ ! -e /dev/tpm0 ] && [ ! -e /dev/tpmrm0 ]; then
        log "no TPM device present — skipping TPM eviction"
        return 0
    fi

    local handles
    handles=$(tpm2_getcap handles-persistent 2>/dev/null || true)
    if ! printf '%s' "$handles" | grep -q "$TPM_HANDLE"; then
        log "TPM slot $TPM_HANDLE already empty"
        return 0
    fi

    local pub_out type_value=""
    if pub_out=$(tpm2_readpublic -c "$TPM_HANDLE" 2>/dev/null); then
        type_value=$(printf '%s\n' "$pub_out" \
            | awk '/^type:/{flag=1; next} flag && /value:/{print $2; exit}')
    fi

    if [ "$type_value" = "keyedhash" ]; then
        log "TPM slot $TPM_HANDLE holds our keyedhash — evicting"
    elif [ "$FORCE" -eq 1 ]; then
        log "TPM slot $TPM_HANDLE holds ${type_value:-unknown} object — force-evicting (--force)"
    else
        log "TPM slot $TPM_HANDLE holds ${type_value:-unknown} object — refusing to touch (pass --force to override)"
        return 1
    fi

    if ! tpm2_evictcontrol -C o -c "$TPM_HANDLE" >/dev/null 2>&1; then
        log "tpm2_evictcontrol failed for $TPM_HANDLE"
        return 2
    fi
    log "TPM slot $TPM_HANDLE evicted"
    return 0
}

tpm_reset
rc=$?
case "$rc" in
    0) ;;
    1) exit 1 ;;
    *) exit 2 ;;
esac

# ---------------------------------------------------------------------------
# 3) Remove TPM-mode artefacts (source-of-truth on /data + runtime on @root)
# ---------------------------------------------------------------------------
TPM_ARTEFACTS=(
    /data/wireguard/thinvpn.template.conf
    /data/wireguard/thinforge-wg-unseal.sh
    /data/wireguard/tpm-dropin.conf
    /usr/local/bin/thinforge-wg-unseal.sh
    /etc/systemd/system/wg-quick@thinvpn.service.d/tpm.conf
    /etc/systemd/system/wg-quick@thinvpn.service.d/override.conf
)
for f in "${TPM_ARTEFACTS[@]}"; do
    if [ -e "$f" ] || [ -L "$f" ]; then
        rm -f "$f" && log "removed $f"
    fi
done
# Drop the per-unit dropin dir if it's empty now.
DROPIN_DIR=/etc/systemd/system/wg-quick@thinvpn.service.d
if [ -d "$DROPIN_DIR" ]; then
    rmdir "$DROPIN_DIR" 2>/dev/null && log "removed empty $DROPIN_DIR"
fi
# Tmpfs runtime — gone with the stopped unit, but make sure.
if [ -d /run/thinforge-wg ]; then
    rm -rf /run/thinforge-wg && log "removed /run/thinforge-wg"
fi

# ---------------------------------------------------------------------------
# 4) Remove plaintext-mode artefacts so nothing of the old identity remains
# ---------------------------------------------------------------------------
PLAINTEXT_ARTEFACTS=(
    /data/wireguard/thinvpn.conf
    /etc/wireguard/thinvpn.conf
)
for f in "${PLAINTEXT_ARTEFACTS[@]}"; do
    # Use -L (symlink check) before -e (target check) so a dangling
    # symlink is also caught.
    if [ -L "$f" ] || [ -e "$f" ]; then
        rm -f "$f" && log "removed $f"
    fi
done

# ---------------------------------------------------------------------------
# 5) daemon-reload — systemd needs to forget the dropin
# ---------------------------------------------------------------------------
if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload && log "systemctl daemon-reload"
fi

# ---------------------------------------------------------------------------
# 6) Final sanity: TPM slot must be empty AND no template/plaintext present
# ---------------------------------------------------------------------------
clean=1
if command -v tpm2_getcap >/dev/null 2>&1 \
   && { [ -e /dev/tpm0 ] || [ -e /dev/tpmrm0 ]; }; then
    if tpm2_getcap handles-persistent 2>/dev/null | grep -q "$TPM_HANDLE"; then
        log "post-reset: TPM slot $TPM_HANDLE still populated"
        clean=0
    fi
fi
for f in "${TPM_ARTEFACTS[@]}" "${PLAINTEXT_ARTEFACTS[@]}"; do
    if [ -L "$f" ] || [ -e "$f" ]; then
        log "post-reset: $f still present"
        clean=0
    fi
done

if [ "$clean" -eq 1 ]; then
    if netbird_owns_link; then
        log "WireGuard-era VPN artefacts removed — the NetBird enrollment on this client is untouched"
    else
        log "WireGuard-era VPN artefacts removed — no NetBird enrollment on this client"
    fi
    exit 0
fi
exit 2
