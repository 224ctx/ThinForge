# 6 — Rollouts

A **rollout** is the distribution of a clone ([05](05-cloning.md)) to a set of clients. ThinForge does it via **Cloning → Deployments**: initial installation or re-clone of a group, several groups or individual clients, via unicast, multicast or BitTorrent, immediately or at a scheduled time — the full image is rewritten via PXE. A wave-based rollout (pilot group first, production after) is planned with several deployments, e.g. per group or at staggered times. The former separate "Staged Rollouts" feature was removed on 2026-10-01.

Delta updates for already-provisioned clients are distributed under **Cloning → Updates** ([workflows/deploy-update.md](workflows/deploy-update.md)), rollbacks under **Cloning → Rollback** ([workflows/client-rollback.md](workflows/client-rollback.md)).

## Deployments

**Cloning → Deployments** lists all clone deployments in a table:

| Column | Content |
|--------|---------|
| Mode | UC (unicast) / MC (multicast) / BT (BitTorrent) |
| Clone | name of the clone |
| Group | target group |
| Status | Scheduled (with time) / Active / Completed / Completed with Errors / Cancelled; for BitTorrent "Preparing…" first |
| Progress | X / Y clients done |
| Created | creation time |

Clicking the arrow of a row expands the clients with per-client status (Pending, Deploying, Done, Failed, Cancelled), BitTorrent progress and error message.

## Creating a deployment

**"New Deployment"** at the top right opens the dialog:

### Target

- **Group**, **Multiple Groups** or **Individual Clients** — only groups with clients are offered
- For groups: the action only hits the clients assigned directly to the group (no sub-groups)
- For individual clients: pick a group first, then mark clients from it

### Clone and mode

- **Select Clone** — preselected with the newest clone
- **Mode**:
  - **Unicast** — each client restores the image individually from the server via NFS. Simple, always works; with > 50 clients on the same LAN the server uplink becomes the bottleneck.
  - **Multicast** — server streams once over UDP multicast, all clients receive in parallel. Great for large LAN rollouts. LAN only, not across VPN/routed networks. Only **one** multicast deployment can be active at a time; for several groups on the same image choose **Multiple Groups**. Creating and launching a deployment with this method is operator work; saving the global **Multicast Settings** (cog icon: wait time 30–3600 s, completion timeout 30–1800 s — clients that do not report back within this timeout after the transmission has ended are marked as failed and boot locally afterwards) has been admin-only since 2026-08-31, because they affect every future deployment.
  - **BT Multi-Deploy** (default) — clients pull the clone as a torrent and share bandwidth among themselves. Good for many clients on the same LAN. Several BitTorrent deployments can run in parallel, even with different clones.
- **Post-Deploy Action** — Reboot (default), Shutdown or Nothing

### Timing

- **No schedule** — the deployment starts immediately. **"Reboot online clients now"** (on by default) reboots clients reported online into the deployment via SSH, for BitTorrent only once the seeder has published the torrents; powered-off clients start into it on their next power-on.
- **Scheduled Start** — set date and time (e.g. 23:00), meant in the server time zone ([09](09-settings.md)); the scheduler activates the deployment one minute before the scheduled time, with BitTorrent the seeder starts ten minutes earlier. A date without a time blocks creation. **"Reboot online clients at the scheduled time"** (on by default) reboots the clients reported online at that moment into the deployment via SSH as part of the activation (with BitTorrent once the torrents are published); if the deployment starts more than 15 minutes after the scheduled time — for example because the server was down — nothing is rebooted.
- **Send Wake-on-LAN at start** — available only for a **scheduled** deployment: the target devices receive a magic packet at the scheduled time, activation (PXE, NFS, DHCP) runs one minute earlier, for BitTorrent the seeder starts ten minutes earlier (PXE boot required). Without a set time the WoL option is unavailable.

### Deploy

**"Deploy"** creates the deployment. If a target client is already part of a running deployment or is armed for a capture ([05 — Captures](05-cloning.md#tab-captures)), the server refuses.

In the list, **Cancel** stops an active or scheduled deployment. Once it has ended, **Restart failed/cancelled** restarts the failed and cancelled clients, **Restart** in the expanded row restarts a single one (not for multicast) — if "Reboot online clients now" was on when the deployment was created, clients reported online reboot into the deployment via SSH right away (with BitTorrent once the torrents are published); **Delete** removes a finished deployment.

## Deployment methods compared

| | Unicast | Multicast | BitTorrent |
|---|---------|-----------|------------|
| Network | LAN only | LAN only | LAN only |
| Scale | ~50 clients | hundreds | hundreds |
| Parallel deployments | yes (server CPU limits) | **no** (only one active multicast deployment) | yes (one seeder for several torrents) |
| Missing clients | no problem | client must boot at the right moment | client can join later |
| Config needed | none | IGMP on the switch | Tracker port 6969 / seed port 6881 open |

## Progress and troubleshooting

- **Start fails with "The NFS share for the deployment could not be activated"** → `exportfs` failed in the `nfs-server` container; no device was prepared. Check the `nfs-server` service on the dashboard ([02](02-dashboard.md)) and start the deployment again. A scheduled deployment retries every minute.
- **A scheduled multicast deployment shows "Cancelled"**, every client with "Termin nicht gestartet: zur selben Zeit lief das Multicast-Deployment …" → another multicast deployment was already running at the scheduled time, and only one can run at once. Schedule the deployment again once the other one has finished.
- **Several clients stuck on `deploying`** → most likely network: firewall blocking download, NFS export unreachable, or the NFS server, multicast sender or BitTorrent seeder is not running. Check services on the dashboard ([02](02-dashboard.md)), logs ([08](08-tasks-logs.md)).
- **`failed` clients** → under **Cloning → Deployments** the expanded row shows the error message per client. Common causes: disk too small, wrong partition table, signature verification failure. Fix and roll the client out again.
- **Rollout should reach only a subset** → choose **Individual Clients** instead of a group in the deployment and pick manually. Or create a temporary "wave" group ([04](04-groups.md)) and deploy the groups one after another.

## Rollouts and VPN

The three distribution methods (unicast, multicast, BitTorrent) distribute full clone images and run only on the local network (LAN). Over VPN, only **delta updates** are supported — clients in home office / branch sites receive changes as a delta, not as a full re-clone.

**"Affected VPN clients" dialog:** If the targets of a deployment include devices activated in the VPN, ThinForge lists them in a dialog (with CSV export) before creating it. Devices in storage are included — a clone deployment images them too. Re-cloning deletes the VPN configuration on the device; with the VPN connection set up, ThinForge resets the pairing itself when the clone starts and issues a new activation key — the devices re-enroll on their own afterwards, the dialog only serves for tracking. If the connection to the VPN instance has been released, this is not possible: the devices must be activated again by hand after reconnecting. Only in that case does the dialog offer to remove the orphaned VPN pairings from the database (the devices free their subscription seats and stop their VPN service; their accesses on the VPN instance remain there). More in [13 — VPN](13-vpn.md).

## Next steps

- [workflows/deploy-update.md](workflows/deploy-update.md) — full walkthrough: delta capture → group rollout → verify
- [workflows/client-rollback.md](workflows/client-rollback.md) — when it went wrong
- [08 — Tasks & Logs](08-tasks-logs.md) — progress and error analysis
