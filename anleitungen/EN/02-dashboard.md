# 2 — Dashboard

The dashboard is the landing view after login. It gives a quick overview of system state, the active client fleet, and running activity. Cards can be shown/hidden and reordered individually (cog icon, top right).

## Cards

### Services

Shows the status of all Docker containers. Two numbers are prominent:

- **X active** (green) — always-on services like backend, database, VPN, frontend
- **Y inactive** (red when > 0) — services unexpectedly not running

A container that is intentionally on-demand (`cloning-vm`, `cloner`) does **not** appear as a warning as long as it is in its expected idle state. Only real problem states (`restarting`, `paused`) are reported.

Below, failed services are listed by name — they can be restarted directly from the card with a single button click.

Detail view: Settings → Services ([09](09-settings.md#services)).

### Client status bar

Bar showing distribution by status:

| Status | Colour | Meaning |
|--------|--------|---------|
| Online | green | Last heartbeat < 5 min |
| VPN sync | light green | Online via VPN, configuration in sync |
| Offline | grey | No heartbeat |
| Cloning | orange | Client is currently installing an image |
| Error | red | Agent reports error state |

The bar is a static visualisation. Only the Groups link and the availability report (report icon) are clickable; filter the client list via its own status dropdown.

### Rollouts

Active (and paused) rollouts. Shows per rollout: image and progress (x/y clients). Clicking jumps to the rollout detail page ([06](06-rollouts.md)).

### System health

Lists compliance issues: clients without a group, without an image, or with an expired warranty. The report button opens the compliance report.

### Alerts

Open incidents — e.g. a client missing heartbeats several times in a row, disk capacity critical, or a failed update rollout. Each row shows client, condition, status and since. Clicking opens the client detail view; **Show all** takes you to Settings → Alerts, where incidents can be acknowledged and resolved.

### Recent Clients

Devices that most recently became active — helpful after a large deployment or a branch-office boot wave, to see which clients have already come back.

### Disk Usage

Progress bar for the ThinForge data folder (clones, deltas, captures, ISOs). At ≥ 75 % the bar turns amber as a warning, and red at ≥ 90 %; time to prune old content or add storage.

### Running Tasks

Number of running background jobs (captures, builds, deployments). Click takes you to the tasks page ([08](08-tasks-logs.md#tasks)).

## Customisation

The **cog icon** at the top right opens "Dashboard settings":

- **Show/hide** individual cards
- **Reorder** via drag & drop
- **Reset** to factory defaults

Settings are stored locally in the browser — so the customisation applies per device and browser, not across accounts.

## Tips for daily use

- **"Inactive" card yellow/red?** Check the services detail view first before panicking — `unhealthy` often has trivial causes (still in `start_period`, right after a reboot, etc.).
- **Client status bar suddenly showing many "Offline"?** Usually a central network problem (VPN gateway down, DHCP lease hiccups). Check logs ([08](08-tasks-logs.md#logs)).
- **Rollouts card shows "in progress" but nothing moves?** The status, alert and disk cards refresh roughly every 30 seconds; rollouts, services, system health and recent clients, however, only update on reload. For a seemingly stuck rollout, reload the browser or use the refresh button on the rollout detail page.
