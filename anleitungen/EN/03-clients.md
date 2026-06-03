# 3 — Clients

A **client** in ThinForge is a physical thin PC with an installed agent that regularly contacts the server via heartbeat. All management actions — image update, rollback, remote access, group assignment — act on client objects.

## Clients list

Menu left, **Clients**. The table shows all registered devices.

### Columns

| Column | Content |
|--------|---------|
| Status | Online (green) / VPN sync (light green) / Offline (grey) / Cloning (orange) / Error (red) |
| Hostname | Computer name reported by the agent |
| IP | Current management IP (VPN or LAN) |
| MAC | Primary NIC |
| Version | Currently-installed clone (`v1.003`, …) |
| Pending | Target version during a running update |
| Group | Assigned group ([04](04-groups.md)) |
| Last heartbeat | Timestamp of the most recent report |
| Boot mode | `agent` (normal), `deploy` (image being installed), `rollback` (being rolled back), `rescue` (diagnostic) |

### Filtering and searching

- **Text search** at the top: searches hostname, MAC, IP, serial number.
- **Status filter**: chip bar above the table — click to filter accordingly (the dashboard status bar links here).
- **Group filter**: dropdown at the top right.
- **Column sorting**: click a column header.

### Bulk actions

Select multiple clients via checkbox → actions at the top of the bar:

- **Assign group**
- **Plan rollout** — directly with these clients as targets
- **Reboot** — via agent
- **Rollback** — to the previous version
- **Delete** — removes from the database (the physical client remains)

## Client detail

Clicking a row opens the detail view with tabs:

### Tab: Overview

- Hardware summary (CPU, RAM, disk, manufacturer)
- Network (current IP, MAC, VPN IP, outbound IP)
- Agent info (version, uptime, boot counter)
- Installed clone with a link to the Cloning view
- Purchase date / warranty months / invoice number / supplier (for warranty-claim research)

### Tab: Actions

- **Start rollout** — single deployment to this client
- **Rollback** — revert to the predecessor clone
- **Reboot / shutdown**
- **Request rescue boot** — enters diagnostic mode on next reboot
- **Remove from inventory**

### Tab: History

All events for this client: heartbeats, updates, rollouts, agent versions, errors. Sorted chronologically, CSV export available.

### Tab: Remote

See the [Remote access](#remote-access) section below.

### Tab: Tasks

All background jobs targeted at this client (updates, playbooks, captures) with their status.

## Creating a new client

In practice clients appear **automatically** on the first heartbeat — a PXE-booted device that checks in is added to the list. Manual creation via **"+ Add client"** is only needed when a client should be reserved in advance (e.g. its MAC and desired group are known before hardware arrives).

Step-by-step: see [workflows/first-client.md](workflows/first-client.md).

## CSV import / export

For bulk creation or backup purposes.

### Export

- **Export CSV** in the list action bar
- File contains all fields including group, version, heartbeat
- UTF-8, semicolon-separated (Excel-compatible)

### Import

- **Import CSV** → select file
- ThinForge validates the schema and shows a preview
- Conflicts (MAC already present) are flagged — options: skip, update, cancel
- After confirmation clients are created/updated

**CSV columns (minimum):**

```
mac_address;gruppe_name;inventarnummer;raum;benutzer;kaufdatum;garantiezeit_monate;rechnungsnummer;lieferant
```

Only `mac_address` is required. Further hardware fields (serial number, CPU, model, etc.) are optional; an exported CSV can be re-imported as-is. See [client-csv-import-export.md](../../docs/client-csv-import-export.md) for the full column reference and supported header aliases.

## Boot modes

Every client has a **boot mode** controlling what it does on its next start. The mode is transmitted to the client via heartbeat and automatically reset to `agent` after execution.

| Mode | Purpose |
|------|---------|
| `agent` | Normal operation — OS starts, agent checks in, everything as usual |
| `deploy` | On next reboot, a clone is installed (in the background via the agent, or via PXE deploy boot) |
| `rollback` | On next reboot, the previous version is restored |
| `rescue` | Client boots into a minimal recovery environment (manual diagnostics) |

The mode can be set from the client detail page or via a rollout.

## VPN status

When a client is connected via WireGuard VPN, a small chip next to the status dot shows the VPN state: `connected`, `stale`, `error`. In the client detail view (Overview tab) a VPN section includes traffic statistics (sent/received, last handshake). See also [07 — Network → VPN](07-network.md#vpn).

## Remote access

Three access methods — choose by use case and permissions:

### Terminal (Web SSH)

- **"Terminal" button** on the client detail page
- Opens an in-browser shell via WebSocket + SSH
- Uses the ThinForge provisioning key (no password prompt)
- Permissions: operator or admin
- Only works when the client is online and the SSH port is reachable (LAN or VPN)

**Typical tasks:** check a log file, verify a mount point, manually restart the agent.

### Remote desktop (noVNC)

- **"Remote desktop" button** on the client detail page
- Starts a proxy container on the server that fetches X11 from the client via SSH and displays it via noVNC in the browser
- Client must be actively used (logged-in user desktop) — not suitable for headless boxes
- Input (mouse, keyboard) is replayed via xdotool
- The connection stays open as long as the browser tab is open; closing stops the proxy container
- Permissions: admin or operator with additional "Remote desktop" permission

**Typical tasks:** end-user support ("I see a red border"), check GUI-level settings.

### Agent commands

Some actions (rollout, reboot, rollback) are not executed by remote login but as a **command to the agent**. The agent picks them up during heartbeat and runs them. This path always works — even without SSH reachability, e.g. when the client is behind NAT and only heartbeats leave the site.

## Common problems

- **Client does not appear in the list after PXE boot** → First check DHCP leases (backend logs) whether the device got an IP. Then verify the provisioning script can reach the server via `get_file`. The Tools ISO may be outdated → rebuild in [05 — Cloning](05-cloning.md).
- **"Offline" although the client is running** → agent service status (`systemctl status thinforge-agent` via the Terminal). Common cause: wrong server URL, or the TLS certificate was rotated but the agent does not accept it.
- **Terminal/remote desktop does not open** → SSH reachability (firewall? VPN up?). Redeploy the provisioning key from [09 — Settings → Signing Keys](09-settings.md).

## Next steps

- [04 — Groups](04-groups.md) — organise clients
- [06 — Rollouts](06-rollouts.md) — distribute updates
- [workflows/first-client.md](workflows/first-client.md) — onboard a new client from scratch
