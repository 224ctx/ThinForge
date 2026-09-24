# Workflow — Create a golden image

From a fresh ISO to the first baseline that can be rolled out to clients.

## Preconditions

- [ ] ThinForge server running
- [ ] Enough memory and disk space on the host for the cloning VM (you set RAM, CPUs and disk size in the interface)
- [ ] Installation ISO ready (either on your local machine or as a URL)

## Step 1 — Provide the ISO

Two ways in **Cloning → ISOs** ([05](../05-cloning.md#tab-isos)):

- **Upload ISO** — when the ISO lives on your machine
- **Download ISO from URL** — fetch directly from a mirror (works well for Debian, Ubuntu, Manjaro; public addresses only)

After a successful upload/download, the ISO appears in the list.

## Step 2 — Create the base disk and start the cloning VM

1. **Cloning → Create VM** ([05](../05-cloning.md#tab-create-vm))
2. **"Create base HD"** → check the sizes (default 60 GB total) → **Apply**. Without this disk the VM does not start; an existing one is overwritten.
3. On the card:
   - Select **ISO**
   - Adjust RAM / CPU if needed (default 2 GB / 2 CPU)
4. **"Start VM"** — the server rebuilds the Tools ISO on the way and attaches it as a second drive
5. Wait until the VM is running and the console appears (~30 s). It is embedded in the tab; **"Open in new tab"** shows it in its own browser tab

## Step 3 — Install OS and customise

In the console you work like on a physical PC. The setup scripts live on the second CD drive **THINFORGE_TOOLS**; the quick guide `INSTRUCTIONS_EN.md` on it describes the steps per distribution:

1. **Prepare the installation** — for live ISOs with Calamares (Debian, Manjaro, Arch, CachyOS) run `sudo bash install-<distribution>.sh prepare` in a terminal (for Debian with the target disk, e.g. `prepare /dev/vda`); the Debian netinst ISO skips this step
2. **Install the OS** — installer with manual partitioning on the prepared partitions (root as subvolume `@root`), create user, network. Then stop the VM, deselect the ISO, start the VM
3. **Set up the ThinForge agent** — in the installed system run `sudo bash install-<distribution>.sh finish` from THINFORGE_TOOLS. The script sets up GRUB with snapshots, the `/data` partition, SSH (key only) and the agent including its signature check
4. **Install software** — everything that should later run on every client (browser, office suite, kiosk software, …)
5. **Remove personalisation** — delete user-specific settings, test files, clear bash history

**Tip:** do not hardcode anything hostname- or MAC-specific — it would be identical on all clients. The agent personalises these at deploy time per device.

## Step 4 — Shut the VM down

In the console a regular shutdown (e.g. `sudo poweroff`). The **Create VM** card shows **Stopped** within about 10 seconds.

**Important:** the VM must be stopped before you save the image. "Stop VM" ends the VM without shutting down the guest system — so shut it down yourself first.

## Step 5 — Save the baseline

1. **Cloning → Create VM** ([05](../05-cloning.md#create-an-image-from-the-vm))
2. Click **"Save update delta & create clone"** — the first time the **Create baseline version** dialog opens
3. Dialog:
   - **Image name** — required, e.g. "Debian Kiosk"
   - **Version** — assigned automatically, first release e.g. `v2026.06.22-001`
   - **Comment** — "initial baseline, Debian 12 with kiosk software"
4. **Create baseline**

Saving runs (10–30 min depending on disk size). Progress is shown in the **Create VM** and **Clones** tabs.

## Step 6 — Clone appears

After completion switch to the **Cloning → Clones** tab. The new entry `v2026.06.22-001` carries the **Base** marker as the root of the chain. Name, comment, created at and sizes are visible.

## Step 7 — Test rollout

Before the clone goes into production — always verify on a test device first.

1. Onboard a test client ([workflows/first-client.md](first-client.md))
2. Deployment to this single client: **Cloning → Deployments** → **New Deployment** → **Individual Clients** ([06 — Rollouts](../06-rollouts.md))
3. Verify: remote desktop, terminal, functional tests

## Pitfalls

- **VM does not start** → no base HD created (the message names the missing disk), not enough memory on the host (the container gets the selected RAM plus 512 MB) or the ISO file is broken. Logs ([08](../08-tasks-logs.md#logs)) → Container Logs → Cloning-VM (QEMU). If the message on start mentions the agent binary or the signing key, a built agent binary correctly signed with the signing key (or the key itself) is missing — without it the server builds no Tools ISO and does not start the VM. The message names the way out: build or sign it under **Clients → Agent** (typical after a release update) or generate the key under **Settings → Security**.
- **Saving aborts** → usually disk space on the host. Check the **Server Storage** card on the dashboard.
- **Clone much larger than expected** → temp files in the VM not cleaned up, swap file large. Before saving: `sudo sync; sudo fstrim -av` in the VM.

## Next steps

- [workflows/deploy-update.md](deploy-update.md) — ship the first change as a delta
- [05 — Cloning](../05-cloning.md) — details on version tree and reassign
