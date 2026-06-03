# 5 — Cloning

The cloning area is the heart of ThinForge: this is where you create, maintain, and manage the disk images (clones) that are later distributed to thin clients.

The view has **four tabs**: Cloning VM, ISOs, Captures, Clones. Each tab covers a step of the image lifecycle.

## Lifecycle overview

```
1. Upload / download an ISO
       ↓
2. Boot the cloning VM with the ISO
       ↓
3. Install OS, set up agent, customise
       ↓
4. Capture → first image = baseline (v1.000)
       ↓
5. Change: start VM, modify, "Save update"
       ↓
6. Delta capture → v1.001, v1.002, ...
       ↓
7. Rollout → clients pull the image ([06](06-rollouts.md))
```

---

## Tab: Cloning VM

The cloning VM is a QEMU/KVM instance running on the server. It has a dedicated qcow2 disk that serves as the template for all later clones.

### VM status

A status bar at the top of the tab shows:

- **Active** (green) — VM running, noVNC attached
- **Inactive** (grey) — not started
- **Starting / stopping** — transitional state

### Starting

1. Click **"Start VM"**
2. Dialog: pick an ISO (or "no ISO" if an OS is already installed)
3. Confirm or adjust resources (RAM, CPUs, disk size)
4. Start

After 10–30 seconds the VM is bootable, the **"Open in VNC"** button becomes active.

### VNC access

- Click **"Open in VNC"** — opens in-browser noVNC
- Fullscreen possible, clipboard is passed through
- The VM then behaves like an ordinary PC: click through the installer, set up software, let updates run

### Stopping

- **"Stop VM"** — clean ACPI shutdown
- **"Force stop"** — hard kill (when the VM hangs)

### Resources

Default values (2 GB RAM, 2 CPUs, 60 GB disk) are enough for most Linux and Windows versions. Override via `.env` variables `CLONING_VM_RAM`, `CLONING_VM_CPUS`, `CLONING_VM_DISK_SIZE` (see [09 — Settings](09-settings.md)).

---

## Tab: ISOs

Manages installation ISOs that serve as boot media for the cloning VM.

### List

Table with file name, size, upload date. Clicking an ISO shows details (SHA256, hint whether it is currently in use).

### Upload

Two ways:

1. **"Upload ISO"** — file from your local machine. Accepts `.iso` only. No size limit, but for > 5 GB a direct URL download is more convenient.
2. **"Download by URL"** — dialog with URL field, optional file name. ThinForge fetches the file in the background and shows progress live (% and bytes). Ideal for Debian, Ubuntu, Manjaro images directly from their mirror.

### Delete

Only possible when no active VM is using the ISO. Otherwise an error is shown with a hint to stop the VM first.

### Tools ISO

A special entry, `thinforge-tools.iso`, is built automatically by the server. It contains the client provisioning script and is used for the **initial setup of a new thin client** via USB stick or PXE ([workflows/first-client.md](workflows/first-client.md)).

- **"Rebuild"** — re-creates it, e.g. after a certificate renewal or key rotation. Takes ~1 minute.

---

## Tab: Captures

The **capture** is the process of turning the VM state into a deployable image. Two kinds:

### Baseline capture

- Produces a full image (no delta parent)
- Clears existing snapshots in the VM
- Starts a new version chain: `v1.000`, `v2.000`, …

**When?** At the very start or when you want a clean new chain (e.g. after a major OS upgrade).

### Delta capture ("Save update")

- Produces an incremental image against the previous version
- Fast and small (only changed blocks)
- Version is incremented: `v1.003` → `v1.004`

**When?** For ongoing updates — security patches, config changes, new software.

### Starting a capture

1. The cloning VM must be **stopped** (otherwise an error)
2. In tab **Captures** click **"Save update"**
3. Dialog:
   - **Version** — pre-filled (next number), can be overridden
   - **Comment** — short note on what changed
   - **"As new baseline"** — checkbox for baseline mode (produces `v<nextRoot>.000`)
4. Start

The capture runs as a background task. Progress is visible here in the tab and in **Tasks** ([08](08-tasks-logs.md)). Depending on disk size a full capture takes 10–30 minutes, a delta usually 1–5 minutes.

### Cancel a capture

While the capture is running, a **"Cancel"** button appears. Cancelling cleans up half-produced files — the VM itself is not damaged.

---

## Tab: Clones

The list of finished images, ready to be rolled out.

### Version tree

Clones are shown hierarchically — baselines as roots, deltas as children:

```
v1.000 (Baseline)
├─ v1.001
├─ v1.002
├─ v1.003
└─ v1.004    ← current "stable", latest update

v2.000 (Baseline)
└─ v2.001
```

Within a version trunk (e.g. all `v1.x`), updates are **flat** — `v1.001`, `v1.002`, `v1.003` are siblings under `v1.000`, not chained. This makes it easy to delete individual updates later without breaking the chain. If a clone with a broken `parent_id` ever appears (e.g. because the original source clone was deleted), ThinForge repairs the tree automatically the next time the Clones tab is opened.

The **base** of a chain is the clone from which rollouts currently start — often the first, sometimes a later one (when older versions are archived).

### Per-clone actions

- **Show details** — metadata (size, comment, created at, agent version at capture time)
- **Set as base** — marks this clone as the chain start (rollouts begin here)
- **Reassign / sort in** — moves the clone to a different position in the tree (see below)
- **Export** — download as a tarball
- **Delete** — only if no clients use this version and no deltas depend on it

### Reassign / sort in

Sometimes clones should be reordered in the tree — e.g. when a re-imported clone belongs at a different position, or when a parent-less clone should be threaded into an existing chain.

- **"Assign as child"** — attaches the clone as the next child of a selected parent
- **"Insert before"** — inserts the clone before an existing clone (only when a version number is recognisable in the name and the target version lies in the same root number range)
- **"Detach"** — removes the clone from its chain and turns it into a standalone new baseline

These operations are **purely logical** — they only modify metadata, not the image itself. Delta generation still follows the physical snapshot chain from the capture moment.

---

## Keep an eye on disk space

Clones can be large (several GB per baseline, a few MB to GB per delta). The dashboard **Disk Usage** card shows values. Typical cleanup:

- **Remove old baselines no longer distributed** — careful: only when no live clients still use them
- **Consolidate old deltas** — via "New baseline" on the current leaf version, then drop the old chain
- **Delete unused ISOs**

## Next steps

- [06 — Rollouts](06-rollouts.md) — distribute a clone to clients
- [workflows/golden-image.md](workflows/golden-image.md) — build the first baseline from scratch
- [workflows/deploy-update.md](workflows/deploy-update.md) — roll a delta update to a group
