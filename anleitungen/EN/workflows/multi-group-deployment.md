# Workflow: Deploy one image to several groups at once

Since the 2026-04-22 release ThinForge supports **multi-group deployments**: a single deployment object can serve several groups, and thanks to the service-mode BitTorrent seeder even **several deployments run in parallel** — including different groups with different clones. This workflow shows how to use that in practice.

## Which mode when?

| Scenario | Recommended mode |
|---|---|
| Same clone → several groups, at the same time, on the local network | **Multicast with target mode "Multiple Groups"** — streams once over the wire, all clients receive in parallel. |
| Same clone → several groups, different subnets on the local network | **BitTorrent** — peer assist, cache sharing between deployments. Branch offices reached over the VPN get no clone deployment at all — only delta updates there ([06](../06-rollouts.md#rollouts-and-vpn)). |
| Different clones → different groups, all at the same time | **BitTorrent** per deployment. Multicast can only run **once** at a time (protocol limit), BitTorrent parallelizes. |
| Only a few targets, no multicast-capable network | **Unicast** — direct download per client. |

## Multi-group via multicast

1. Menu **Cloning** → tab **Deployments** → **New Deployment**.
2. Target → **Multiple Groups**.
3. Under **Select Groups** tick the groups you want. The hint below says how many clients from how many groups the deployment hits.
4. **Select Clone**.
5. **Mode** → `Multicast`.
6. Optional: **Scheduled Start** + **Send Wake-on-LAN at start** (the magic packet goes out at the scheduled time, the activation runs one minute before).
7. **Deploy**.

All clients of all groups appear in a single deployment row. The server waits until all participants have completed the PXE boot — at most the **wait time** from the multicast settings, after which it starts with the clients that are ready —, then streams the image **once** and serves all groups at the same time with it.

**Gotcha:** A second simultaneous multicast deployment is not possible — the address `224.0.0.1:2232` is static. The server refuses a second active multicast deployment.

## Parallel deployments via BitTorrent

Since 2026-04-22 BitTorrent runs as a **service mode**: a single `thinforge-bt-seeder-service` container hosts any number of clone torrents in parallel and shuts itself down automatically as soon as the last deployment is finished.

Advantages from the operator's point of view:

- **No more mode conflict** with BT. Simply create a second deployment with a different clone for a different group.
- **Slice cache per clone** — the second rollout of the same clone saves the expensive partclone extraction, the new clients join the same swarm as the ones already running.
- **Auto-stop** when idle — tracker port 6969 and seed port 6881 are closed outside active rollouts.

Workflow:

1. Create deployment 1: group Marketing, clone `marketing-v2026.06.22-006`, mode BitTorrent.
2. Create deployment 2: group Sales, clone `sales-v2026.06.22-003`, mode BitTorrent.
3. Both deployments start in parallel — the seeder boots once and hosts both torrents.
4. When deployment 1 is finished: torrent 1 is unregistered, the seeder stays for deployment 2.
5. When deployment 2 is finished as well: the container is removed automatically.

## Monitoring during the rollout

Table in the Deployments tab:

- **Multicast** — the chip shows "N/M ready" with the remaining time (M:SS) during the readiness phase, then the partition currently being sent (or "Sending...") during the stream, finally "Sent".
- **BitTorrent** — the status first reads "Preparing…", a chip shows the steps ("Seeder starting...", "Extracting...", "Creating torrents...", "Starting tracker..."), then "Seeding (N part.)", finally "Completed". In the expanded row you see per client the partition currently being written plus a percentage bar.
- Per client row: Pending / Deploying / Done / Failed / Cancelled; for failed or cancelled clients under BitTorrent/unicast also **Restart** (not under multicast — a restart makes no sense there because the stream is already gone).

## Error handling

- A client reports `failed` → expand the row, **Restart**; the backend retries the single client.
- The whole deployment hangs → **Cancel** sets the status to "Cancelled"; follow up with **Restart failed/cancelled** if needed.
- The seeder does not start → check **Settings → Services** (`thinforge-bt-seeder-service` container). The logs tell whether opentracker or EZIO was blocked.
- Multicast stays stuck in the readiness phase → network issue (IGMP snooping, switch configuration).

## After the rollout

- The deployment row reads "Completed" or "Completed with Errors". The **Delete** button removes only the record, not the clones.
- In **Clients** → column **Installed Version** shows the new version.
- With **Post-Deploy Action** = reboot or shutdown the clients are already in the target state.

## Next steps

- [05 — Cloning](../05-cloning.md) for the basics of the image pipeline.
- [06 — Rollouts](../06-rollouts.md) for deployments, distribution methods and progress control.
- [workflows/deploy-update.md](deploy-update.md) for the case where only a delta is to be rolled out rather than a full image.
