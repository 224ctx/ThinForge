# 7 — Network

The Network menu gathers everything related to ThinForge's infrastructure side: server interfaces, DHCP/PXE, DNS, and VPN.

The view has four tabs:

## Tab: Local Network (server interfaces)

Shows every network interface on the server host with its current IP, MAC, and link status. For regular operation mostly read-only — ThinForge reads `/proc/net`.

**Typical use:** see which interface carries traffic, verify the management interface is online before a rollout.

**"Apply"** writes a netplan file on the host via a short privileged container and applies it — this is an admin step, usually done during setup.

## Tab: DHCP / PXE

The internal `dnsmasq` service handles DHCP and PXE boot for the management subnet.

### Settings

| Field | Meaning |
|-------|---------|
| Subnet | CIDR of the management network, e.g. `192.168.10.0/24` |
| Gateway | usually the ThinForge server IP |
| DNS | upstream DNS for clients (default: local dnsmasq) |
| Rollout IP range | start and end of the pool for clients to get a temporary IP during PXE boot |
| Lease time | typical 8h |
| Domain suffix | optional, e.g. `.thinforge.local` |

**Save** writes a new `dnsmasq.conf` and restarts the service.

### Leases

Table with currently-assigned DHCP leases (MAC, IP, hostname, expires). Useful to check whether a new client has even received DHCP. A client appears here **before** it shows up in the clients list (lease comes during PXE boot, client object only after the first agent heartbeat).

### PXE boot

ThinForge automatically provides a TFTP root and a GRUB EFI/BIOS boot chain. New clients PXE-boot into the Tools ISO (provisioning) or into a deploy boot (install an image).

**Error patterns:**

- Client shows "PXE-E61: Media test failure" → DHCP not reaching. Check subnet, gateway, switch IGMP/helper.
- Client gets an IP but does not boot → TFTP blocked? Is the dnsmasq container running ([02 — Dashboard](02-dashboard.md))?

## Tab: DNS

Two areas:

### Upstream DNS

Which external DNS servers dnsmasq queries when a name is not locally known. Default: management gateway IP from the setup wizard. For branch-office scenarios often a central corporate DNS.

### Local domain

The internal zone for which dnsmasq acts authoritative (e.g. `thinforge.local`). Clients receive this domain as search suffix on their DHCP lease.

Changes here require a dnsmasq restart (happens automatically on save).

## Tab: VPN

ThinForge uses **WireGuard** for secure access to clients outside the local management network (field service, home office, branch offices).

### VPN status

Tab-wide status at the top: **server active**, **interface up**, **port open** (usually 51820/UDP).

### Client list

Table of all registered VPN peers:

| Column | Meaning |
|--------|---------|
| Name | client hostname |
| Public key | WireGuard pubkey |
| VPN IP | internal VPN address |
| Last handshake | when the client last checked in |
| Traffic | bytes sent / received this session |
| Status | `connected` / `stale` / `error` |

### Provisioning

A new client receives its VPN configuration **automatically** during agent setup — WireGuard keys are generated on both sides and exchanged. For the operator there's usually nothing to do; manual intervention is only needed in special cases (key rotation, VPN gateway move):

- **"Deploy"** on a client → generates new keys, pushes the config to the agent, restarts WireGuard.
- **"Undeploy"** → removes the peer from the server; the agent deletes the local VPN config.

### Traffic statistics

A separate sub-tab with historical traffic per client (monthly, daily). Useful for capacity planning (which branch consumes how much) and for billing if ThinForge infrastructure is shared.

## Branch offices

When multiple branches each have their own local network, clients there usually connect via VPN to headquarters. Recommended setup:

- One **group per location** ([04](04-groups.md))
- **BitTorrent rollout** instead of unicast — clients in a branch distribute data internally via VPN-internal peering
- **Multicast not over VPN** — only works locally. For within-branch rollouts a branch relay could make sense in the future but is not available today.

## Next steps

- [workflows/first-client.md](workflows/first-client.md) — onboard a client via DHCP + PXE
- [09 — Settings](09-settings.md) — NTP, TLS, general server config
