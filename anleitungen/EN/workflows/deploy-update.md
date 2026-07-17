# Workflow — Deploy an update to a group

Change to the golden image (security patch, new software version, config tweak) → delta capture → wave-based rollout to the client fleet.

## Preconditions

- [ ] An existing clone chain (baseline + possibly some deltas) exists
- [ ] Target group(s) defined ([04](../04-groups.md))
- [ ] Pilot group with 1–3 test clients (optional but strongly recommended)

## Step 1 — Start the cloning VM (with the existing disk)

The VM has the disk from the last capture — starting "without ISO" boots that exact disk.

1. **Cloning → Cloning VM**
2. **"Start VM"** → dialog → **no ISO** (the existing disk is booted)
3. **Open VNC**

## Step 2 — Apply changes

In the VM:

- Security updates (`apt upgrade`, `pacman -Syu`, Windows Update)
- Install / upgrade software
- Adjust configuration
- Whatever else

**Tested in a kiosk / production scenario?** Before the capture goes out, make sure nothing obvious is broken.

## Step 3 — Shut the VM down

Clean shutdown from within the VM. VM status goes "inactive".

## Step 4 — Delta capture

1. **Cloning → Captures**
2. **"Save update"** → dialog:
   - **Version** — next number, e.g. `v2026.06.22-005` (usually auto-suggested)
   - **Comment** — concise; e.g. "Chromium 126, libssl CVE patch"
   - **"As new baseline"** — **do not** enable (we want delta, not baseline)
3. Start

Capture runs 1–5 minutes. Delta is computed against the previous version, lands in `/data/deltas`, and is signed.

## Step 5 — Pilot rollout

First on a few test clients:

1. **Rollouts → + New rollout** ([06](../06-rollouts.md))
2. **Name**: `2026-04-15 pilot — v2026.06.22-005`
3. **Target**: client list → select the 1–3 pilot clients
4. **Image**: `v2026.06.22-005`
5. **Method**: unicast (simple, few clients)
6. **Schedule**: start now
7. Save

Track on the rollout detail page until all pilot clients are `done`.

## Step 6 — Verify the pilot

Minimum check-list:

- [ ] Clients rebooted and are back online
- [ ] Agent running (`systemctl status thinforge-agent` via the terminal)
- [ ] Version column shows `v2026.06.22-005`
- [ ] User-side nothing obviously wrong (apps start, network works, printers work)
- [ ] No error traces in tasks ([08](../08-tasks-logs.md))

**Let it run at least 24 h** in pilot before broad rollout.

## Step 7 — Broad rollout

When the pilot is solid:

1. **Rollouts → + New rollout**
2. **Name**: `2026-04-15 broad — v2026.06.22-005`
3. **Target**: group (e.g. "Branch North", "all POS")
4. **Image**: `v2026.06.22-005`
5. **Method**:
   - **Multicast** when everyone is on the same LAN → fast, bandwidth-friendly
   - **BitTorrent** when across VPN / multiple sites → clients share data
   - **Unicast** for a couple of dozen clients and none of the above applies
6. **Schedule**:
   - Now, or
   - Overnight (for POS scenarios where clients are off but Wake-on-LAN is set)
7. Save

## Step 8 — Monitor progress

On the rollout detail page:

- Per-client status list — watch for `failed`
- Click a failed client → error details
- Timeline shows pace

**On issues:**

- Individual failed clients: re-roll manually, move into rescue mode → fix locally
- Clustered failures (> 10 % failed): **pause the rollout**, clarify root cause before more clients are affected

## Step 9 — Close

Rollout switches to `completed`. Final check:

- Dashboard Compliance card: should be near 100 % of the target group on `v2026.06.22-005`
- Filter the clients list for deviators (status + version columns), deal with them individually

## Pitfalls

- **Delta capture fails** → usually the VM did not actually shut down, or the previous snapshot was deleted manually. Check task details.
- **Multicast rollout does not reach clients** → IGMP snooping must be active on the switch, or the subnet blocks multicast. Fall back to unicast.
- **BitTorrent rollout stalls** → another BT rollout running in parallel? Only **one** works at a time.
- **Pilot clients do not return after reboot** → the agent update itself had a bug or the signature no longer fits. Rollback individually ([client-rollback.md](client-rollback.md)).

## Next steps

- [workflows/client-rollback.md](client-rollback.md) — when it went wrong
- [06 — Rollouts](../06-rollouts.md) — deployment methods in detail
