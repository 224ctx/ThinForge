# 1 — Getting Started

## Installation

ThinForge runs as a Docker stack on a server in your local network (Debian or Ubuntu). A bootstrap script handles the installation; it is run once on the fresh server:

```bash
./bootstrap-release.sh
```

It downloads the ThinForge components, sets up the base configuration including automatically generated access secrets (no manual `.env` editing needed) and starts the whole stack. Afterwards the web interface is reachable at the server's address.

> **Note:** The bootstrap script lives in the public ThinForge release repository; the repository and the container registry can be read without credentials. `git` must be present on the server; the script installs all other dependencies itself.

## Open the server URL

The web interface is reachable under the HTTPS address of the ThinForge server. On first access the browser shows a certificate warning because the installation ships with a self-signed certificate. Once your own certificate is installed (see [09 — Settings](09-settings.md), TLS section), the warning goes away.

```
https://<server-hostname-or-ip>/
```

## Setup wizard

On the very first access after a fresh installation, the **setup wizard** appears. It walks through six steps of basic configuration:

1. **Create admin account** — username, email, password. This is the first admin account; additional users are added later in the settings.
2. **Server identity** — hostname and local domain for dnsmasq.
3. **DHCP / PXE** — management interface with upstream DNS, rollout interface with a static IP, and the DHCP mode (own DHCP server with an IP range, or proxy DHCP next to an existing one). Needed for booting new thin clients.
4. **NTP** — upstream time servers for the server (pre-filled with the default gateway) and the NTP server handed to the clients via DHCP (pre-filled with the rollout IP, otherwise `0.pool.ntp.org`). The wizard does not ask for a time zone — `Europe/Berlin` applies, changeable under [09 — Settings → Time zone](09-settings.md#time-zone).
5. **HTTPS / TLS** — a self-signed certificate is created.
6. **Summary** — review all entries and finish.

After completion the wizard redirects to the **login page** after 15 seconds. If a sub-step could not be done (for example the certificate or a key), it lists the warnings and only continues via **"Continue to login"**. The tools ISO for initial client provisioning is not built during setup, but on the first start of the cloning VM.

> **Note:** If the wizard is left before completing, it re-appears from the start on the next visit — until **"Complete"** has succeeded.

## Signing in

After setup you sign in with the admin credentials you just created. Additional operator and viewer accounts are set up in [09 — Settings → Users](09-settings.md#tab-users--roles).

**Forgot your password?** Sending a reset link by email is not available yet. Have another admin set a new password in [09 — Settings → Users](09-settings.md#tab-users--roles) instead.

## UI tour

The window is split into three regions:

```
┌─────────────────────────────────────────────────────────┐
│ TopBar: version │ theme │ language │ user menu (logout) │
├──────────┬──────────────────────────────────────────────┤
│          │                                              │
│ Sidebar  │                 Main content area            │
│          │                                              │
│          │                                              │
└──────────┴──────────────────────────────────────────────┘
```

### TopBar (top)

- **Menu icon** (far left) — shows and hides the sidebar.
- **Version chip** (`v2026-04-14` or similar) — clicking it opens the changelog dialog with all release notes.
- **Theme switch** — dark/light mode.
- **Language selector** — German/English.
- **User menu** (far right) — shows username and role, opens the profile (change password and 2FA there) and signs out.

### Sidebar (left)

Except for **Logs** (admins only), the sidebar is the same for every role — so it also shows areas where your own role may only read. What a role may actually change is listed in the [role overview](README.md#roles-in-the-system). An operator sees:

- **Dashboard** — overview ([02](02-dashboard.md)); the sub-entry **First Run Wizard** opens a short assistant for a first group, a first client and the Clonezilla download
- **Clients** — device management with the sub-entries Clients, Warranty, Agent and Certificates ([03](03-clients.md))
- **Groups** — organisation ([04](04-groups.md))
- **Cloning** — image management; deployments, updates and rollback live here as tabs ([05](05-cloning.md))
- **VPN** — ThinVPN management: connection to the VPN instance, clients, exposures
- **Network** — infrastructure settings ([07](07-network.md))
- **Tasks** — running and historical jobs plus scheduled tasks ([08](08-tasks-logs.md))
- **Reports** — analytics and exports
- **Settings** — services, config, users ([09](09-settings.md))
- **Logs** — audit log and container logs, admins only ([08](08-tasks-logs.md))
- **Info & Backup** — system info, backup & restore and the license texts

### Main area (right)

The content changes with the selected menu entry. Most views have an **action bar** at the top (New, Import, Export, Refresh) and a list or detail form below.

## Customising the dashboard

The **cog icon** at the top right of the dashboard lets you show/hide individual cards, change their width and rearrange them via drag & drop. Settings are stored locally in the browser (per device).

## Next steps

- **No clients yet?** → [workflows/first-client.md](workflows/first-client.md)
- **Want to understand what the dashboard shows?** → [02 — Dashboard](02-dashboard.md)
- **Want to build a new image?** → [workflows/golden-image.md](workflows/golden-image.md)
