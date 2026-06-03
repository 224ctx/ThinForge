#!/bin/bash
# thinforge-vpn-reset.sh
#
# Bring a ThinForge client into a known-clean state for a fresh VPN-key
# install. Removes every artefact that could pin the client to a stale
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
# Idempotent: safe to re-run, no-op on clean clients.
#
# Exit codes:
#   0  client is clean (whether something was removed or not)
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

log() { printf '[vpn-reset] %s\n' "$*"; }

# ---------------------------------------------------------------------------
# 1) Stop the tunnel — release tmpfs and any wg-quick post-up state
# ---------------------------------------------------------------------------
if systemctl is-active --quiet "wg-quick@${WG_IFACE}.service" 2>/dev/null; then
    log "stopping wg-quick@${WG_IFACE}"
    systemctl stop "wg-quick@${WG_IFACE}.service" || true
fi
# Belt-and-braces: tear down the interface even if the unit was already
# stopped but the kernel-side link is still there (zombie state).
if ip link show "$WG_IFACE" >/dev/null 2>&1; then
    log "deleting leftover ${WG_IFACE} link"
    ip link del "$WG_IFACE" 2>/dev/null || true
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
# 4) Remove plaintext-mode artefacts so the next install starts from zero
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
   && [ -e /dev/tpm0 -o -e /dev/tpmrm0 ]; then
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
    log "client is now in a clean VPN state — ready for fresh key install"
    exit 0
fi
exit 2
