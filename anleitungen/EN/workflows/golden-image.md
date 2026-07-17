# Workflow — Create a golden image

From a fresh ISO to the first baseline that can be rolled out to clients.

## Preconditions

- [ ] ThinForge server running
- [ ] Cloning VM resources sufficient (RAM, disk adjusted in `.env` if needed)
- [ ] Installation ISO ready (either on your local machine or as a URL)

## Step 1 — Provide the ISO

Two ways in **Cloning → ISOs** ([05](../05-cloning.md#tab-isos)):

- **Upload** — when the ISO lives on your machine
- **By URL** — fetch directly from a mirror (works well for Debian, Ubuntu, Manjaro)

After a successful upload/download, the ISO appears in the list.

## Step 2 — Start the cloning VM

1. **Cloning → Cloning VM** ([05](../05-cloning.md#tab-cloning-vm))
2. **"Start VM"** → dialog:
   - Select **ISO**
   - Adjust RAM / CPU / disk size if needed (default 2 GB / 2 CPU / 60 GB)
   - Start
3. Wait until the VM is running (~30 s)
4. Click **"Open in VNC"** — a new browser tab opens the running VM

## Step 3 — Install OS and customise

In the VNC window you work like on a physical PC:

1. **Install the OS** — normal installer flow (partitioning, create user, network)
2. **Prepare for ThinForge agent** — the provisioning script expects a certain structure. Recommended prep work:
   - Create the `/data` partition (see scripts in the Tools ISO — they run automatically at client deploy time)
   - Enable the SSH server
   - The agent runs on the actual client via the provisioning script — you do **not** install it manually here
3. **Install software** — everything that should later run on every client (browser, office suite, kiosk software, …)
4. **Remove personalisation** — delete user-specific settings, test files, clear bash history

**Tip:** do not hardcode anything hostname- or MAC-specific — it would be identical on all clients. The agent personalises these at deploy time per device.

## Step 4 — Shut the VM down

In the VNC window a regular shutdown (e.g. `sudo poweroff`). The cloning VM view goes "inactive" after 1–2 seconds.

**Important:** the VM must be stopped before the capture starts.

## Step 5 — Baseline capture

1. **Cloning → Captures** ([05](../05-cloning.md#tab-captures))
2. Click **"Save update"**
3. Dialog:
   - **Version** — first release: `v2026.06.22-001`
   - **Comment** — "initial baseline, Debian 12 with kiosk software"
   - **"As new baseline"** — **enable the checkbox** (baseline mode)
4. **Start**

The capture runs (10–30 min depending on disk size). Progress:
- Here in the Captures tab
- In Tasks ([08](../08-tasks-logs.md#tasks))

## Step 6 — Clone appears

After completion switch to the **Cloning → Clones** tab. The new entry `v2026.06.22-001` is shown as **baseline** (root of the chain). Metadata, size, comment are visible.

## Step 7 — Test rollout

Before the clone goes into production — always verify on a test device first.

1. Onboard a test client ([workflows/first-client.md](first-client.md))
2. Rollout to this single client ([06 — Rollouts](../06-rollouts.md))
3. Verify: remote desktop, terminal, functional tests

## Pitfalls

- **VM does not start** → port/resource conflict (`.env` `CLONING_VM_MEM_LIMIT`) or the ISO file is broken. Logs ([08](../08-tasks-logs.md#logs)) → Cloning VM source.
- **Capture aborts** → usually disk space on the host. Check the Disk Usage card on the dashboard.
- **Clone much larger than expected** → temp files in the VM not cleaned up, swap file large. Before capture: `sudo sync; sudo fstrim -av` in the VM.

## Next steps

- [workflows/deploy-update.md](deploy-update.md) — ship the first change as a delta
- [05 — Cloning](../05-cloning.md) — details on version tree and reassign
