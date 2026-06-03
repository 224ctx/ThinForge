# 1 — Getting Started

## Open the server URL

The web interface is reachable under the HTTPS address of the ThinForge server. On first access the browser shows a certificate warning because the installation ships with a self-signed certificate. Once your own certificate is installed (see [09 — Settings](09-settings.md), TLS section), the warning goes away.

```
https://<server-hostname-or-ip>/
```

## Setup wizard

On the very first access after a fresh installation, the **setup wizard** appears. It walks through five steps of basic configuration:

1. **Create admin user** — email, display name, password. This is the first admin account; additional users are added later in the settings.
2. **DNS configuration** — upstream DNS (default: management gateway), local domain for dnsmasq.
3. **DHCP / PXE** — subnet and rollout IP range. Needed for booting new thin clients.
4. **NTP** — chrony upstream server. Default is `pool.ntp.org`; internally usually a local management NTP.
5. **Tools ISO** — ISO for initial client provisioning is built. Takes 1–2 minutes.

After completion you land on the **dashboard**.

> **Note:** If the wizard is cancelled, it re-appears on the next login until every step has been completed at least once.

## Signing in

After setup you sign in with the admin credentials you just created. Additional operator and viewer accounts are set up in [09 — Settings → Users](09-settings.md#users--roles).

**Forgot your password?** The "Reset password" function on the login screen sends a reset link — an SMTP server must be configured in the settings for this to work. Without SMTP, another admin must set a new password in [09 — Settings → Users](09-settings.md#users--roles).

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
- **Cloning** — image management ([05](05-cloning.md))
- **Rollouts** — deployment planning ([06](06-rollouts.md))
- **Network** — infrastructure settings ([07](07-network.md))
- **Tasks** — running and historical jobs ([08](08-tasks-logs.md))
- **Logs** — server logs ([08](08-tasks-logs.md))
- **Settings** — services, config, users (admin only, [09](09-settings.md))

### Main area (right)

The content changes with the selected menu entry. Most views have an **action bar** at the top (New, Import, Export, Refresh) and a list or detail form below.

## Customising the dashboard

The **cog icon** at the top right of the dashboard lets you show/hide individual cards and rearrange them via drag & drop. Settings are stored per user.

## Next steps

- **No clients yet?** → [workflows/first-client.md](workflows/first-client.md)
- **Want to understand what the dashboard shows?** → [02 — Dashboard](02-dashboard.md)
- **Want to build a new image?** → [workflows/golden-image.md](workflows/golden-image.md)
