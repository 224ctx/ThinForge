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
| Status | Online (green; when the path is known "Online (LAN)" or "Online (VPN)" with a shield icon) / Offline (gray) / Cloning (orange) — there has been no "Error" status since the update of 2026-10-01 |
| Current IP | The address the last heartbeat came from (LAN or VPN overlay) |
| Installed Version | Currently-installed clone (`v2026.06.22-004`, …); without a version, the image name with a link to the Cloning view |
| User, Room | Freely maintained details |
| VPN | Shield icon when VPN is enabled for the device (access issued, takes a subscription seat); "–" otherwise. Whether the tunnel is up right now is shown in the VPN tab |
| Groups | Assigned group ([04](04-groups.md)) |

Clients in **storage** appear dimmed with an orange chip. The status also turns red when a device has not been seen for more than three weeks or when the server rejects its heartbeat — the chip then reads **"Install token detected!"** if the device reported with the install token, or **"Unknown token!"** if it sends a token the server does not know at all (since the update of 2026-10-08; before that it also said "Install token detected!" then). The tooltip gives the reason in the interface language, with the address the device came from where that matters. Since the update of 2026-10-08, ThinForge also opens the incident **"Heartbeat rejected"** for such a rejection and notifies through the configured channels ([09 — Settings](09-settings.md#tab-alerts)). Clicking an online or offline chip pings the device to check whether it is reachable right now.

Since the update of 2026-10-21 two more chips appear next to the status: **“Integrity!”** (red) when the device's agent rejected or repaired something, or the server found a difference while comparing the device with its own state — the tooltip names the latest open agent event, the details are in the detail view ([Agent events](#agent-events)) —, and **“Agent silent”** (yellow) when the device answers ping but sends no heartbeat: the agent is not running or cannot reach the server. The status stays “Offline”, and pinging by click reports a silent device as reachable but does not set it to “Online” — only the next heartbeat does. All roles see both chips.

At the end of each row: **Edit** (opens the detail view), **Delete**, **Re-issue token** and **Reset to install token** (only active while the heartbeat is rejected, i.e. with "Install token detected!" or "Unknown token!"; the client re-enrolls on its next heartbeat). If the chip says **"Unknown token!"**, the device reports with a token the server does not know (for example after an aborted reimage) — then the reset only helps once the device sends the install token again; usually that means reimaging the device. Deleting and both token actions are admin tasks: since the update of 2026-10-08 the interface shows them to admins only — in the row, in the bulk actions of the selection and (Delete) in the detail view.

### Filtering and searching

- **Search field** at the top: filters the displayed list across the table columns (e.g. hostname, MAC address, inventory number, user, room, group); a search term from the dashboard is carried over.
- **Status filter**: dropdown in the filter row (Online, Offline, Cloning).
- **Group filter**: "Groups" dropdown in the filter row, with **No group** as the first entry; next to it the filters "Connection" (how the device is coming in right now) and "VPN enabled" (yes/no) and the refresh button. "VPN enabled: Yes" together with "No group" shows the VPN devices whose group was deleted.
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

Clicking a row opens the detail view. It has no tabs but three areas — for admins and operators, since the update of 2026-10-21, with the [Agent events](#agent-events) card below them; the header shows the same “Integrity!” and “Agent silent” chips next to the status as the list. The page reloads every 15 seconds, the refresh button at the top immediately. If the server briefly does not answer (for example during a restart), the next reload brings the page back on its own. If the device no longer exists (deleted, or an old link), the header reads “Client not found” with a link to the list, and the page stops reloading.

### Client details

- Hostname and MAC address (read-only; an admin accepts a new MAC address, see [New network card](#new-network-card))
- Inventory number (must be unique, checked while typing), room, user, group
- **Storage** — device in storage: no alerts, not counted in key figures and reports
- Installed version or image and "Installed At" (read-only)
- Purchase date / warranty months with the computed warranty end / invoice number / supplier (for warranty-claim research)
- **Save** only sends the changed fields — whatever someone else changed meanwhile in another field is kept

### Actions

- **Wake Up (WoL)**, **Reboot**, **Shutdown** — reboot and shutdown only report "sent" when the command reached the device via SSH. If the device is unreachable, rejects the login, the time limit runs out or the command fails, an error message names the reason (since the update of 2026-09-30; before that "sent" was shown in these cases too)
- **Open Terminal** and **Remote Desktop** — only while the client is online, see [Remote access](#remote-access)
- **Delete** (admins only)

### New network card

Since the update of 2026-10-08: when a device gets a new network card, it keeps reporting to the server — but with a MAC address other than the registered one. The detail view then shows the notice **"The client reports a new MAC address …"** at the top with the reported and the registered address, and within five minutes **Settings → Alerts** lists the incident **"MAC Address Changed"** with both addresses — notified through the configured channels ([09 — Settings](09-settings.md#tab-alerts)). This works for devices that have reported to the server before; a device that never reported is still rejected with an unknown MAC address.

An admin accepts the new address with **Accept MAC** — on the notice or on the incident. The confirmation shows both addresses and the consequences:

- the DHCP reservation (same IP address) moves to the new MAC address,
- the PXE boot files apply to the new card, those of the old one are removed,
- Wake-on-LAN wakes the new card from now on,
- the **hostname stays**.

The incident is resolved afterwards. Nothing is accepted while the device is part of a running deployment or armed for a capture (wait for it or cancel it first), or if the address is already registered for another device — the message then names that device (for example because the disk of one device sits in the other). If the DHCP reservation or the PXE files could not be switched, the message says so; catch up under **Network → DHCP / DNSMASQ → Reload Config** or **Network → PXE Boot → Sync All**. If the old card still holds a valid DHCP lease on the reserved address, the new card only gets it once that lease has expired and receives an address from the range until then.

If the old card is put back, the notice disappears on its own and the incident resolves with the next check (within five minutes).

If the client reports no new address but its agent reports that the hostname stored on the client comes from another network card (for example a disk taken from another client, or a card replaced before the client was registered), the detail view shows the notice **"The agent reports that the hostname stored on the client … comes from a network card other than the registered one …"**, and the incident "MAC Address Changed" is open as well. If that state is intended, an admin confirms the registered address with **Confirm MAC**: nothing is switched, the incident resolves, and the same state opens no new one. If the client later reports a different address or a different stored hostname, a new incident opens.

### System information

Last seen plus CPU, RAM and disk usage with bars (CPU and RAM orange above 60 %, red above 80 %; disk orange above 75 %, red above 90 %).

The jobs of a device are listed under **Tasks** using the client filter ([08](08-tasks-logs.md)).

### Agent events

Since the update of 2026-10-21 (agent 2.27.0), the agent tells the server what it rejected or repaired on the device: an agent update, a script, a server certificate, a signing or SSH key with an invalid signature, a missing trust anchor, a modified systemd unit, a delta that could not be applied at shutdown. In addition, the server compares the device's agent version, agent binary and signing key with its own state on every heartbeat. The **“Agent events”** card below the areas of the detail view lists both (for admins and operators; viewers only see the chips):

- Columns **Time (device)**, **Received**, **Event** (in the interface language; code and details in the tooltip), **Count** (how often it was reported, “Last reported” in the tooltip), **Source** (device or server check) and **Closed** (by whom and when, otherwise “open”).
- Filter **Open** (default) and **All**; the refresh icon reloads.
- A row with a crossed-out bell opens no incident: the unit was repaired right after a reimage, a rollback or an agent update — that is the expected sequence.

Every other open row keeps the “Integrity!” chip and the **“Agent Integrity”** incident open ([09 — Settings](09-settings.md#tab-alerts)). **Acknowledge** (per row) and **Acknowledge all** are admin tasks and ask for confirmation first:

- A **one-time event** (for example a repaired unit, a rejected script or delta) is closed by this. If the same thing happens again later, it appears as a new row.
- A **persisting condition** (for example a rejected certificate, a differing agent binary, or an agent version that is still the old one 30 minutes after an agent update) stays open as long as the device reports it; acknowledging only stops the notifications about it. Once the cause is fixed, the server closes the row by itself (“no longer reported”), and likewise when it ships a new agent binary or a new signing key itself (“server's expected state changed”).

Acknowledging sets the “Agent Integrity” incident to acknowledged; once nothing is open any more, the next check resolves it (after five minutes at the latest). If a new row appears after the acknowledgement, the incident reports again right away. Every acknowledgement that closes an event or acknowledges the incident is recorded in the audit log (“Agent events acknowledged”, [08 — Tasks & Logs](08-tasks-logs.md)). Closed rows are kept as long as resolved incidents ([09 — Settings](09-settings.md#card-general-settings)) and deleted afterwards.

What these reports can do: they are information from the device itself or a comparison with it. They reveal errors, half-finished updates and interventions that are not hidden (someone edits the unit, stops the agent). An attacker with full rights on the device can replace the agent and keep it quiet — that only shows up as “Agent silent” if the device keeps answering ping.

## Creating a new client

Clients are created **manually** — there is no automatic registration of new devices. Use **"+ Register Client"** to enter the device's **MAC address** (required) and, optionally, inventory number, room, user, purchase and warranty details, group and storage. Only a created device is accepted by the server; heartbeats from unknown MAC addresses are rejected. For bulk creation, use the CSV import (see below).

Step-by-step: see [workflows/first-client.md](workflows/first-client.md).

## CSV import / export

For bulk creation or backup purposes.

### Export

- **Export CSV** in the action bar above the list
- File `clients.csv` with hostname, MAC address, status, user, room, group, installed version, inventory number, invoice number and supplier — it exports the clients currently loaded, so with a status, connection, "VPN enabled" or group filter set (including "No group") only those; the text search only affects the display, not the export
- UTF-8 with BOM, comma-separated, every field quoted; column headers in the interface language

### Import

- **Import CSV** → paste the CSV content into the text field (no file upload); an exported `clients.csv` can be pasted as-is
- ThinForge recognizes the header row (German and English column names, including those of the export) and shows a preview; rows with an invalid MAC are flagged and skipped
- If groups are missing, a dialog asks whether to create them
- After **"Import N client(s)"** the server creates the new clients. If a MAC already exists, nothing is created — only a given group is applied to the existing device. Rows with an inventory number already in use are skipped and reported
- The result states how many clients were created, updated (new group) and skipped. If there were row errors, the dialog stays open and lists every row that was not imported with its MAC address and the reason in the interface language (since the update of 2026-09-30; before that it always closed and the errors were not visible — and until the update of 2026-10-01 the reasons were partly German, partly English). A device whose group was already correct counts as skipped, not as updated

**CSV columns (minimum):**

```
mac_address,gruppe_name,inventarnummer,raum,benutzer,kaufdatum,garantiezeit_monate,rechnungsnummer,lieferant
```

Only `mac_address` is required; `kaufdatum` as `YYYY-MM-DD`. Other columns (such as hostname, status or installed version from the export) are ignored, so an exported CSV can be re-imported as-is. Without a recognizable header row the fixed order `mac_address, inventarnummer, raum, benutzer, kaufdatum, garantiezeit_monate, rechnungsnummer, lieferant` applies.

## Boot modes

Every client has a **boot mode** controlling what it does on its next PXE start. The mode lives on the server as a PXE configuration; after a finished deployment or capture it is automatically set back to local boot.

| Mode | Purpose |
|------|---------|
| Local | Normal operation — the client boots from its local disk |
| Deploy | On next start, an image is installed; the list names the method: "Clone deployment" (unicast), "Multicast deployment" or "BitTorrent deployment" — "Deploy" only remains on older boot configurations |
| Capture | On next start, the device's disk is captured as an image |
| No Config | No boot configuration is set — the client just boots normally |

The mode is shown under **Network → PXE Boot**; only admins can change it: set local or capture, delete the configuration ([07](07-network.md#tab-pxe-boot)). Deploy is set by ThinForge itself as soon as a deployment arms the client.

## VPN status

When a client's heartbeat arrives over the VPN, the list shows its status as "Online (VPN)" with a shield icon; the **Connection** filter separates LAN from VPN clients. When a device goes offline — no more heartbeat, end or cancellation of a clone deployment or a capture — the connection path goes with it (since the update of 2026-10-10): "Offline" is shown without a shield, and the **Connection** filter finds the device again only once it reports back. That is all this view shows: the actual VPN state of a device (activated, connected, last handshake, connection via relay) lives in the **Clients** tab of the **VPN** menu ([13 — VPN](13-vpn.md)); there are no traffic statistics.

## Remote access

Three access methods — choose by use case and permissions:

### Terminal (Web SSH)

- **"Open Terminal" button** on the client detail page
- Opens an in-browser shell (as `root`) via WebSocket + SSH
- Uses the ThinForge provisioning key (no password prompt)
- Permissions: operator or admin
- Only works when the client is online and the SSH port is reachable (LAN or VPN)
- The start and end of every session appear in the audit log (account, sender IP, device, duration; since the update of 2026-10-09). ThinForge does not record what is typed or printed in the terminal

**Typical tasks:** check a log file, verify a mount point, manually restart the agent.

### Remote desktop

- **"Remote Desktop" button** on the client detail page
- The server opens an SSH tunnel to the client, starts `x11vnc` on display `:0` there and passes the session through the Guacamole service (`guacd`) into the browser; mouse and keyboard take the same way back
- The client needs a running graphical session on `:0` (login screen or desktop) — not suitable for headless boxes
- On the client a notice window "Remote session active" is shown while the session runs; when it ends, the server stops `x11vnc` again
- The start and end of every session appear in the audit log (account, sender IP, device, quality level, duration; since the update of 2026-10-09). ThinForge does not record the screen
- The quality level (DSL, VDSL, LAN) can be switched in the dialog; the default, idle timeout and the number of concurrent sessions per client are under **Settings → Remote Desktop**. The session starts with that default; if it cannot be retrieved when the dialog opens, no level is highlighted and a yellow notice names the reason — the server still applies its default (since the update of 2026-09-30; before that the session silently started with VDSL in this case)
- Permissions: operator or admin

**Typical tasks:** end-user support ("I see a red border"), check GUI-level settings.

### Agent commands

Delta updates and rollbacks do not run over a remote login: the **agent** picks them up with its heartbeat and executes them. This path works even without SSH reachability, e.g. when the client is behind NAT and only heartbeats leave the site. Reboot and shutdown, on the other hand, are sent by the server via SSH — the device must be reachable for that.

## Other tabs

- **Warranty** — cards for valid, soon (within the configured warranty pre-warning, default 30 days, today included — Settings → Alerts; until the update of 2026-10-03 a fixed 30 days) expiring and expired warranties — the warranty end day still counts as covered, as on the dashboard and in the reports (since the update of 2026-10-01; before that 90 days, and the end day already counted as expired) — filters and a table with the warranty end; **Export CSV** writes `inventar.csv`.
- **Agent** — the server's agent binary: build, upload, sign and distribute to the fleet via SSH. Admins and operators see the tab; **Build now**, **Upload binary**, **Sign** and saving the heartbeat interval are admin tasks (hidden or read-only for operators — signing and the interval since the update of 2026-10-08, building and uploading since the update of 2026-10-21, because both sign the binary with the fleet key and publish it as the target state for every device).
- **Certificates** — trust certificates the server distributes to all clients or to one group (admins only).

## Common problems

- **Client stays offline after the deployment** → First check under **Network → DHCP / DNSMASQ → Leases** whether the device got an IP (only registered MACs get one), then the status in the deployment. If the golden image was set up with an outdated Tools ISO, the agent lacks matching tokens or certificates → set the image up again with the current ISO ([05 — Cloning](05-cloning.md)).
- **"Offline" although the client is running** → agent service status (`systemctl status thinforge-agent` directly on the device — the terminal in the interface is locked while "Offline"). Common cause: wrong server URL, or the TLS certificate was rotated but the agent does not accept it. If the list shows **"Install token detected!"**, the server rejects the heartbeat → **Reset to install token** (admin). If it also shows **“Agent silent”**, the device answers ping but the agent sends no heartbeat: the service is stopped or hangs (`systemctl status thinforge-agent` and `journalctl -u thinforge-agent -n 30` on the device). A device whose heartbeat the server rejects also counts as silent here.
- **After replacing the network card, the device no longer boots via PXE or does not get its IP address** → The reservations are tied to the MAC address. In the device's detail view choose **Accept MAC** (admin), see [New network card](#new-network-card).
- **Terminal/remote desktop does not open** → SSH reachability (firewall? VPN up?). Check or rotate the provisioning key under **Settings → Security → SSH Access** — online clients pick up a new key with their next heartbeat ([12 — Security](12-security-and-cve-scan.md)).
- **“Integrity!” in the list** → Read the [Agent events](#agent-events) card in the detail view: it names what the agent rejected or repaired, or what differed in the comparison. An admin acknowledges a one-time event; a persisting condition disappears once the cause is fixed — for a differing agent binary, a differing signing key or a missing trust anchor, **Reinstall** in the **Agent** tab with the target **Select clients** usually helps (it puts the binary, `server.crt` and `signing.pub` in place again).
- **A device shows the current agent version but behaves like an old one** → The agent version in the list is **what the device reports**; the server cannot verify it. Since the update of 2026-10-21, an agent from 2.27.0 on also reports the checksum of its binary, and the server compares it with the one it ships: if it differs at the same version, “Integrity!” appears with the note about the differing agent binary — that, too, is information from the device. **Update all** (tab **Agent**) with "All clients" or "Group" only picks devices whose reported version differs — a device that merely reports the current version is left out. If in doubt, handle the device explicitly: **Reinstall** (reinstalls regardless of the reported version) or pick it under **Select clients** in the dialog.

## Next steps

- [04 — Groups](04-groups.md) — organize clients
- [06 — Rollouts](06-rollouts.md) — distribute updates
- [workflows/first-client.md](workflows/first-client.md) — onboard a new client from scratch
