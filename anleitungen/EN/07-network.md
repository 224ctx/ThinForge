# 7 — Network

The Network menu gathers everything related to ThinForge's infrastructure side: server interfaces, DHCP, DNS, and PXE boot.

The view has four tabs: **Local Network**, **DHCP / DNSMASQ**, **DNS**, and **PXE Boot**. Remote access via VPN lives in its own **VPN** menu entry.

## Tab: Local Network (server interfaces)

Shows every network interface on the server host with its current IP, MAC, and link status. For regular operation mostly read-only — ThinForge reads `/proc/net`.

**Typical use:** see which interface carries traffic, verify the management interface is online before a rollout.

**"Apply"** writes a netplan file on the host via a short privileged container and applies it — this is an admin step, usually done during setup.

## Tab: DHCP / DNSMASQ

The internal `dnsmasq` service handles DHCP and PXE boot for the management subnet. PXE boot itself is covered in its own **PXE Boot** tab.

### Settings

| Field | Meaning |
|-------|---------|
| Subnet | CIDR of the management network, e.g. `192.168.10.0/24` |
| Gateway | usually the ThinForge server IP; you can also point it to an internal firewall here |
| DNS | upstream DNS for clients (default: local dnsmasq) |
| Rollout IP range | start and end of the pool for clients to get a temporary IP during PXE boot |
| Lease time | default 12h (format e.g. `12h` or `1d`) |
| Domain suffix | optional, e.g. `.thinforge.local` |

**Save** writes a new `dnsmasq.conf` and restarts the service.

### Leases

Table with currently-assigned DHCP leases (MAC, IP, hostname, expires). **DHCP addresses are handed out only to known (registered) clients — unknown devices are ignored.** A device must therefore exist in the clients list before it gets an IP via DHCP/PXE; the lease table then helps to check whether it has received one.

## Tab: DNS

Two areas:

### Upstream DNS

Which external DNS servers dnsmasq queries when a name is not locally known. Default: management gateway IP from the setup wizard. For branch-office scenarios often a central corporate DNS.

### Local domain

The internal zone for which dnsmasq acts authoritative (e.g. `thinforge.local`). Clients receive this domain as search suffix on their DHCP lease.

Changes here require a dnsmasq restart (happens automatically on save).

**Recommendation:** Leave the ThinForge server as the clients' DNS server (the default, DHCP option 6). It answers the local domain itself and forwards external names to the upstream DNS; pointing clients directly at an external DNS breaks local and VPN-internal name resolution.

## Tab: PXE Boot

This tab bundles the boot infrastructure and the boot modes of all clients. ThinForge automatically provides a TFTP root and a GRUB EFI/BIOS boot chain; new clients PXE-boot into the Tools ISO (provisioning) or into a deploy boot (install an image).

**Status cards:** Three cards show whether the TFTP/dnsmasq service is running and whether the PXE boot files and the Clonezilla image (for capture/deploy) are ready. If Clonezilla is missing, it can be downloaded directly (default URL or a custom URL) or uploaded as an ISO.

**Client list:** Below, all clients are grouped by group, each with hostname, user, inventory number, boot mode, assigned image, and config file. The boot mode can be set per client directly — reset to **Local**, trigger a **Capture**, or delete the boot config. These are the same boot modes as in the client detail view ([03 — Clients](03-clients.md)), here centralized for all devices.

**Error patterns:**

- Client shows "PXE-E61: Media test failure" → DHCP not reaching. Check whether the client exists (unknown MACs get no DHCP), plus subnet, gateway, switch IGMP/helper.
- Client gets an IP but does not boot → TFTP blocked? Is the dnsmasq container running ([02 — Dashboard](02-dashboard.md))?

## VPN

ThinForge uses a VPN for secure access to clients outside the local management network (field service, home office, branch offices). It has its own menu entry — everything about it is covered there.

## Branch offices

When multiple branches each have their own local network, clients there usually connect via VPN to headquarters. Recommended setup:

- One **group per location** ([04](04-groups.md))
- **BitTorrent rollout** instead of unicast — clients in a branch distribute data internally via VPN-internal peering
- **Multicast not over VPN** — only works locally. For within-branch rollouts a branch relay could make sense in the future but is not available today.

## Next steps

- [workflows/first-client.md](workflows/first-client.md) — onboard a client via DHCP + PXE
- [09 — Settings](09-settings.md) — NTP, TLS, general server config
