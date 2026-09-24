# 6 — Rollouts

A **rollout** is the distribution of a clone ([05](05-cloning.md)) to a set of clients. ThinForge offers two ways to do it; both rewrite the full image via PXE:

- **Cloning → Deployments** — initial installation or re-clone of a group, several groups or individual clients, via unicast, multicast or BitTorrent, immediately or at a scheduled time
- **Staged Rollouts** — wave-based rollout of an image (pilot share first, production after) with an error threshold per stage

Delta updates for already-provisioned clients are distributed under **Cloning → Updates** ([workflows/deploy-update.md](workflows/deploy-update.md)), rollbacks under **Cloning → Rollback** ([workflows/client-rollback.md](workflows/client-rollback.md)).

## Deployments

**Cloning → Deployments** lists all clone deployments in a table:

| Column | Content |
|--------|---------|
| Mode | UC (unicast) / MC (multicast) / BT (BitTorrent) |
| Clone | name of the clone |
| Group | target group |
| Status | Scheduled (with time) / Active / Paused / Completed / Completed with Errors / Cancelled; for BitTorrent "Preparing…" first |
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
  - **Multicast** — server streams once over UDP multicast, all clients receive in parallel. Great for large LAN rollouts. LAN only, not across VPN/routed networks. Only **one** multicast deployment can be active at a time; for several groups on the same image choose **Multiple Groups**. Creating and launching a deployment with this method is operator work; saving the global **Multicast Settings** (cog icon: wait time 30–3600 s, completion timeout 30–1800 s) has been admin-only since 2026-08-31, because they affect every future deployment.
  - **BT Multi-Deploy** (default) — clients pull the clone as a torrent and share bandwidth among themselves. Good for many clients on the same LAN. Several BitTorrent deployments can run in parallel, even with different clones.
- **Post-Deploy Action** — Reboot (default), Shutdown or Nothing

### Timing

- **No schedule** — the deployment starts immediately. **"Reboot online clients now"** (on by default) reboots clients reported online into the deployment via SSH, for BitTorrent only once the seeder has published the torrents; powered-off clients start into it on their next power-on.
- **Scheduled Start** — set date and time (e.g. 23:00), meant in the server time zone ([09](09-settings.md)); the scheduler starts the deployment at that moment. A date without a time blocks creation.
- **Send Wake-on-LAN at start** — available only for a **scheduled** deployment: the target devices receive a magic packet at the scheduled time, activation (PXE, NFS, DHCP) runs one minute earlier, for BitTorrent the seeder starts ten minutes earlier (PXE boot required). Without a set time the WoL option is unavailable.

### Deploy

**"Deploy"** creates the deployment. If a target client is already part of a running deployment, the server refuses.

In the list, **Cancel** stops an active or scheduled deployment. Once it has ended, **Restart failed** restarts the failed and cancelled clients, **Restart** in the expanded row restarts a single one (not for multicast); **Delete** removes a finished deployment.

## Staged Rollouts

The **Staged Rollouts** view has no menu entry of its own. You reach it via the dashboard card **Active Rollouts** ("View All", only while a rollout is active or paused) or directly at `/rollouts`.

### Rollouts overview

| Column | Content |
|--------|---------|
| Name | free-form |
| Image | name of the image |
| Status | Draft / Active / Paused / Completed / Cancelled |
| Progress | current stage (e.g. "Stage 2 / 3") with a bar of the finished clients of that stage |
| Started | start time |

Clicking a row expands the **Stage Progress** (done / total, errors, active clients per stage) and the **Clients** with hostname, MAC, stage, status and completion time. Per-client status:

- `pending` (Pending) — waiting for its stage
- `deploying` (Deploying) — stage armed, client pulling and installing
- `done` (Done) — successful, client running the new version
- `failed` (Failed) — cloning failed
- `cancelled` (Cancelled) — cancelled by the operator

### Creating a rollout

**"New Rollout"** at the top right opens the dialog:

- **Rollout Name** — pick something sensible (e.g. `2026-04-15 security patch Branch North`)
- **Image** — the ready images are offered, i.e. the captures imported under **Cloning → Captures** ([05](05-cloning.md#tab-captures))
- **Stages (cumulative %)** — comma-separated, strictly increasing, the last value must be 100; default `10,50,100`
- **Scope** — **All Clients** or **Group** (then pick the group; only clients assigned directly count, no sub-groups)
- **Halt on errors** (on by default) with **Error threshold (%)** (default 20)

**"Save"** creates the rollout as a **Draft**. A draft can be edited (name, stages, error rule) or deleted. Each stage writes the image via **unicast** and triggers a reboot for its clients; after cloning the clients reboot.

## Rollout actions

### Launch and advance

- **Launch** (rocket icon, draft only) — checks whether the NFS server is running (and otherwise offers to start it), collects the clients in scope, distributes them randomly across the stages and arms the first stage: PXE deploy entry plus reboot job. Clients without an assigned IP address or in another running deployment are skipped by the stage.
- **Advance to Stage X** — arms the next stage; on the last stage the button reads **Complete** and sets the rollout to `completed`. With **Halt on errors** the server refuses to advance as soon as the share of failed clients among the already finished clients of the current stage reaches the error threshold.

### Pause and resume

**Pause** stops the rollout in two places:

- **No further stage** is started. The "Advance to stage X" button is unavailable while paused — only **Resume** brings it back.
- Prepared clients that have **not started yet** are put on hold — including stragglers from an earlier stage that never went through it: PXE entry back to local boot, pending reboot job discarded, per-client status back to `pending`. Without this step a client that was powered off when the stage started would still clone on its next power-on — even though the stage was paused because of errors.

Clients that are **already cloning** keep going. Aborting an image mid-write would leave the disk in an undefined state; their outcome is recorded normally as `done` or `failed`. **Cancel** does not stop them either.

**Resume** prepares all held-back clients again (including the reboot job) and re-enables "Advance to stage X". Clients that already finished the stage are left untouched.

### Cancel

Sets the rollout to `cancelled` after confirmation. Already-deployed clients stay on the new version. Prepared clients that have not started yet are disarmed as with pausing, their per-client status goes to `cancelled`. Clients that are already cloning finish and report their result as usual.

Completed and cancelled rollouts can be deleted.

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
- **Several clients stuck on `deploying`** → most likely network: firewall blocking download, NFS export unreachable, or the NFS server, multicast sender or BitTorrent seeder is not running. Check services on the dashboard ([02](02-dashboard.md)), logs ([08](08-tasks-logs.md)).
- **`failed` clients** → under **Cloning → Deployments** the expanded row shows the error message per client; the stages of a staged rollout appear there as separate unicast deployments. Common causes: disk too small, wrong partition table, signature verification failure. Fix and roll the client out again.
- **Rollout should reach only a subset** → choose **Individual Clients** instead of a group in the deployment and pick manually. Or create a temporary "wave" group ([04](04-groups.md)).

## Rollouts and VPN

The three distribution methods (unicast, multicast, BitTorrent) distribute full clone images and run only on the local network (LAN). Over VPN, only **delta updates** are supported — clients in home office / branch sites receive changes as a delta, not as a full re-clone.

**"Affected VPN clients" dialog:** If the targets of a deployment or rollout include devices activated in the VPN, ThinForge lists them in a dialog (with CSV export) before creating it. Re-cloning deletes the VPN configuration on the device; with the VPN connection set up, ThinForge resets the pairing itself when the clone starts and issues a new activation key — the devices re-enrol on their own afterwards, the dialog only serves for tracking. If the connection to the VPN instance has been released, this is not possible: the devices must be activated again by hand after reconnecting. Only in that case does the dialog offer to remove the orphaned VPN pairings from the database (the devices free their license seats and stop their VPN service; their accesses on the VPN instance remain there).

## Next steps

- [workflows/deploy-update.md](workflows/deploy-update.md) — full walkthrough: delta capture → group rollout → verify
- [workflows/client-rollback.md](workflows/client-rollback.md) — when it went wrong
- [08 — Tasks & Logs](08-tasks-logs.md) — progress and error analysis
