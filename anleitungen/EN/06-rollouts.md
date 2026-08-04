# 6 — Rollouts

A **rollout** is the planned distribution of a clone ([05](05-cloning.md)) to a set of clients. Rollouts are the primary tool for:

- Initial installation of a baseline on new clients
- Updates on already-provisioned clients (delta)
- Wave-based rollout (pilot group first, production after)
- Rollbacks (restoring an older version — see [workflows/client-rollback.md](workflows/client-rollback.md))

## Rollouts overview

The **Rollouts** menu shows all running, scheduled, and completed rollouts in a table:

| Column | Content |
|--------|---------|
| Status | draft / scheduled / active / paused / completed / cancelled |
| Name | free-form |
| Target | group or client list |
| Image | clone version |
| Method | unicast / multicast / bittorrent |
| Progress | X / Y clients done |
| Start | scheduled or actual |

Clicking a row opens the rollout detail page.

## Creating a rollout

**"+ New rollout"** at the top right. The dialog has four tabs:

### Tab 1 — Basics

- **Name** — pick something sensible (e.g. `2026-04-15 security patch Branch North`)
- **Description** — free text

### Tab 2 — Target

- **Mode**: group or client list
- Group mode: choose the group, checkbox "include sub-groups"
- List mode: mark clients in the table (same filter options as the client list)

### Tab 3 — Image + method

- **Choose clone** — from the version tree. Usually the current base or a fresh delta version
- **Deployment method**:
  - **Unicast** — each client downloads directly from the server. Simple, always works; with > 50 clients on the same LAN the server uplink becomes the bottleneck.
  - **Multicast** — server streams once over UDP multicast, all clients receive in parallel. Great for large LAN rollouts. LAN only, not across VPN/routed networks.
  - **BitTorrent** — clients pull the clone as a torrent and share bandwidth among themselves. Good for many clients on the same LAN. Only **one** at a time because of fixed tracker ports.

### Tab 4 — Schedule

- **Start now** — rollout begins after confirmation
- **Scheduled** — set date/time (e.g. 23:00); the scheduler starts it at that moment
- **Manual start** — save the rollout as "draft", start later via button
- **Wake-on-LAN** — available only for a **scheduled** rollout: the target devices are powered on 1–60 minutes before the start via a magic packet (PXE boot required). Without a set time the WoL option is unavailable.

### Save

Depending on the schedule option the rollout is active immediately, waiting for the scheduler, or sitting as a draft.

## Rollout detail

The detail page shows:

- **Header bar** — status, progress, action buttons (cancel / rollback)
- **Client list with per-client status**:
  - `pending` — waiting to start
  - `deploying` — client pulling and installing
  - `done` — successful, client running the new version
  - `failed` — error, details in the client history
  - `cancelled` — cancelled by the operator
- **Live logs** — backend logs for the rollout (also visible in Tasks / Logs)
- **Timeline** — events (started, completed)

## Rollout actions

### Pause and resume

**Pause** stops the rollout in two places:

- **No further stage** is started. The "Advance to stage X" button is unavailable while paused — only **Resume** brings it back.
- Prepared clients that have **not started yet** are put on hold — including stragglers from an earlier stage that never went through it: PXE entry back to local boot, pending reboot job discarded, per-client status back to `pending`. Without this step a client that was powered off when the stage started would still clone on its next power-on — even though the stage was paused because of errors.

Clients that are **already cloning** keep going. Aborting an image mid-write would leave the disk in an undefined state; their outcome is recorded normally as `done` or `failed`. To stop those as well, use **Cancel**.

**Resume** prepares all held-back clients again (including the reboot job) and re-enables "Advance to stage X". Clients that already finished the stage are left untouched.

### Cancel

Sets the rollout to `cancelled`. Already-deployed clients stay on the new version; running installations are interrupted (clients fall into rescue mode → manual reboot recommended).

### Rollback the rollout

On the detail page, the **"Rollback"** button sends all clients already updated by this rollout back to the previous version. It creates a new rollout in reverse. Details: [workflows/client-rollback.md](workflows/client-rollback.md).

## Deployment methods compared

| | Unicast | Multicast | BitTorrent |
|---|---------|-----------|------------|
| Network | LAN only | LAN only | LAN only |
| Scale | ~50 clients | hundreds | hundreds |
| Parallel rollouts | yes (server CPU limits) | yes (per subnet) | **no** (tracker port conflict) |
| Missing clients | no problem | client must boot at the right moment | client can join later |
| Config needed | none | IGMP on the switch | Tracker port 6969 / seed port 6881 open |

## Progress and troubleshooting

- **Several clients stuck on `deploying`** → most likely network: firewall blocking download, NFS export unreachable, or the cloner container is down. Check services on the dashboard ([02](02-dashboard.md)), logs ([08](08-tasks-logs.md)).
- **`failed` clients** → a single click on the client opens the client history with the error. Common causes: disk too small, wrong partition table, signature verification failure. Fix and re-roll the client via a single-client rollout.
- **Rollout should reach only a subset** → go client list instead of group, pick manually. Or create a temporary "wave" group ([04](04-groups.md)).

## Rollouts and VPN

The three distribution methods (unicast, multicast, BitTorrent) distribute full clone images and run only on the local network (LAN). Over VPN, only **delta updates** are supported — clients in home office / branch sites receive changes as a delta, not as a full re-clone.

## Next steps

- [workflows/deploy-update.md](workflows/deploy-update.md) — full walkthrough: delta capture → group rollout → verify
- [workflows/client-rollback.md](workflows/client-rollback.md) — when it went wrong
- [08 — Tasks & Logs](08-tasks-logs.md) — progress and error analysis
