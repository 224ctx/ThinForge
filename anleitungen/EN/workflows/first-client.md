# Workflow — Onboard a new client

A freshly unboxed thin client from carton to a green status indicator on the dashboard. This workflow assumes the **normal case**: client is on the rollout network, DHCP works, a golden image already exists as a clone.

## Preconditions

- [ ] ThinForge server running, web UI reachable
- [ ] DHCP/PXE set up ([07](../07-network.md#tab-dhcp--dnsmasq))
- [ ] At least one clone (baseline) in the Cloning view ([05](../05-cloning.md)) matching this hardware
- [ ] The physical client is plugged into the rollout network (where ThinForge serves DHCP/PXE) and capable of PXE boot

## Step 1 — Tools ISO (once per infrastructure)

The Tools ISO carries the provisioning script, the agent binary, the heartbeat token, and the server certificate (it contains no VPN keys — those are only created when a device is activated in the VPN menu). A new client does not boot it itself: the ISO is attached to the cloning VM as a second drive, its setup script installs agent, SSH key, heartbeat token and server certificate into the golden image ([workflows/golden-image.md](golden-image.md)), and every clone carries them onto the client. The server rebuilds the ISO every time the cloning VM starts — not during setup, and there is no separate "Rebuild" button. After a certificate or key rotation, restarting the cloning VM is therefore enough ([05](../05-cloning.md#tools-iso)).

1. Under **Clients → Agent**, check that a built and signed agent binary is present — without it the server builds no ISO and the cloning VM does not start.
2. **Cloning** → start or restart the cloning VM; this produces the current ISO.
3. Set up the golden image with this ISO and save it as a clone — an older clone carries the state it was set up with.

## Step 2 — Determine the MAC and create the client

DHCP and PXE only serve **clients that already exist** — an unknown MAC is ignored and gets neither an IP nor the boot chain. So the client must be created **first** before it can boot at all.

1. **Determine the MAC address** — from the device label, the BIOS/UEFI network screen, or your inventory list. (Not from a DHCP lease — while the device is unknown there is none.)
2. **Clients list** ([03](../03-clients.md)) → **"+ Register Client"** → enter the MAC (optionally group, room, and inventory details) → save. For many devices at once: CSV import.

ThinForge assigns the computer name `TF-<MAC>` (e.g. `TF-D45D64A1B2C3`); it cannot be changed.

## Step 3 — Roll out the clone and boot the client

1. **Cloning → Deployments** → **"New Deployment"**: pick the new client as target (or its group if you set one in step 2), plus the clone and the method, e.g. unicast ([06](../06-rollouts.md))
2. Connect the device to power and network
3. In BIOS/UEFI: enable PXE boot for the network adapter (default on most thin clients)
4. Boot

Because the MAC is known and the deployment is armed, the client obtains an IP via DHCP, PXE-boots into Clonezilla and writes the clone to its disk.

**While this runs:**
- The DHCP lease appears under [07 — Network → DHCP / DNSMASQ → Leases](../07-network.md#leases) — handy to check whether the registered device received an IP
- The deployment shows the progress per client (Cloning → Deployments, expand the row)

Afterwards the client starts from its freshly written disk (post-deploy action "Reboot"). The agent from the image sends heartbeats; since the client already exists, they are accepted and the device appears with "Online" status (version = rolled-out baseline) in the clients list and on the dashboard. On first start the agent switches the operating system to the computer name `TF-<MAC>`.

## Step 4 — Assign

- **Clients list** → mark the new client → pick the target group in the **"Assign Group"** field → **Apply** ([04](../04-groups.md))
- Optional: add inventory number, room and user in the client detail view → **Save**

## Step 5 — Verify

- **Terminal** on the client ([03](../03-clients.md#terminal-web-ssh)): `hostname`, `df -h`, `systemctl status thinforge-agent`
- If VPN is in use: menu **VPN → Clients**, the device's row should show "active" and "connected", the last handshake should be < 2 min ago

## Pitfalls

- **No DHCP** → Does the device exist? Unknown MACs get no DHCP. Otherwise check switch configuration (IGMP/helper) and the server subnet settings
- **Client boots into BIOS menu instead of PXE** → check BIOS boot order; disable Secure Boot for legacy PXE if needed
- **Deployment stays "Pending" for the client** → the device did not PXE-boot: check boot order and network cable, then restart it.
- **Provisioning script aborts while setting up the golden image** → old TLS certificate in the Tools ISO? Repeat step 1. If it reports `signature check of the agent binary FAILED` or `thinforge-agent.minisig is missing`, the agent signature does not match the server's signing key → sign it under **Clients → Agent**, then repeat step 1. If `minisign` is missing in the VM, the script installs it and needs access to the package repositories for that.
- **Device still carries a different computer name** → the agent sets `TF-<MAC>` on first start; until then the name from the image applies. Wait a few minutes.

## Next steps

- [workflows/deploy-update.md](deploy-update.md) — when a new version is ready
- [03 — Clients](../03-clients.md) — daily management
