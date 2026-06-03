#!/bin/sh
# dnsmasq dhcp-script hook — forwards every lease event (add/old/del) to the
# ThinForge backend so it can bind NFS authorisation to actual DHCP state.
#
# dnsmasq invocation: script $ACTION $MAC $IP [$HOSTNAME]
#   ACTION ∈ {add, old, del}
#
# Authentication: network isolation. The backend endpoint is on
# 127.0.0.1:8000, Caddy refuses /api/v1/dhcp/* on :80, and this container
# runs with network_mode:host — so the dnsmasq process and the backend share
# the host loopback and no LAN peer can reach the endpoint. MAC+IP in the
# payload are trusted because the caller can only be dnsmasq itself.
#
# Fire-and-forget: we never block dnsmasq, so lease issuance is never delayed
# by backend latency or outage. Always exit 0.

set -u

ACTION="${1:-}"
MAC="${2:-}"
IP="${3:-}"
HOSTNAME="${4:-}"

BACKEND_URL="${THINFORGE_BACKEND:-http://127.0.0.1:8000}"

# Abort conditions (exit 0 — never fail a lease)
[ -z "$ACTION" ] && exit 0
[ -z "$MAC" ]    && exit 0
[ -z "$IP" ]     && exit 0

# dnsmasq container ships wget (separate apt package, not busybox).
# We run in background so dnsmasq doesn't wait.
(
  wget \
    --quiet \
    --tries=1 \
    --timeout=5 \
    --header="Content-Type: application/json" \
    --post-data="{\"mac\":\"$MAC\",\"ip\":\"$IP\",\"action\":\"$ACTION\",\"hostname\":\"$HOSTNAME\"}" \
    -O /dev/null \
    "$BACKEND_URL/api/v1/dhcp/lease-event" 2>/dev/null || true
) &

exit 0
