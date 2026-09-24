# 7 — Network

The Network menu gathers everything related to ThinForge's infrastructure side: server interfaces, DHCP, DNS, and PXE boot.

The view has four tabs: **Local Network**, **DHCP / DNSMASQ**, **DNS**, and **PXE Boot**. Remote access via VPN lives in its own **VPN** menu entry.

> **This chapter is admin territory.** Every role may look: all tabs, status cards, lease tables and boot modes are readable as an operator or viewer. **Since 2026-08-31 only an admin may change anything:** saving DHCP and DNS settings, resetting leases, reloading dnsmasq, applying the netplan configuration, downloading/uploading/deleting Clonezilla, syncing PXE files, and setting or clearing boot modes.
>
> The buttons stay visible to everyone; pressing one without the admin role returns an error instead of an effect. The [role overview](README.md#roles-in-the-system) explains why.

## Tab: Local Network (server interfaces)

The **Server Network Configuration** card has two areas:

- **Management Network (Upstream / Internet)** — the interface with the default route and its IP (display only), plus the **Upstream DNS** for the server's own name resolution
- **Client Network (Rollout / DHCP)** — **Interface** (selection of all physical host interfaces with MAC, address and link status), **Server IP** and **CIDR**; from these the interface derives **Gateway**, **Subnet Mask**, **DHCP Start** and **DHCP End** (fields you changed by hand stay as they are); plus **Domain** and **Lease Duration**

**Typical use:** see which interface carries traffic, verify the management interface is online before a rollout.

**"Save"** puts the server IP on the client interface (via a short privileged container as a netplan file on the host and immediately as an address), rewrites the DHCP configuration and updates the `thinforge-server` DNS entry — this is an admin step, usually done during setup.

## Tab: DHCP / DNSMASQ

The internal `dnsmasq` service handles DHCP and PXE boot for the client network. PXE boot itself is covered in its own **PXE Boot** tab.

At the top, the **MAC Filter active** notice applies: dnsmasq only answers registered MAC addresses and runs non-authoritatively, so it can coexist with an existing DHCP server. If a client reports an IP other than its fixed assigned one, an **IP Address Conflict Detected** warning lists it with both addresses.

### Settings

First choose the mode: **DHCP Server** (dnsmasq hands out the addresses) or **ProxyDHCP (PXE Only)** — then an existing DHCP server hands out the addresses, dnsmasq only supplies the PXE boot information, and instead of pool and network options you enter the **Subnet** of the existing DHCP server and optionally the interface.

| Field | Meaning |
|-------|---------|
| IP Range Start / End | pool from which every registered client gets its fixed IP |
| Subnet Mask | e.g. `255.255.255.0` |
| Lease Time | default 2h (format e.g. `12h` or `1d`) |
| Network Interface | empty = dnsmasq listens on all interfaces |
| Default Gateway | DHCP option 3; usually the ThinForge server IP; you can also point it to an internal firewall here |
| DNS Server 1 / 2 | DHCP option 6; empty = the gateway address |
| Domain | optional, DHCP option 15, e.g. `thinforge.local` |
| Upstream DNS (Server) | DNS for the server's own internet resolution; takes effect after the containers restart |

**Save & Apply** writes `/etc/dnsmasq.d/dhcp-settings.conf` and restarts dnsmasq; if the restart fails, the interface warns.

### Leases

Below, three cards show the service status, the registered clients and the active leases; **"Reload Config"** regenerates the device configuration and reloads dnsmasq, **"Reset leases"** clears the leases (clients get their reserved IP on the next request), **"Show config"** reveals the generated `clients.conf`. The **Active DHCP Leases** table lists MAC address, IP address, hostname and expiry. **DHCP addresses are handed out only to known (registered) clients — unknown devices are ignored.** A device must therefore exist in the clients list before it gets an IP via DHCP/PXE; the lease table then helps to check whether it has received one.

## Tab: DNS

The **DNS enabled** switch sits at the top; switched off, dnsmasq only acts as a DHCP/TFTP server. Switched on there are four areas: **Upstream DNS Servers**, **Local Domain**, **DNS Cache** (0–50000 entries, 0 = no cache) and **Custom DNS Entries** (IP address and hostname for devices or services without DHCP).

### Upstream DNS

Which external DNS servers dnsmasq queries when a name is not locally known (primary and secondary). Default: the management network upstream DNS entered in the setup wizard, otherwise the host's DNS servers, otherwise `8.8.8.8`/`8.8.4.4`. For branch-office scenarios often a central corporate DNS.

### Local domain

The internal zone for which dnsmasq acts authoritative (e.g. `thinforge.local`). Clients receive this domain as search suffix on their DHCP lease. With **Auto-expand hostnames** DHCP clients become resolvable as `hostname.domain`.

Changes here require a dnsmasq restart (happens automatically on save).

**Recommendation:** Leave the ThinForge server as the clients' DNS server (the default, DHCP option 6). It answers the local domain itself and forwards external names to the upstream DNS; pointing clients directly at an external DNS breaks local and VPN-internal name resolution.

## Tab: PXE Boot

This tab bundles the boot infrastructure and the boot modes of all clients. ThinForge automatically provides a TFTP root and a GRUB EFI/BIOS boot chain; depending on its boot mode a client PXE-boots into a capture (record an image), into a deploy boot (install an image) or locally from its disk.

**Status cards:** Three cards show whether the TFTP/dnsmasq service is running and whether the PXE boot files and the Clonezilla image (for capture/deploy) are ready. If Clonezilla is missing, it can be downloaded directly (default URL or a custom URL) or uploaded as an ISO.

**Client list:** Below, all clients are grouped by group, each with hostname, user, inventory number, boot mode, assigned image, and config file. The boot mode can be set per client directly — reset to **Local**, trigger a **Capture** (dialog **Capture Disk Image** with image name), or delete the boot config. **"Sync All"** creates missing boot configs; running deploy configs are left untouched. [03 — Clients](03-clients.md) explains the boot modes themselves; the deploy mode is set by deployments and rollouts ([06](06-rollouts.md)).

**Error patterns:**

- Client shows "PXE-E61: Media test failure" → DHCP not reaching. Check whether the client exists (unknown MACs get no DHCP), plus subnet, gateway, switch IGMP/helper.
- Client gets an IP but does not boot → TFTP blocked? Is the dnsmasq container running ([02 — Dashboard](02-dashboard.md))?

## VPN

ThinForge uses a VPN for secure access to clients outside the local management network (field service, home office, branch offices). It has its own menu entry — everything about it is covered there.

## Branch offices

When multiple branches each have their own local network, clients there usually connect via VPN to headquarters. Recommended setup:

- One **group per location** ([04](04-groups.md))
- **Clone deployments only on site** — unicast, multicast and BitTorrent distribute full images exclusively on the ThinForge server's rollout LAN ([06 — Rollouts and VPN](06-rollouts.md#rollouts-and-vpn)); devices for a branch are therefore imaged at headquarters or shipped with a clone created there
- **Management and delta updates run over the VPN** — heartbeat, remote access and the update chain reach the branch through the tunnel; a branch relay for on-site rollouts is not available.

## Next steps

- [workflows/first-client.md](workflows/first-client.md) — onboard a client via DHCP + PXE
- [09 — Settings](09-settings.md) — NTP, TLS, general server config
