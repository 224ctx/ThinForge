# 15 — Firewall Rules

This chapter summarizes which connections ThinForge needs so that a company firewall can allow them — by direction, source and destination, protocol and port, with hostnames where they are fixed. Connections between the containers and to the server's operating system (database, Redis, internal services) are not listed: they stay on the server and never touch a firewall. Which connections the server opens towards the outside on its own and how to switch them off is described in [12 — Security → Outgoing connections](12-security-and-cve-scan.md#outgoing-connections); this chapter is about the rules for them.

> **The essentials.** The server opens all connections to the internet itself and needs **no inbound port from the internet** — not even for the VPN. No port forwarding, no telemetry, no check with the vendor, no automatic certificates. In operation the server talks on its own only to the time server, DNS and — once set up — the VPN instance; everything else happens only on command or when it is configured.

## The three networks

The server has two adapters ([workflows/setup-wizard.md](workflows/setup-wizard.md)): the **management interface** on the company LAN, through which the interface is reached and the server gets to the internet, and the **rollout interface** into the client network, where it is DHCP, DNS, PXE and time server for the devices ([07 — Network](07-network.md)). With the VPN active, the **VPN instance** on the internet is added, to which server and devices build their tunnels ([13 — VPN](13-vpn.md)). The tables follow these three paths.

## Management network → server

| Source → destination | Protocol / port | Purpose | Required |
|---|---|---|---|
| Admin workstations → server (management address) | TCP 443 | Web interface and API, including terminal and remote desktop in the browser | required |
| Admin workstations → server | TCP 22 | SSH for installing and maintaining the operating system — a matter of the server, not of ThinForge | optional |

On the management address only port 443 answers; the server serves port 80 only on the rollout address (PXE). PostgreSQL (5432), Redis (6379), backend (8000) and frontend (3000) are published only on the server's loopback and appear on no interface.

## Client network ↔ server

The client network is attached directly to the rollout interface; DHCP, PXE and multicast work with broadcast or stay within the local segment. These rules are needed only if a firewall filters inside this network — for example between switch segments or when the server itself is not the devices' gateway (DHCP option 3, [07 — Network](07-network.md)).

**Devices → server (rollout address)**

| Service | Protocol / port | Purpose | Required |
|---|---|---|---|
| DHCP | UDP 67, 68 | Address assignment and PXE boot of the devices | required with the built-in DHCP server |
| TFTP | UDP 69 | First boot files at PXE start (`pxelinux.0`, GRUB, `boot.ipxe`) | required for cloning and capturing |
| DNS | UDP/TCP 53 | Name resolution for the devices, including `thinforge-server` and the local domain | required (on by default) |
| Time service (NTP) | UDP 123 | Clock of the devices (handed out via DHCP option 42) | required |
| HTTP | TCP 80 | PXE: kernel, Clonezilla image, deploy scripts and the devices' callbacks during cloning and capturing | required for cloning and capturing |
| HTTPS | TCP 443 | Agent: heartbeat, certificates, agent update, delta downloads (`https://thinforge-server`) | required |
| NFS (version 3) | TCP 2049, TCP/UDP 111 (rpcbind) and dynamic RPC ports (mountd) | Clone image during unicast deployment, storage during capture | required for unicast deployment and capture |
| BitTorrent | TCP/UDP 6969 (tracker), TCP/UDP 6881 (seeder) and peer ports between the devices | BitTorrent deployment; tracker and seeder run only during the rollout | optional |
| Multicast | UDP from 2232, two ports per partition, to 224.0.0.1 (TTL 1) | Multicast deployment; stays within the segment | optional |

**Server → devices**

| Service | Protocol / port | Purpose | Required |
|---|---|---|---|
| SSH | TCP 22 | Terminal, remote desktop (VNC 5900 runs inside the SSH tunnel), tasks, control of cloning and capturing | required |
| ICMP | echo | Reachability ping from the Clients view | optional |
| Wake-on-LAN | UDP 9, broadcast | Switch devices on; only within the same network | optional |

## Server → internet

On its own, the server opens only a few connections in operation. The tables name all destinations and when they are contacted; switching them off is described in [12 — Security](12-security-and-cve-scan.md#outgoing-connections).

**In operation**

| Destination | Protocol / port | Purpose | When |
|---|---|---|---|
| Time servers — default `0.pool.ntp.org`, `1.pool.ntp.org` | UDP 123 | Clock of the server, which the devices use as their time source | permanently; your own time server under **Settings → General** |
| DNS servers from the setup wizard | UDP/TCP 53 | Resolve names outside your own network for the devices | on the devices' DNS queries; changeable under **Network → DNS** |
| VPN instance — host from the VPN management URL | TCP 443, plus UDP 3478 (STUN, optional) | Management, signal and relay of the VPN | permanently, once the VPN is set up (see below) |
| Mail server from the settings | TCP 587 (STARTTLS) or 465 (TLS); another port only without login or with explicit approval (`allow_insecure_auth`) | Alert mails, test mail, link from "Forgot password?" | only when configured |
| Webhook address from the settings | TCP, port from the address (443 or 80) | Alerts | only when configured |
| Vulnerability database `grype.anchore.io` | TCP 443 | Basis of the vulnerability scan | only when a scan is started by hand |
| `www.cisa.gov` (KEV catalog), `git.thinforge.org` (newer acceptance list) | TCP 443 | Cross-check of the scan assessment | off by default |
| SourceForge (Clonezilla Live) or any address you enter | TCP 443 or 80 | ISO download in the wizard or "Download ISO from URL" | only on click |
| OCSP service of the issuing certificate authority | TCP 80 or 443 | Revocation status of an uploaded public certificate | depends on the certificate; not with the bundled self-signed one |

**Installation and update** — everything only on command:

| Destination | Protocol / port | Purpose | When |
|---|---|---|---|
| `git.thinforge.org` | TCP 443 | Release repository and ThinForge's container images | `bootstrap-release.sh`, every `./deploy.sh` |
| Docker Hub (`registry-1.docker.io` and the hosts Docker Hub redirects to during a pull) | TCP 443 | Images of PostgreSQL, Redis and Caddy, for remote desktop (`guacamole/guacd`) and the VPN (`netbirdio/netbird`) | installation and update |
| Ubuntu package sources, `download.docker.com` | TCP 443 and 80 | Docker installation by `install-deps.sh` | installation |
| Docker Hub (`golang`) and the Go module proxy (`proxy.golang.org`, `sum.golang.org`) | TCP 443 | Building the agent from the interface | only with `THINFORGE_AGENT_BUILD_ENABLED=true`; off by default in ThinForge-Release |

For an installation without internet, the images can be mirrored in advance (`./deploy.sh --pull-only` on a machine with internet, then `docker save`/`docker load`) and the Clonezilla ISO uploaded — details in [12 — Security](12-security-and-cve-scan.md#outgoing-connections).

**Image creation in the cloning VM** — the virtual machine has unfiltered internet access through QEMU's network translation; it can only be restricted at the host's or the perimeter firewall. The installation scripts of the Tools ISO fetch packages from the chosen distribution's package sources, the VPN client via the installation script from `pkgs.netbird.io` and — if the distribution lacks the package — `grub-btrfs` from `github.com`; the optional VDI clients are downloaded by `install-vdi-clients-debian.sh download` from the vendors' sites.

## VPN

Server and devices open the connection to the VPN instance themselves — from the inside out. Nothing has to be opened inbound.

| Source → destination | Protocol / port | Purpose | Required |
|---|---|---|---|
| ThinForge server → host from the VPN management URL (e.g. `teststellung01.thinforge.org`) | TCP 443 | Management (management API), signal and relay: registration, reconciliation every minute and the server peer's tunnel | required |
| ThinForge server → the same host | UDP 3478 | STUN for connection setup; without it the server's tunnel runs through the relay | optional |
| Devices in the home office → host from the VPN management URL | TCP 443 | Management, signal and relay — the devices force the relay path (`NB_FORCE_RELAY=true`) and need no further port | required |
| Devices with agent up to version 2.24.0 → `thinforge.org` | TCP 443 | Diagnostic request (headers only), only when the VPN instance is unreachable; may stay blocked | optional |

With the VPN option from ThinForge, management, signal, relay and STUN all run under the one hostname from the booking — in the example `teststellung01.thinforge.org`: management, signal and relay on TCP 443, STUN on UDP 3478. With a self-hosted instance, the hostnames and ports set up there apply — the management API, signal and relay must be reachable. What runs through the tunnel is governed by ThinForge through the rules on the VPN instance, not by the company firewall: devices → server on TCP 443 and UDP 53, server → devices via SSH (TCP 22) and ICMP, plus your own exposures ([13 — VPN](13-vpn.md)).

## What is not needed

- **No inbound port from the internet** to the server and no port forwarding — not even for the VPN. Devices in the home office reach the server only through the tunnel.
- **No connection to the vendor in operation:** no telemetry, no subscription check (the server verifies the file offline), no search for new versions, no automatic certificates (no ACME).
- **No port 80** on the management address — the server serves it only on the client network for PXE.
- **No rules for database, Redis, backend and frontend** — they are reachable only on the server itself.

## Next steps

- [07 — Network](07-network.md) for DHCP, DNS and PXE on the client network.
- [12 — Security](12-security-and-cve-scan.md#outgoing-connections) for trigger, default and switching off of the outgoing connections.
- [13 — VPN](13-vpn.md) for setting up and running the VPN.
