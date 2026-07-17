# 1 — Getting Started

## Installation

ThinForge runs as a Docker stack on a server in your local network (Debian or Ubuntu). A bootstrap script handles the installation; it is run once on the fresh server:

```bash
./bootstrap-release.sh
```

It downloads the ThinForge components, sets up the base configuration including automatically generated access secrets (no manual `.env` editing needed) and starts the whole stack. Afterwards the web interface is reachable at the server's address.

> **Note:** You get the bootstrap script from your ThinForge provider. `git` must be present on the server; the script installs all other dependencies itself.

## Open the server URL

The web interface is reachable under the HTTPS address of the ThinForge server. On first access the browser shows a certificate warning because the installation ships with a self-signed certificate. Once your own certificate is installed (see [09 — Settings](09-settings.md), TLS section), the warning goes away.

```
https://<server-hostname-or-ip>/
```

## Setup wizard

On the very first access after a fresh installation, the **setup wizard** appears. It walks through six steps of basic configuration:

1. **Create admin account** — email, display name, password. This is the first admin account; additional users are added later in the settings.
2. **Server identity** — hostname and local domain for dnsmasq.
3. **DHCP / PXE** — subnet and rollout IP range, plus the upstream DNS. Needed for booting new thin clients.
4. **NTP** — upstream time server. Default is `0.pool.ntp.org`; internally usually a local management NTP.
5. **HTTPS / TLS** — a self-signed certificate is created.
6. **Summary** — review all entries and finish.

After completion you land on the **dashboard**. The tools ISO for initial client provisioning is not built during setup, but on the first start of the cloning VM.

> **Note:** If the wizard is cancelled, it re-appears on the next login until every step has been completed at least once.

## Signing in

After setup you sign in with the admin credentials you just created. Additional operator and viewer accounts are set up in [09 — Settings → Users](09-settings.md#users--roles).

**Forgot your password?** Sending a reset link by email is not available yet. Have another admin set a new password in [09 — Settings → Users](09-settings.md#users--roles) instead.

## UI tour

The window is split into three regions:

```
┌─────────────────────────────────────────────────────────┐
│ TopBar: version │ user │ theme │ language │ logout      │
├──────────┬──────────────────────────────────────────────┤
│          │                                              │
│ Sidebar  │                 Main content area            │
│          │                                              │
│          │                                              │
└──────────┴──────────────────────────────────────────────┘
```

### TopBar (top)

- **Version chip** (`v2026-04-14` or similar) — clicking it opens the changelog dialog with all release notes.
- **User menu** — profile settings, change password, logout.
- **Theme switch** — dark/light mode.
- **Language selector** — German/English.

### Sidebar (left)

Menu entries depend on permissions. A typical operator sees:

- **Dashboard** — overview ([02](02-dashboard.md))
- **Clients** — device management ([03](03-clients.md))
- **Groups** — organisation ([04](04-groups.md))
- **Cloning** — image management; rollouts/rollback live here as tabs ([05](05-cloning.md))
- **VPN** — ThinVPN management
- **Network** — infrastructure settings ([07](07-network.md))
- **Tasks** — running and historical jobs ([08](08-tasks-logs.md))
- **Reports** — analytics and exports
- **Settings** — services, config, users ([09](09-settings.md))
- **Logs** — server logs, admins only ([08](08-tasks-logs.md))
- **Info** — system info and backup

### Main area (right)

The content changes with the selected menu entry. Most views have an **action bar** at the top (New, Import, Export, Refresh) and a list or detail form below.

## Customising the dashboard

The **cog icon** at the top right of the dashboard lets you show/hide individual cards and rearrange them via drag & drop. Settings are stored locally in the browser (per device).

## Next steps

- **No clients yet?** → [workflows/first-client.md](workflows/first-client.md)
- **Want to understand what the dashboard shows?** → [02 — Dashboard](02-dashboard.md)
- **Want to build a new image?** → [workflows/golden-image.md](workflows/golden-image.md)
