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
   longer selected, start the VM → install the agent, customize
       ↓
4. Save the baseline ("Save update delta & create clone", in
   baseline mode the first time) → image (v2026.06.22-001)
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

A chip in the header of the **Create VM** card shows the state:

- **Running** (green) — VM running
- **Shutting down** (orange) — "Stop VM" is in progress, the guest system is shutting down
- **Stopped** (gray) — not started

While starting, the button spins; while stopping, the chip reads "Shutting down" until the VM is off. The console only appears once the screen transfer responds — until then it shows "Preparing console".

### Create base HD

Without a virtual disk the VM does not start. **"Create base HD"** creates it from scratch and partitions it in the ThinForge layout: total size (GB), ESP partition (MB, default 300) and data partition (GB, default 20 % of the total size); the system partition is what remains and must be at least 4 GB. Existing disk content is lost. **"Reset VM"** deletes the virtual disk entirely.

### Starting

1. Pick the ISO on the card (or **"No ISO (boot from disk)"** if an OS is already installed)
2. Check or adjust RAM, CPUs, disk size and **KVM Acceleration**
3. Click **"Start VM"**

If the selected disk size differs from the existing disk, a dialog asks whether to **keep** it or **recreate** it (recreating leads into **Create base HD**). If a restored clone is active, the VM boots from its disk; ISO selection is then locked and the disk can only be enlarged.

After 10–30 seconds the VM is bootable, the console becomes active.

### Console

- The VM console is embedded directly in the tab; use **"Open in new tab"** to show it in its own window
- The clipboard is passed through
- The VM then behaves like an ordinary PC: click through the installer, set up software, let updates run

### Stopping

- **"Stop VM"** — shuts the guest system down cleanly: ThinForge presses the VM's power button and waits up to 2 minutes for it to switch itself off. Meanwhile the button stays disabled and a notice appears above the buttons. Afterwards ThinForge reports "shut down cleanly" — or "stopped hard" if the guest system did not react (for instance in the installer, in the firmware menu or with an open "Shut down?" dialog without countdown); that is like a power cut, unwritten data is lost. Until the update of 2026-10-01 the button always ended the VM immediately.
- To be on the safe side, shut the system down in the console yourself first and stop afterwards.
- The clean shutdown needs the cloning-vm image from this update on; with an older one the stop reports "No QEMU monitor reachable" and halts the VM hard right away.

### Resources

Defaults are 2 GB RAM (allowed 1–128 GB), 2 vCPUs (up to 24), a 60 GB disk and KVM acceleration on. You set RAM, CPUs and disk size per VM directly when starting it; the defaults are fixed in the server and cannot be configured. After a start or a restore the card takes over the values of the VM or the clone.

If the server has no KVM (for example because it is itself a VM without nested virtualization), the VM still starts with KVM acceleration switched on — in software emulation (TCG), much slower. Since the update of 2026-10-08 the info card of the running VM then shows **"Unavailable (TCG)"** for KVM, with a notice; before, it showed "On" anyway.

---

## Tab: ISOs

Manages installation ISOs that serve as boot media for the cloning VM.

### List

Table with file name, size, uploaded at.

### Upload

Two ways:

1. **"Upload ISO"** — file from your local machine. Accepts `.iso` only, upper limit 120 GB; for > 5 GB a direct URL download is more convenient.
2. **"Download ISO from URL"** — dialog with URL field, optional file name (otherwise derived from the URL). ThinForge fetches the file in the background and shows progress live (bar and bytes). Ideal for Debian, Ubuntu, Manjaro images directly from their mirror. Only `http`/`https` and public addresses are allowed — the server rejects sources on your own network (private, loopback or link-local addresses). Only one download runs at a time.

### Delete

Via the trash icon, after confirmation. ThinForge does not check whether the running VM is currently using the ISO — delete an ISO only once the VM is stopped.

### Tools ISO

The Tools ISO is built automatically by the server and is attached to the running cloning VM as a second CD drive (`THINFORGE_TOOLS`). It contains the setup scripts including client provisioning and the agent; with them you set up the agent in the image system before you save the image ([workflows/golden-image.md](workflows/golden-image.md)). Clients then receive the finished image via deployment. Its root also holds the license texts (`LICENSE`, `NOTICE`, `THIRD_PARTY_LICENSES.md`, `WRITTEN_OFFER.md`) — the agent is licensed GPL-3.0-or-later.

The Tools ISO is rebuilt automatically every time the cloning VM starts, and also after every agent build or upload under **Clients → Agent**. The VM only starts with the freshly built ISO: if the rebuild fails, it does not start, and the message names the reason. So after a certificate renewal or key rotation, you simply restart the VM.

The ISO carries the server's agent binary together with its signature. If the server has no built or no signed agent binary, no ISO is built and the cloning VM does not start; the message names the missing step (build or **Sign** under **Clients → Agent**). Only an admin may sign or create a missing signing key; the message says so. During setup the provisioning script checks the signature and only installs a correctly signed agent.

## Tab: VDI Clients

This is where you store the installation packages of the VDI clients that ThinForge does not ship for licensing reasons: Citrix Workspace App, Citrix USB-Support (ctxusb), Parallels Client and Omnissa Horizon Client. Each client has exactly one slot; the table shows whether a package is present, with file, size and upload time.

- **Upload** — Citrix, Citrix USB-Support and Parallels take a `.deb` file, Omnissa a `.bundle` or `.deb` file. The server stores the package under a fixed name; a new upload replaces the existing one.
- **Delete** — via the trash icon, after confirmation.

Uploaded packages are put on the Tools ISO the next time the cloning VM starts (folder `DebianVDIClients/`). At the end of `install-debian-minimal.sh finish` the script offers to install them in the image; to do it by hand, run `DebianVDIClients/install-vdi-clients-debian.sh` from the Tools ISO. Admins and operators may upload and delete.

---

## Create an image from the VM

In the **Create VM** tab you save the VM state as a deployable image (the VM must be **stopped**). The dialog picks the right mode automatically. Alongside, **"Create Clone"** saves the disk without a delta as the start of a new image line (name and optional comment).

### Create baseline

- Takes a baseline snapshot of the VM and starts a new version chain
- Chosen automatically the first time (no clones or snapshots yet); afterwards selectable any time via the **"New base image (new version chain)"** option
- Requires an **image name** (line name, e.g. "Debian Workforce"); each image line counts its versions separately
- **When?** At the very start or for a clean new chain (e.g. after a major OS upgrade)

### Save update delta & create clone

- Creates a delta against the previous version **and** a complete, deployable clone image
- Fast and small (only changed blocks in the delta)
- **When?** For ongoing updates — security patches, config changes, new software

### Creating an image

1. The cloning VM must be **stopped** (while it runs, the button is disabled)
2. In the **Create VM** tab click **"Save update delta & create clone"**
3. In the dialog:
   - Choose **"Delta update (incremental)"** or **"New base image (new version chain)"** — the first time there is no choice
   - **Image name** — only for a new baseline, required
   - **Version** — assigned automatically in the format `vYYYY.MM.DD-NNN` (UTC date plus a per-day counter per image line), e.g. `v2026.06.22-001`
   - **Comment** — optional, short note on what changed
4. Save

Beforehand the server checks the VM's Btrfs layout. If it still has separate subvolumes from the Calamares default layout, the dialog **"Layout consolidation required"** asks first; **"Consolidate and save"** merges them into the root subvolume and then saves.

The operation runs in the background; progress is shown in the **Create VM** and **Clones** tabs ("Step 1/2: Generating delta", "Step 2/2: Creating VM clone"). Depending on disk size a full image takes 10–30 minutes, a delta usually 1–5 minutes.

### Cancel

While the operation is running, a **"Cancel"** button appears — not during the delta phase (step 1/2), which cannot be interrupted midway. Cancelling cleans up half-produced files — the VM itself is not damaged.

---

## Tab: Captures

The **Captures** tab, in contrast, captures the disk of a **physical client**: the device boots into a capture environment (Clonezilla) via PXE, and its disk state is saved as an image.

1. Pick the client (optionally filter by group first)
2. Give the capture a name
3. Under **"After Capture"** decide whether the device **shuts down** or **reboots** afterwards
4. **"Reboot the client now"** (on by default): a client reported online reboots into the capture via SSH right away, a powered-off one on its next power-on. Without the option you reboot it yourself.
5. **"Start Capture"**

The operation runs in the background; its state (Pending, Capturing, Done, Failed, Cancelled) is shown in the **Capture Jobs** list next to it. There a job can be cancelled, restarted or deleted; **Restart** prepares the device again and reboots it into the capture via SSH right away if it is reported online. The finished capture appears in the **Clones** tab with source **HW Clone**; **"Import"** in the job list registers it under an image name (1–80 characters) as a deployable image, and the version is assigned automatically.

A device that is part of a running clone deployment cannot be captured — and a device with a running capture cannot be deployed. Either would overwrite the boot entry of the other operation; the interface reports it until that operation has finished or been cancelled.

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

The **base** of a chain is determined automatically: it is the lowest version of its image line (clones with the same name). It carries the **Base** marker.

### Per-clone actions

The table shows per clone the version, source (**VM Clone** or **HW Clone**), name, comment, created at, disk and clone size. Markers: **Base**, **Active** (currently loaded in the VM), **obsolete** (older than every version installed on a client) and **Defective** (marked defective via rollback). Expanded, a row lists the clients still below this version.

- **Reassign** — moves the clone to a different position in the tree (see below)
- **Restore to VM** — writes the clone back onto the cloning VM (the VM must be stopped). This lets you switch back to an older version at any time. Make sure the clients end up on the older version too — either via a new deployment or via the rollback (which can only restore the immediately previous version).
- **Export** — download as a 7z archive, optionally encrypted with a password (at least 4 characters, ASCII characters only — no umlauts). Unencrypted, credentials stored in the image are readable by anyone who gets the file.
- **Delete** — shows the consequences first. Blocked while a running deployment uses the clone or an active update assignment (**Updates** tab) targets this version. If clients run this version you must confirm the impact; for the last clone of a chain the associated deltas can be deleted as well.

**"Import"** in the tab header uploads an exported 7z archive again (password only for an encrypted export); the clone keeps its version. If the line name is already taken, the dialog asks for a new name. During the import, the archive and the unpacked clone sit side by side on the server — so it needs roughly twice the archive size plus 2 GB of headroom. ThinForge checks this when the upload starts and again before unpacking; if there is not enough space, the import stops with a message stating the free and the required space, and nothing is left behind.

### Reassign / sort in

Sometimes clones should be reordered in the tree — e.g. when a re-imported clone belongs at a different position, or when a parent-less clone should be threaded into an existing chain.

- **"Assign as child"** — attaches the clone as the next child of a selected parent
- **"Insert before clone"** — inserts the clone before an existing clone. It is only offered when the name contains a version that precedes the target version: a date-based version such as `v2026.05.07-001` or an older number such as `v1.002`. Date-based versions only work within the same image line — the name consists of the line name and the version (e.g. "Manjaro v2026.05.07-001" before a clone of the line "Manjaro"), and the clone takes the line name afterwards. Older numbers need the same major number (`v1.…` before `v1.…`); the name stays.
- **"Remove assignment"** — only for clones with a parent: removes the clone from its chain and turns it into a standalone new baseline

These operations are **purely logical** — they only modify metadata, not the image itself. Delta generation still follows the physical snapshot chain from the capture moment.

---

## Keep an eye on disk space

Clones can be large (several GB per baseline, a few MB to GB per delta). The dashboard **Server Storage** card shows the values. Typical cleanup:

- **Remove old baselines no longer distributed** — careful: only when no live clients still use them
- **Consolidate old deltas** — via "New base image" on the current leaf version, then drop the old chain
- **Delete unused ISOs**

## Next steps

- [06 — Rollouts](06-rollouts.md) — distribute a clone to clients
- [workflows/golden-image.md](workflows/golden-image.md) — build the first baseline from scratch
- [workflows/deploy-update.md](workflows/deploy-update.md) — roll a delta update to a group
