# 5 — Cloning

The cloning area is the heart of ThinForge: this is where you create, maintain, and manage the disk images (clones) that are later distributed to thin clients.

The view has several tabs. The most important ones for the image lifecycle are **Create VM**, **ISOs**, **Captures** and **Clones**.

## Lifecycle overview

```
1. Create the base HD  (without this base disk layout, delta-update
   functionality cannot be guaranteed)
       ↓
2. Upload/download an ISO, boot the cloning VM with it
       ↓
3. Install OS → for the restart: stop the VM, check the ISO is no
   longer selected, start the VM → install the agent, customise
       ↓
4. Create a delta update ("Save update delta & create clone")
   → image (v2026.06.22-001)
       ↓
5. Later: start VM, modify, click "Save update delta" again
   → v2026.06.22-002, v2026.06.22-003, ...
       ↓
6. Rollout → clients pull the image ([06](06-rollouts.md))
```

---

## Tab: Create VM

The cloning VM is a QEMU/KVM instance running on the server. It has a dedicated qcow2 disk that serves as the template for all later clones.

### VM status

A status bar at the top of the tab shows:

- **Active** (green) — VM running, console attached
- **Inactive** (grey) — not started
- **Starting / stopping** — transitional state

### Starting

1. Click **"Start VM"**
2. Dialog: pick an ISO (or "no ISO" if an OS is already installed)
3. Confirm or adjust resources (RAM, CPUs, disk size)
4. Start

After 10–30 seconds the VM is bootable, the console becomes active.

### Console

- The VM console is embedded directly in the tab; use **"Open in new tab"** to show it in its own window
- The clipboard is passed through
- The VM then behaves like an ordinary PC: click through the installer, set up software, let updates run

### Stopping

- **"Stop VM"** — shuts the VM down

### Resources

The default values (RAM, CPUs, disk size) are enough for most Linux and Windows versions. You set RAM, CPUs and disk size per VM directly when starting it; the server-side defaults live in the server configuration, not in the Settings area of the interface.

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

The Tools ISO is built automatically by the server. It contains the client provisioning script and is used for the **initial setup of a new thin client** via USB stick or PXE ([workflows/first-client.md](workflows/first-client.md)).

The Tools ISO is rebuilt automatically every time the cloning VM starts. So after a certificate renewal or key rotation, you simply restart the VM.

---

## Create an image from the VM

In the **Create VM** tab you save the VM state as a deployable image (the VM must be **stopped**). The dialog picks the right mode automatically.

### Create baseline

- Takes a baseline snapshot of the VM and starts a new version chain
- Chosen automatically the first time (no clones yet); forceable any time via the **"As new baseline"** option
- **When?** At the very start or for a clean new chain (e.g. after a major OS upgrade)

### Save update delta & create clone

- Creates a delta against the previous version **and** a complete, deployable clone image
- Fast and small (only changed blocks in the delta)
- **When?** For ongoing updates — security patches, config changes, new software

### Creating an image

1. The cloning VM must be **stopped** (otherwise an error)
2. In the **Create VM** tab click **"Save update delta & create clone"**
3. In the dialog:
   - **Version** — assigned automatically in the format `vYYYY.MM.DD-NNN` (date plus a per-day counter per image line), e.g. `v2026.06.22-001`
   - **Comment** — short note on what changed
   - **"As new baseline"** — forces a fresh chain (baseline mode)
4. Start

The operation runs as a background task. Progress is visible here and in **Tasks** ([08](08-tasks-logs.md)). Depending on disk size a full image takes 10–30 minutes, a delta usually 1–5 minutes.

### Cancel

While the operation is running, a **"Cancel"** button appears. Cancelling cleans up half-produced files — the VM itself is not damaged.

---

## Tab: Captures

The **Captures** tab, in contrast, captures the disk of a **physical client**: the device boots into a capture environment (Clonezilla) via PXE, and its disk state is saved as an image.

1. Pick the client
2. Give the capture a name
3. Decide whether the device **shuts down** or **reboots** afterwards
4. Start

The operation runs as a background task; progress is visible in **Tasks** ([08](08-tasks-logs.md)).

---

## Tab: Clones

The list of finished images, ready to be rolled out.

### Version tree

Clones are shown hierarchically — baselines as roots, deltas as children:

```
v2026.06.22-001 (Baseline)
├─ v2026.06.22-002
├─ v2026.06.22-003
├─ v2026.06.22-004
└─ v2026.06.22-005    ← current "stable", latest update

v2026.06.23-001 (Baseline)
└─ v2026.06.23-002
```

Within a chain the deltas are **flat** — they hang as siblings directly off the base (linked via `parent_id`, not by version number), not nested. This makes it easy to delete individual updates later without breaking the chain. If a clone with a broken `parent_id` ever appears (e.g. because the original source clone was deleted), ThinForge repairs the tree automatically the next time the Clones tab is opened.

The **base** of a chain is determined automatically: it is the root of the version chain (the lowest version with no parent). It is shown as a marker.

### Per-clone actions

- **Show details** — metadata (size, comment, created at, agent version at capture time)
- **Reassign / sort in** — moves the clone to a different position in the tree (see below)
- **Restore** — writes the clone back onto the cloning VM. This lets you switch back to an older version at any time. Make sure the clients end up on the older version too — either via a new deployment or via the rollback (which can only restore the immediately previous version).
- **Export** — download as a 7z archive
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
