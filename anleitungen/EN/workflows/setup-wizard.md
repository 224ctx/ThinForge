# Workflow: Setup Wizard — First Installation of the Server

On the very first visit to a fresh ThinForge installation the router guard redirects to `/setup` automatically. There a stepper walks through all required settings. This document describes the steps in the order in which they actually appear — with all validation rules and the typical pitfalls.

## Preparation

Before you start the wizard:

- The server host has a static IP (management interface).
- HTTPS access to the server FQDN works in principle (self-signed is fine — the wizard replaces it).

## Restore (removed)

The wizard no longer has a restore step — it always sets up from scratch, and the former endpoints (`/setup/validate-backup`, `/setup/restore`, `/setup/partial-restore`) no longer exist. You restore a backup after setup under **Info & Backup → Backup & Restore**. Anyone who opens `/setup` after setup has been completed lands on the dashboard with a notice.

## Step 1: Admin account

| Field | Rule |
|---|---|
| Username | Required, at least 3 characters |
| Email | Required, in the form `name@domain.tld` (rough check) |
| Password | Required, at least 8 characters |
| Confirm password | Must match exactly |

The admin account has full rights. You add further users (operator, viewer) later under **Settings → Users**.

In the background the wizard already loads interface suggestions for step 3 (`GET /setup/network-defaults`), so the selection there is quicker.

## Step 2: Server identity

| Field | Rule |
|---|---|
| Hostname | Required — e.g. `thinforge` |
| Domain | Required — e.g. `thinforge.local`, `example.com` |

From these the wizard later builds the FQDN for the TLS certificate in step 5.

## Step 3: Network / DHCP

The most important page. Two logical interfaces:

- **Management interface** — traffic to and from the admin browser (usually the server's LAN interface).
- **Rollout interface** — the network the thin clients are in (can be identical to the management interface or a dedicated clone VLAN).

If both are identical, it is enough to enter it for management and select the same one for the rollout.

| Field | Rule |
|---|---|
| Management interface | Selection from the interfaces that have an address, suggestion from `GET /setup/network-defaults`; used to pre-fill the upstream DNS |
| Management DNS | Optional — upstream DNS for the server (field **Upstream DNS (Server)**) |
| Rollout interface | Selection from all physical network cards; the completion refuses any other |
| Rollout IP | Static IP of the rollout interface. Leaving it empty only works if the interface already carries an IPv4 address — otherwise the completion refuses. If it stays empty, the completion takes the interface's address as the rollout IP (stored, in the certificate, and for the NTP access of this network only). From IP and CIDR the wizard pre-calculates the IP range (network address + 10 up to broadcast − 1; from /29 on it stays empty, see server mode below), netmask, gateway and DNS server |
| Rollout CIDR | 1–32 |
| DHCP mode | `server` (ThinForge's dnsmasq is the DHCP server) or `proxy` (a DHCP server already exists, ThinForge only supplies the PXE options). `proxy` cannot be selected since 2026-09-30 until clarified: the button is disabled and the completion refuses the choice (`errors.network.proxyDhcpModeUnavailable`) |

Depending on the mode:

- **Server mode:** range start, range end, netmask, lease time (required, default `2h`), network interface, gateway, DNS servers for the devices (DHCP option 6; a list with **Add DNS server**, pre-filled with the rollout IP, empty = the gateway address — until 2026-10-02 two fixed fields), domain. The wizard suggests the range from rollout IP and CIDR (see table); in networks of /29 and smaller there is no room for it, the fields then stay empty and must be filled in by hand. **Next** only works if start and end lie inside the rollout network and the start is not after the end; since the update of 2026-09-30 the server runs the same check on completion (against the rollout IP or the address of the rollout interface).
- **Proxy mode** (currently locked, see table): subnet of the existing DHCP server, network interface.

In both modes only registered clients get an answer (MAC filter).

## Step 4: NTP

Time synchronization is mandatory — otherwise signed tokens and delta signatures will not work reliably later.

- **Enable NTP** (switch).
- **Upstream servers** (1 required, 2 optional) — server 1 is pre-filled with the server's default gateway; overwrite it if a different corporate NTP server exists.
- **NTP server for clients** (required) — pre-filled with the rollout IP (otherwise `0.pool.ntp.org`), so that thin clients use the ThinForge server as their NTP source; the clients receive it via DHCP.

Installations without outside contact switch it off and supply the clients with time manually.

- **Time zone** (required, pre-selected `Europe/Berlin`) — the operating time zone: task templates, maintenance windows, scheduled deployments and the day boundaries of the reports are calculated in it, and the clients adopt it with their heartbeat. The selection offers every zone the browser knows; the completion refuses a zone the server does not know. It can be changed afterwards under **Settings → General**, card **Time Server (NTP)** ([09 — Settings → Time zone](../09-settings.md#time-zone)).

## Signing key (automatic)

There is no separate step for it: on completion the wizard creates the minisign Ed25519 pair itself and then re-signs every signable artifact with this key in the background — including an agent binary that is already present. Without a key, signed delta updates cannot be distributed later.

The public key only reaches the Tools ISO on the first start of the cloning VM. This ISO build requires an agent binary signed to match exactly this key; if it is missing, the VM does not start, and the message names the step (build or sign it under **Clients → Agent**).

If generating the key fails, the completion shows a warning; you then create the key under **Settings → Security → Minisign Key** (see [12 — Security](../12-security-and-cve-scan.md)).

## Step 5: HTTPS / TLS

| Field | Rule |
|---|---|
| Common Name | Required, pre-filled with the FQDN from step 2; a DNS name like the SAN names (letters, digits, `-`, `_` per label, no wildcards). An invalid name is already flagged in the field, **Next** stays disabled |
| Validity in days | 1–3650 as in the TLS panel, default 365 (until the update of 2026-10-01 the wizard required at least 30) |
| SAN names | Comma-separated; pre-filled with FQDN + hostname + detected server IPs + rollout IP + `localhost`; every entry follows the same DNS name rule — wildcards such as `*.example.com`, spaces or IPv6 addresses are already flagged in the field (**Next** disabled), and the completion refuses them as well |

The wizard creates a self-signed certificate. After setup you can replace it with a CA-signed one at any time under **Settings → Security → HTTPS / TLS**.

## Step 6: Summary

Read-only table with all entries. Read through it once more, then **Complete**.

What happens behind the scenes:

1. `POST /setup/complete` with all configs. The backend first checks all entries (400) before it writes anything: the field check reports its objections all at once, time zone, rollout interface and rollout IP are checked one by one afterwards.
2. Backend: the admin user is created, the TLS certificate generated, the dnsmasq config written, NTP configured, heartbeat token, SSH and signing key generated (afterwards every artifact is signed with the new key in the background). Then it restarts Caddy, worker and backend. The wizard does **not** build a Tools ISO — that only happens on the first start of the cloning VM.
3. The frontend counts down 15 seconds (so Caddy can pick up the new certificate) and then redirects to `https://<address>/login` — the same address under which you opened the wizard. If a non-critical sub-step fails (for example the dnsmasq reload, the certificate or a key), the wizard shows the warnings instead, together with the button **"Continue to login"**; the items can be done in the settings after signing in.

## On first login

- Sign in with the admin user from step 1.
- The browser certificate is self-signed → add an exception or upload a CA-signed certificate.
- Recommendation: enable TOTP right away ([10 — Profile & 2FA](../10-profile-and-2fa.md)).

## Troubleshooting

- **`POST /setup/complete` fails with 400** → The message names the objections. Common: rollout IP empty although the rollout interface has no IPv4 address yet; an interface that is not a physical network card of the server; an invalid IPv4 value.
- **`POST /setup/complete` fails with 500** → check the server log (`docker compose logs backend`).
- **The redirect to `/login` never comes** → the Caddy certificate is not ready yet; after 30 s open `https://<fqdn>/login` manually. With warnings the wizard does not redirect by itself anyway — then click **"Continue to login"**.
- **The current installation should be reset** → not via the wizard but via **Settings → Factory Reset**; afterwards the wizard appears again. The wizard is only meant for fresh installations.

## Next steps

- [01 — Getting Started](../01-getting-started.md) for the tour through the fresh dashboard.
- [workflows/first-client.md](first-client.md) to onboard a client right away.
- [12 — Security](../12-security-and-cve-scan.md) for the signing key, replacing TLS and the initial CVE scan.
