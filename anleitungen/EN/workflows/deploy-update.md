# Workflow — Deploy an update to a group

Change to the golden image (security patch, new software version, config tweak) → save a delta → assign it to pilot clients first, then to the client fleet.

## Preconditions

- [ ] An existing clone chain (baseline + possibly some deltas) exists
- [ ] Target group(s) defined ([04](../04-groups.md))
- [ ] Pilot group with 1–3 test clients (optional but strongly recommended)

## Step 1 — Start the cloning VM (with the existing disk)

The VM has the disk from the last save — starting "without ISO" boots that exact disk.

1. **Cloning → Create VM**
2. Leave the ISO on **"No ISO (boot from disk)"** (if a restored clone is active, the VM boots from its disk anyway) → **"Start VM"**
3. Use the console in the tab or **"Open in new tab"**

## Step 2 — Apply changes

In the VM:

- Security updates (`apt upgrade`, `pacman -Syu`)
- Install / upgrade software
- Adjust configuration
- Whatever else

**Tested in a kiosk / production scenario?** Before the update goes out, make sure nothing obvious is broken.

## Step 3 — Shut the VM down

Clean shutdown from within the VM. The **Create VM** card shows **Stopped**.

## Step 4 — Save the delta

1. **Cloning → Create VM**
2. **"Save update delta & create clone"** → dialog:
   - **"Delta update (incremental)"** — the default, keep it (not "New base image")
   - **Version** — assigned automatically, e.g. `v2026.06.22-005`
   - **Comment** — concise; e.g. "Chromium 126, libssl CVE patch"
3. **"Save update delta & create clone"**

The delta usually takes 1–5 minutes (step 1/2), then the full clone is created (step 2/2). The delta is computed against the previous version, stored on the server and signed if a signing key exists. It appears under **Cloning → Updates** in the **Update Chain**.

## Step 5 — Pilot assignment

First on a few test clients:

1. **Cloning → Updates** → **Assignments** card → **"Add"** ([06](../06-rollouts.md))
2. **Individual clients** → pick a group → select the 1–3 pilot clients
3. **Target version**: `v2026.06.22-005`
4. Optionally **"Notify user (auto-reboot after update)"** — the client shows a 15-minute countdown before the automatic reboot
5. **"Add"** — the assignment is created as a **Draft**
6. In its row click **"Release"** (check mark) — the clients fetch the delta from their next heartbeat on

Expanded, the assignment shows each client's status, with progress, rate and bytes while downloading. A fully downloaded update is **Prepared** and is applied on the client's next shutdown or reboot; without the notification, select the clients there and reboot them via **Actions → Reboot**. Wait until all pilot clients are **Confirmed** — the note “reported by the device” says where the status comes from: the device reports the target version as installed; the server does not verify the installation itself.

## Step 6 — Verify the pilot

Minimum check-list:

- [ ] Clients rebooted and are back online
- [ ] Agent running (`systemctl status thinforge-agent` via the terminal)
- [ ] **Installed Image** column shows `v2026.06.22-005`
- [ ] User-side nothing obviously wrong (apps start, network works, printers work)
- [ ] No client in the assignment on **Failed** or **Signature invalid**

**Let it run at least 24 h** in pilot before broad rollout.

## Step 7 — Broad assignment

When the pilot is solid:

1. **Cloning → Updates** → **Assignments** → **"Add"**
2. Choose the **Group** (e.g. "Branch North", "all POS")
3. **Target version**: `v2026.06.22-005`
4. If clients lag several versions behind: **"Generate merged deltas"** — the server builds combined deltas in the background, clients wait for them automatically
5. Optionally **"Notify user"** as in the pilot
6. **"Add"**, then **"Release"**

A client can only be part of one open assignment; clients still in another one are skipped. How many clients download at the same time and with how much bandwidth is set in the **Bandwidth settings** (cog in the update chain).

## Step 8 — Monitor progress

In the **Assignments** table:

- The **Progress** column counts confirmed, prepared, pending and failed clients
- Expanded row: per-client status — watch for **Failed** and **Signature invalid**

**On issues:**

- Individual failed clients: check the cause on the device (terminal, container logs [08](../08-tasks-logs.md)). If a download aborts, the server retries it up to the configured number of automatic retries
- Clustered failures (> 10 % failed): **Cancel** the assignment — running downloads finish, new ones do not start — and clarify the root cause before more clients are affected

## Step 9 — Close

Once all clients have reached a final status, the assignment switches to **Completed**. Final check:

- Find deviators in the clients list via the **Installed Image** column and deal with them individually
- In the **Clones** tab, the expanded row of a version lists the clients still below it

## Pitfalls

- **Saving the delta fails** → usually the VM did not actually shut down, or the previous snapshot was deleted manually. The error appears in the **Create VM** tab, details in the container logs.
- **Clients stay on Pending** → the limit of concurrent downloads is exhausted (bandwidth settings), or the merged deltas are still being built (merge progress in the status column).
- **Pilot clients do not return after reboot** → the update itself had a bug or the signature no longer fits. Rollback individually ([client-rollback.md](client-rollback.md)).

## Next steps

- [workflows/client-rollback.md](client-rollback.md) — when it went wrong
- [06 — Rollouts](../06-rollouts.md) — deployment methods in detail
