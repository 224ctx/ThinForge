# 2 — Dashboard

The dashboard is the landing view after login. It gives a quick overview of system state, the active client fleet, and running activity. Cards can be shown/hidden and reordered individually (cog icon, top right).

Next to the cog there is a **Refresh** button and a search field: **Enter** opens the client list with the search term. While a maintenance window is active, a notice with its name and end time sits above the cards.

## Cards

### Key figures

Four numbers about the active fleet — clients in storage are not counted here, in the status bar, in the alerts or in the system health card: **Total Clients** (with "of which N in stock"), **Online**, **Warranty Expiring** (within the configured warranty pre-warning, default 30 days — [09 — Settings → Alerts](09-settings.md#tab-alerts); today included, the warranty end day is still covered; the card shows the period, until the update of 2026-10-03 it was a fixed 30 days) and **Warranty Already Expired** (from the day after; until the update of 2026-10-01 the end day itself already counted as expired). If one of the last two is above 0, its card is shaded. The former **Error** card is gone since the update of 2026-10-01: nothing ever set the client status "error", so it always showed 0. Errors show up on tasks, deployments and the VPN state.

### Services

The **Services** card shows the status of all Docker containers. Two numbers are prominent:

- **X active** (green) — running containers like backend, database, VPN, frontend
- **Y inactive** (red when > 0) — services unexpectedly not running

A container that is intentionally on-demand (`cloning-vm`, `cloner`, multicast sender, BitTorrent seeder) does **not** appear as a warning as long as it is stopped or was never created. Any other state (e.g. `restarting`, `paused`) is reported.

Below, failed services are listed by name — they can be started directly from the card with a single button click (admins only).

Detail view via the arrow: Settings → Services ([09](09-settings.md#tab-services)).

### Client status bar

Bar showing distribution by status:

| Status | Color | Meaning |
|--------|--------|---------|
| Online | green | Last heartbeat < 5 min — via LAN or VPN |
| Offline | gray | No heartbeat |
| Cloning | orange | Client is currently installing an image |

The bar is a static visualization. Only the Groups link and the availability report (report icon) are clickable; filter the client list via its own status dropdown.

### Deployments

The **Active Deployments** card shows up to three open clone deployments (scheduled or active): clone name, group ("Individual clients" for hand-picked targets), status — for scheduled ones the time in the server's time zone —, a progress bar (done of all clients) and the number of failed clients. **View All** opens **Cloning → Deployments** ([06](06-rollouts.md)), the report icon the deployments report. Without an open deployment it reads "No active deployments". (Until 2026-10-01 the card was "Active Rollouts" and showed the staged rollouts; that feature has been removed.)

### System health

The **Fleet Health** card lists compliance issues: clients without a group, without an image, or with an expired warranty. Without findings it reads "All clients compliant"; if the report cannot be loaded, "Compliance report unavailable". The report button opens the compliance report.

### Alerts

The **Active Alerts** card shows open and acknowledged incidents of individual clients — e.g. a client offline for too long, CPU, RAM or disk of a client above the threshold, warranty expiring, installed version mismatch, or a changed MAC address. Each row (the five newest) shows client, alert, status, details and since. Clicking opens the client detail view; **View All** (only shown while alerts are pending) takes you to Settings → Alerts, where incidents can be acknowledged and resolved. The report icon opens the incidents report. Without alerts it reads "No active alerts".

### Recent Clients

The **Recently Active Clients** card lists the five most recently seen devices with hostname, MAC address, status, room and "since" — helpful after a large deployment or a branch-office boot wave, to see which clients have already come back. Clicking opens the device, **View All** the client list.

### Disk Usage

The **Server Storage** card shows the usage of the disk that holds the ThinForge data folder (clones, deltas, captures, ISOs) — used, total and free in GB. At 75 % the bar turns orange as a warning, and red at 90 %; time to prune old content or add storage. The report icon opens the storage report.

### Activity

Running and failed tasks as numbers, each linking to the tasks page ([08](08-tasks-logs.md#tasks)); plus pending enrollments linking to the client list. With nothing pending it reads "No pending activity". The report icon opens the tasks report.

### Subscription

Visible to admins only: subscription status (Active, Expired, No Subscription), remaining term and the VPN client seats in use. The arrow leads to Settings → Subscription, the report icon to the subscription report.

## Customization

The **cog icon** at the top right opens "Customize Dashboard":

- **Show/hide** individual cards
- **Reorder** via drag & drop
- **Width** per card (1/4 up to full width)
- **Reset** to factory defaults

Settings are stored locally in the browser — so the customization applies per device and browser, not across accounts.

## Tips for daily use

- **"inactive" counter red?** Check the services detail view first before panicking — it shows status, health, exit code and logs; often a service is just restarting (`restarting`).
- **Client status bar suddenly showing many "Offline"?** Usually a central network problem (VPN instance or relay unreachable, DHCP lease hiccups). Check logs ([08](08-tasks-logs.md#logs)); for VPN clients also the **VPN connection** card in the VPN menu ([13](13-vpn.md)).
- **Deployments card shows "Active" but nothing moves?** The cards reload roughly every 30 seconds (the subscription card only when the page is opened), the refresh button at the top immediately. If progress still does not move, the deployment itself is stuck — see **Cloning → Deployments** ([06](06-rollouts.md#progress-and-troubleshooting)).
