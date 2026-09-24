# 3 — Clients

A **client** in ThinForge is a physical thin PC with an installed agent that regularly contacts the server via heartbeat. All management actions — image update, rollback, remote access, group assignment — act on client objects.

> **Recommended system:** For the thin clients, Debian is the preferred choice — installed as a minimal system with XFCE as the graphical desktop. In principle, any Linux distribution works.

## Clients list

Menu left, **Clients**. The table shows all registered devices and reloads every 30 seconds. The other tabs of the view are covered in [Other tabs](#other-tabs).

### Columns

| Column | Content |
|--------|---------|
| Inventory Number | Your own inventory number; the list is initially sorted by it |
| Hostname | Computer name `TF-<MAC>` — assigned by ThinForge on creation |
| MAC Address | Primary NIC |
| Status | Online (green; when the path is known "Online (LAN)" or "Online (VPN)" with a shield icon) / Offline (grey) / Cloning (orange) / Error (red) |
| Current IP | The address the last heartbeat came from (LAN or VPN overlay) |
| Installed Image | Currently-installed clone (`v2026.06.22-004`, …); without a version, the image name with a link to the Cloning view |
| User, Room | Freely maintained details |
| Groups | Assigned group ([04](04-groups.md)) |

Clients in **storage** appear dimmed with an orange chip. The status also turns red when a device has not been seen for more than three weeks or when the server rejects its heartbeat — the chip then reads **"Install token detected!"** and its tooltip gives the reason. Clicking an online or offline chip pings the device to check whether it is reachable right now.

At the end of each row: **Edit** (opens the detail view), **Delete**, **Re-issue token** and **Reset to install token** (only active with "Install token detected!"; the client re-enrolls on its next heartbeat). Deleting and both token actions are admin tasks.

### Filtering and searching

- **Search field** at the top: filters the displayed list across the table columns (e.g. hostname, MAC address, inventory number, user, room, group); a search term from the dashboard is carried over.
- **Status filter**: dropdown in the filter row (Online, Offline, Cloning, Error).
- **Group filter**: "Groups" dropdown in the filter row; next to it the "Connection" filter and the refresh button.
- **Column sorting**: click a column header.

### Bulk actions

Select multiple clients via checkbox → actions at the top of the bar:

- **Assign Group** — pick a group, then **Apply**
- **Actions** menu:
  - **Wake Up (WoL)**, **Reboot**, **Shutdown** — reboot and shutdown are sent by the server via SSH
  - **Ping Check** — checks whether the selected devices are reachable
  - **Re-issue token** — renews the heartbeat tokens; each device picks up its new token on its next heartbeat (admins only). If it fails for a device, a warning names it
  - **Delete** — removes the client from management (the physical PC remains); it does not come back on its own and must be re-created manually using its MAC address to manage it again (admins only). If a device cannot be deleted, a warning names it

## Client detail

Clicking a row opens the detail view. It has no tabs but three areas; the page reloads every 15 seconds, the refresh button at the top immediately.

### Client details

- Hostname and MAC address (read-only)
- Inventory number (must be unique, checked while typing), room, user, group
- **Storage** — device in storage: no alerts, not counted in key figures and reports
- Installed version or image and "Installed At" (read-only)
- Purchase date / warranty months with the computed warranty end / invoice number / supplier (for warranty-claim research)
- **Save** only sends the changed fields — whatever someone else changed meanwhile in another field is kept

### Actions

- **Wake Up (WoL)**, **Reboot**, **Shutdown**
- **Open Terminal** and **Remote Desktop** — only while the client is online, see [Remote access](#remote-access)
- **Delete** (admins only)

### System information

Last seen plus CPU, RAM and disk usage with bars (CPU and RAM orange from 60 %, red from 80 %; disk orange from 75 %, red from 90 %).

The jobs of a device are listed under **Tasks** using the client filter ([08](08-tasks-logs.md)).

## Creating a new client

Clients are created **manually** — there is no automatic registration of new devices. Use **"+ Register Client"** to enter the device's **MAC address** (required) and, optionally, inventory number, room, user, purchase and warranty details, group and storage. Only a created device is accepted by the server; heartbeats from unknown MAC addresses are rejected. For bulk creation, use the CSV import (see below).

Step-by-step: see [workflows/first-client.md](workflows/first-client.md).

## CSV import / export

For bulk creation or backup purposes.

### Export

- **Export CSV** in the action bar above the list
- File `clients.csv` with hostname, MAC address, status, user, room, group, installed image, inventory number, invoice number and supplier — it exports the clients currently loaded, so with a status, connection or group filter set only those
- UTF-8 with BOM, comma-separated, every field quoted; column headers in the interface language

### Import

- **Import CSV** → paste the CSV content into the text field (no file upload); an exported `clients.csv` can be pasted as-is
- ThinForge recognises the header row (German and English column names, including those of the export) and shows a preview; rows with an invalid MAC are flagged and skipped
- If groups are missing, a dialog asks whether to create them
- After **"Import N client(s)"** the server creates the new clients. If a MAC already exists, nothing is created — only a given group is applied to the existing device. Rows with an inventory number already in use are skipped and reported

**CSV columns (minimum):**

```
mac_address,gruppe_name,inventarnummer,raum,benutzer,kaufdatum,garantiezeit_monate,rechnungsnummer,lieferant
```

Only `mac_address` is required; `kaufdatum` as `YYYY-MM-DD`. Other columns (such as hostname, status or installed image from the export) are ignored, so an exported CSV can be re-imported as-is. Without a recognisable header row the fixed order `mac_address, inventarnummer, raum, benutzer, kaufdatum, garantiezeit_monate, rechnungsnummer, lieferant` applies.

## Boot modes

Every client has a **boot mode** controlling what it does on its next PXE start. The mode lives on the server as a PXE configuration; after a finished deployment or capture it is automatically set back to local boot.

| Mode | Purpose |
|------|---------|
| Local | Normal operation — the client boots from its local disk |
| Deploy | On next start, an image is installed |
| Capture | On next start, the device's disk is captured as an image |
| No Config | No boot configuration is set — the client just boots normally |

The mode is shown and set under **Network → PXE Boot** (admins only): set local or capture, delete the configuration ([07](07-network.md#tab-pxe-boot)). Deploy is set by ThinForge itself as soon as a deployment or rollout arms the client.

## VPN status

When a client's heartbeat arrives over the VPN, the list shows its status as "Online (VPN)" with a shield icon; the **Connection** filter separates LAN from VPN clients. That is all this view shows: the actual VPN state of a device (activated, connected, last handshake, connection via relay) lives in the **Clients** tab of the **VPN** menu; there are no traffic statistics.

## Remote access

Three access methods — choose by use case and permissions:

### Terminal (Web SSH)

- **"Open Terminal" button** on the client detail page
- Opens an in-browser shell (as `root`) via WebSocket + SSH
- Uses the ThinForge provisioning key (no password prompt)
- Permissions: operator or admin
- Only works when the client is online and the SSH port is reachable (LAN or VPN)

**Typical tasks:** check a log file, verify a mount point, manually restart the agent.

### Remote desktop

- **"Remote Desktop" button** on the client detail page
- The server opens an SSH tunnel to the client, starts `x11vnc` on display `:0` there and passes the session through the Guacamole service (`guacd`) into the browser; mouse and keyboard take the same way back
- The client needs a running graphical session on `:0` (login screen or desktop) — not suitable for headless boxes
- On the client a notice window "Remote session active" is shown while the session runs; when it ends, the server stops `x11vnc` again
- The quality level (DSL, VDSL, LAN) can be switched in the dialog; the default, idle timeout and the number of concurrent sessions per client are under **Settings → Remote Desktop**
- Permissions: operator or admin

**Typical tasks:** end-user support ("I see a red border"), check GUI-level settings.

### Agent commands

Delta updates and rollbacks do not run over a remote login: the **agent** picks them up with its heartbeat and executes them. This path works even without SSH reachability, e.g. when the client is behind NAT and only heartbeats leave the site. Reboot and shutdown, on the other hand, are sent by the server via SSH — the device must be reachable for that.

## Other tabs

- **Warranty** — cards for valid, soon (90 days) expiring and expired warranties, filters and a table with the warranty end; **Export CSV** writes `inventar.csv`.
- **Agent** — the server's agent binary: build, upload, sign and distribute to the fleet via SSH.
- **Certificates** — trust certificates the server distributes to all clients or to one group (admins only).

## Common problems

- **Client stays offline after the deployment** → First check under **Network → DHCP / DNSMASQ → Leases** whether the device got an IP (only registered MACs get one), then the status in the deployment. If the golden image was set up with an outdated Tools ISO, the agent lacks matching tokens or certificates → set the image up again with the current ISO ([05 — Cloning](05-cloning.md)).
- **"Offline" although the client is running** → agent service status (`systemctl status thinforge-agent` directly on the device — the terminal in the interface is locked while "Offline"). Common cause: wrong server URL, or the TLS certificate was rotated but the agent does not accept it. If the list shows **"Install token detected!"**, the server rejects the heartbeat → **Reset to install token** (admin).
- **Terminal/remote desktop does not open** → SSH reachability (firewall? VPN up?). Check or rotate the provisioning key under **Settings → Security → SSH Access** — online clients pick up a new key with their next heartbeat ([09 — Settings](09-settings.md)).
- **A device shows the current agent version but behaves like an old one** → The agent version in the list is **what the device reports**; the server cannot verify it. **Update all** (tab **Agent**) with "All clients" or "Group" only picks devices whose reported version differs — a device that merely reports the current version is left out. If in doubt, handle the device explicitly: **Reinstall** (reinstalls regardless of the reported version) or pick it under **Select clients** in the dialog.

## Next steps

- [04 — Groups](04-groups.md) — organise clients
- [06 — Rollouts](06-rollouts.md) — distribute updates
- [workflows/first-client.md](workflows/first-client.md) — onboard a new client from scratch
