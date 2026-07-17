# Workflow — Onboard a new client

A freshly unboxed thin client from carton to a green status indicator on the dashboard. This workflow assumes the **normal case**: client is on the management network, DHCP works, a golden image already exists as a clone.

## Preconditions

- [ ] ThinForge server running, web UI reachable
- [ ] DHCP/PXE profile active ([07](../07-network.md#tab-dhcp--pxe))
- [ ] At least one clone (baseline) in the Cloning view ([05](../05-cloning.md)) matching this hardware
- [ ] The physical client is plugged into the management network and capable of PXE boot

## Step 1 — Tools ISO (once per infrastructure)

The Tools ISO carries the provisioning script, the agent binary, the VPN keys, and the server certificate. It is built automatically after first setup — after certificate or key rotation it must be rebuilt.

1. **Cloning → ISOs**
2. Find the entry **"thinforge-tools.iso"**
3. Click **"Rebuild"** (~1 minute)

## Step 2 — Determine the MAC and create the client

DHCP and PXE only serve **clients that already exist** — an unknown MAC is ignored and gets neither an IP nor the boot chain. So the client must be created **first** before it can boot at all.

1. **Determine the MAC address** — from the device label, the BIOS/UEFI network screen, or your inventory list. (Not from a DHCP lease — while the device is unknown there is none.)
2. **Clients list** ([03](../03-clients.md)) → **"+ Add client"** → enter the MAC (optionally group, room, and inventory details) → save. For many devices at once: CSV import.

## Step 3 — Power on and provision the client

- Connect the device to power and network
- In BIOS/UEFI: enable PXE boot for the network adapter (default on most thin clients)
- Boot

Because the MAC is now known, the client obtains an IP via DHCP, loads the PXE boot chain, boots into the Tools ISO, and there automatically starts the provisioning script.

**While this runs** (~3–5 minutes):
- The DHCP lease appears under [07 — Network → DHCP/PXE → Leases](../07-network.md#leases) — handy to check whether the registered device received an IP
- The provisioning script writes the partition table, installs the agent, fetches the baseline via unicast/BitTorrent, configures VPN

After the reboot the agent sends heartbeats. Since the client already exists, they are accepted immediately and the device appears with "Online" status (version = rolled-out baseline) in the clients list and on the dashboard.

## Step 4 — Assign

- **Clients list** → mark the new client → **"Assign group"** → choose the target group ([04](../04-groups.md))
- Optional: change the **hostname** (detail tab → Overview → Edit); the new name is applied on the next agent heartbeat

## Step 5 — Verify

- **Terminal** on the client ([03](../03-clients.md#terminal-web-ssh)): `hostname`, `df -h`, `systemctl status thinforge-agent`
- If VPN is in use: **VPN tab** on client detail, last-handshake should be < 2 min ago

## Pitfalls

- **No DHCP** → Does the device exist? Unknown MACs get no DHCP. Otherwise check switch configuration (IGMP/helper) and the server subnet settings
- **Client boots into BIOS menu instead of PXE** → check BIOS boot order; disable Secure Boot for legacy PXE if needed
- **Provisioning script aborts** → old TLS certificate in the Tools ISO? Repeat step 1
- **Client shows up with the wrong hostname** → that's the DHCP hostname; at the first agent heartbeat the real one takes over. Wait a few minutes.

## Next steps

- [workflows/deploy-update.md](deploy-update.md) — when a new version is ready
- [03 — Clients](../03-clients.md) — daily management
