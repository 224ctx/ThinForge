# Workflow — Roll a client back to a previous version

When something doesn't behave right after an update — a single client, a whole group, or an entire rollout — we need to go back to the last known-good version. ThinForge supports three rollback paths, depending on scope.

## Preconditions

- [ ] The affected client has a **predecessor clone** (one generation is automatically kept locally)
- [ ] Agent is running or the client can PXE-boot

**Important:** a rollback always goes **one generation** back. For earlier versions → start a new rollout of the older clone instead of using the rollback function.

## Path 1 — A single client

Fast, directly from the detail page.

1. **Clients → Client detail** ([03](../03-clients.md))
2. Tab **Actions** → **"Rollback"**
3. Confirmation dialog says: *"This client will be rolled back to `v2026.06.22-004` (current: `v2026.06.22-005`). Continue?"*
4. Confirm

What happens:
- The agent receives boot mode `rollback` on the next heartbeat
- Client reboots (automatic or after manual trigger)
- The rollback boot mode activates the locally-kept predecessor snapshot
- After ~2–5 min the client is on the previous version and the agent checks in

**Tracking:**
- Client detail → History tab
- Status in the list: orange ("Cloning") → grey ("Offline") → green ("Online")

## Path 2 — Multiple clients (bulk)

Typical case: a handful of clients in a group have issues, but not all.

1. **Clients list** ([03](../03-clients.md))
2. Filter/search → select affected clients (checkbox)
3. Action bar at the top → **"Rollback"**
4. Confirmation dialog with the list of selected clients
5. Confirm

Internally runs a single rollback per client. Progress in **Tasks** ([08](../08-tasks-logs.md#tasks)).

## Path 3 — Revert an entire rollout

A freshly rolled-out update has widespread problems — all affected clients should go back together.

1. **Rollouts → rollout detail** ([06](../06-rollouts.md))
2. Button **"Rollback this rollout"**
3. Confirmation dialog: *"X clients will be rolled back to the version installed before this rollout."*
4. Confirm

ThinForge internally creates a new rollout that performs a rollback on each affected client. Method is inherited from the original rollout (unicast/multicast/BitTorrent).

**Advantage**: progress page just like a normal rollout. **Disadvantage**: takes about as long as the original rollout.

## When the rollback itself fails

Rare, but possible — rollback process hangs, client no longer running, disk damage.

### Option A — Rescue boot

1. Client detail → Actions → **"Rescue boot on next start"**
2. Reboot the client (manually at the device or via agent command)
3. Client boots into a minimal recovery environment
4. Terminal into the client → diagnose manually (partitions, snapshots, logs)

### Option B — Re-deploy

When rollback doesn't work, the fastest path is often: fresh deploy of the desired version.

1. Client detail → Actions → **"Rollout"** with the older version as target image
2. Client reboots in `deploy` mode and installs the version like a new client

### Option C — Re-provision from scratch

Last resort when the disk is corrupt:

1. **Delete** the client in the UI (DB entry gone)
2. Physically power cycle the client, PXE reset (ideally wipe the disk)
3. Onboard like a new client ([workflows/first-client.md](first-client.md))

## Pitfalls

- **"Rollback" button is greyed out** → client has no predecessor snapshot (fresh install, or the local snapshot was cleaned up). Use option B or C.
- **After rollback the client does not come back online** → verify the agent is running correctly on the older version; re-provision if not.
- **Rollout rollback produces "failed" clients** → these clients had a problem even before the original rollout. Treat individually (path 1 or option C).

## Prevention next time

- **Stick to the pilot phase** ([workflows/deploy-update.md](deploy-update.md), steps 5–6)
- **Don't go straight broad** — 1–3 clients first, let them run 24 h, then scale
- **Monitoring** — keep an eye on alerts and the Compliance card on the dashboard

## Next steps

- [06 — Rollouts](../06-rollouts.md) — how rollouts are set up
- [08 — Tasks & Logs](../08-tasks-logs.md) — find the root cause
