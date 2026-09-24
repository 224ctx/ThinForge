# Workflow — Roll a client back to a previous version

When something doesn't behave right after an update — individual clients or a whole group — we need to go back to the last known-good version. ThinForge does this with a **rollback assignment** under **Cloning → Rollback**, either for a group or for individual clients.

## Preconditions

- [ ] The affected client has a **predecessor snapshot** (after an update the agent keeps the previous generation locally and reports its snapshots via heartbeat)
- [ ] Agent is running and reports via heartbeat

**Important:** a rollback always goes **one generation** back — the agent switches to the next older snapshot. For earlier versions → deploy the older version (**Cloning → Deployments**, [06](../06-rollouts.md)) instead of using the rollback function.

## Create a rollback

1. **Cloning → Rollback** → **"Create rollback"**
2. Dialog **Create rollback assignment**:
   - **Group** — the clients of a group, or **Individual clients** — pick a group first, then select the affected clients
   - **Rollback target** — offers the snapshot versions these clients report (excluding the currently installed one). Clients without this snapshot are not included; if none remain, "No clients with this snapshot found" appears
   - **Mark version as defective** (on by default) — see below; clear it if the current version should remain usable (e.g. because it was only rolled out by mistake)
3. **"Create rollback"**

### Mark version as defective

With the checkbox set, the version the selected clients are currently running counts as **defective**:

- running and scheduled update assignments to this version are aborted and their downloads stopped
- in **Clones** and in the update chain the version carries the red **Defective** marker and can no longer be chosen as a target
- its snapshot is removed on the clients — on the rolled-back ones only once their rollback is confirmed

The marking stays in place even if the rollback assignment is aborted or deleted later.

## What happens

- With the next heartbeat the agent receives the rollback request, stores it locally and reports **prepared**
- The actual switch happens **on the client's next shutdown or reboot**: the agent swaps to the next older snapshot and points the boot loader at it
- There is no automatic reboot. The **Client status** card below the assignments lists the clients still open; select them there and trigger **Actions → Reboot** (or **Shutdown**)
- After the reboot the agent reports the older version, the client is **completed**; once all clients are completed the assignment switches to **Completed**

**Tracking:** the table of rollback assignments shows **Group / Clients**, **Version** (the rollback target), **Status** (Active, Completed, Aborted) and **Progress** (completed / prepared / pending); expanded, per client hostname, inventory number, MAC address, version and status. While an assignment is active, the view refreshes every 30 seconds.

## Abort and delete

- **Abort** (active assignments only) — clients not yet rolled back lose their rollback request; clients already rolled back stay on the older version
- **Delete** — removes the assignment, with the same effect on open clients

Neither undoes the defective marking.

## When the rollback itself fails

Rare, but possible — client stays on "prepared", client no longer running, disk damage.

### Option A — Re-deploy

When rollback doesn't work, the fastest path is often: fresh deploy of the desired version.

1. **Cloning → Deployments** → **"New Deployment"** → **Individual Clients** → pick the client, with the older version as clone ([06](../06-rollouts.md))
2. Client PXE-boots into the deployment and installs the version like a new client

### Option B — Re-provision from scratch

Last resort when the disk is corrupt:

1. **Delete** the client in the UI (DB entry gone)
2. Physically power off the client (ideally wipe the disk)
3. Onboard like a new client ([workflows/first-client.md](first-client.md))

## Pitfalls

- **Rollback target list stays empty / "No clients with this snapshot found"** → the clients report no older snapshot (e.g. because local snapshots were cleaned up). Use option A or B.
- **Client stays on "prepared"** → it has not been shut down or rebooted yet (**Client status** card → **Actions → Reboot**). If the switch fails during shutdown, the request stays on the device and the next reboot tries again.
- **After rollback the client does not come back online** → verify the agent is running correctly on the older version; re-provision if not.

## Prevention next time

- **Stick to the pilot phase** ([workflows/deploy-update.md](deploy-update.md), steps 5–6)
- **Don't go straight broad** — 1–3 clients first, let them run 24 h, then scale
- **Monitoring** — keep an eye on alerts on the dashboard; the **Version Mismatch** alert reports clients whose installed clone differs from the one expected for their group ([09](../09-settings.md))

## Next steps

- [06 — Rollouts](../06-rollouts.md) — how rollouts are set up
- [08 — Tasks & Logs](../08-tasks-logs.md) — find the root cause
