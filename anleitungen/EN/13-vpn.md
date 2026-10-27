# 13 — VPN

This guide describes setting up ThinVPN and activating VPN clients from the user's point of view. ThinVPN is ThinForge's VPN service; it registers with a **VPN instance** (the management platform the devices build their tunnels to) and manages everything it needs there by itself. You never have to create anything by hand in the dashboard of NetBird, which the VPN instance is built on — whatever there does not originate from ThinForge is removed again by the next reconcile run.

Menu: **VPN entry** (in the sidebar). Setting up, activating, deactivating and exposures are administrator tasks; operators see the view read-only.

> **Recommendation:** For the VPN feature you should book the **VPN option from ThinForge**. To unlock it, [thinforge.org](https://thinforge.org) provides a **URL** and a **key** (= the VPN management URL and the access token, see Prerequisites) with which you activate the VPN feature. Terms: [price table](https://thinforge.org/#preise).

## First visit — VPN not set up yet

As long as no connection to the VPN instance is set up, the view shows only the card **"ThinVPN not set up"** with the button **"Set up ThinVPN"** (administrators only; operators see a notice at this point).

### Prerequisites

- **VPN management URL** (e.g. `https://teststellung01.thinforge.org`)
- **Access token** — the key you receive from thinforge.org after booking the VPN option.
- A finished network configuration under **Network → Local Network** (the server IP in the client network is needed for the VPN).
- For activating devices: a subscription with free VPN seats ([11 — Subscription](11-licensing.md)).

Which ports server and devices have to reach on the outside for this (TCP 443 to the host of the VPN management, e.g. `teststellung01.thinforge.org`, nothing more) is listed in [15 — Firewall Rules](15-firewall.md#vpn).

> **Caution:** Do not confuse this with an *activation key* (setup key). Activation keys are device-specific and are generated automatically by the backend when you activate a VPN client — you never have to enter them yourself.

Has thinforge.org delivered these details (URL and key) after you booked the VPN option? If so, click **"Set up ThinVPN"**.

## Setup wizard

The wizard runs in five steps: **Connection → Existing data → Register server → Apply baseline → Done**.

### Step 1 — Connection

| Field | Input |
|---|---|
| VPN management URL | Full address with `https://` prefix. An `http://` address is accepted, but with a warning: the access token would then cross the network unencrypted on every call. |
| Access token | The key from the booking |

Clicking **"Test connection & continue"** checks the details against the VPN instance and then saves them; a token the instance accepts but that may not read everything the reconciliation needs (groups, policies, DNS groups, setup keys) is refused and not saved. On success the wizard moves to step 2; on an error the message appears in the dialog ("The instance does not answer at this address.", "The instance rejected the token." — also for a token the instance does not or no longer knows — or "No management API of the VPN instance answers at this address …" when the URL points at the dashboard instead of the management API). The token is never shown again — not even masked.

### Step 2 — Existing data

The wizard reads what is already on the VPN instance and shows it. Nothing happens by itself — you choose the way:

| Data found | Way |
|---|---|
| The instance is empty | **"Continue"** — ThinForge creates its objects from scratch. |
| Data of this ThinForge installation (e.g. server reinstalled) | **"Restore"** — the data is adopted; connected devices keep working without interruption. |
| Data of another ThinForge installation or of an earlier ThinForge version | **"Adopt"** after ticking a box — this server becomes the sole administrator of the instance. |
| Data that does not originate from ThinForge | Only **"Wipe"** (deletes all data, after a second confirmation) or **"Cancel"**. |

**"Wipe"** is available for every non-empty instance, but always demands a second confirmation with a checkbox: peers, groups, rules, networks, DNS groups and setup keys of the instance are removed, connected devices lose their access, the step is irreversible.

### Step 3 — Register server

Here the ThinForge server itself is registered with the VPN instance. The detected hostname and the LAN subnet are shown. Clicking **"Register"** completes the step; it can take up to two minutes. After a restore in which the server peer already runs on this machine, the wizard skips the step.

### Step 4 — Apply baseline

Clicking **"Apply & verify"** writes ThinForge's basic rules to the VPN instance and checks the result right away. "The instance matches the target state." means: everything is set. If steps are still outstanding, that is normal right after setup — reconciliation keeps running every minute, the current state is shown in the **State** tab.

### Step 5 — Done

**"ThinVPN is set up"** — **"Done"** closes the wizard.

## Normal tab content (after setup)

After setup the view shows two fixed areas at the top:

1. **Status bar** (top): green chip "ThinVPN active", the number of active clients and — only if there are any — the number of deviations between target and actual state.
2. **VPN connection**: the VPN management URL and the check status ("Connected (last checked …)", "Error (…)" or "Not checked yet"). Actions: "Test connection", "Enter credentials again", "Release connection".

Below follow four tabs:

- **Clients**: the devices per group with their VPN status — if the device's agent reports a different state of the ThinVPN service ("error", "installed, off" or "not installed"), a small hint "Device reports: …" appears next to it, explained on hover (since the update of 2026-10-07) —, activate and deactivate (individually or "Activate entire group"), plus "Re-enroll fleet" for moving to a different VPN instance.
- **Exposures**: the exposures you created and, below them, the fixed basic rules (baseline), which cannot be changed.
- **State**: the reconciliation between target and actual state with "Check" and "Apply now", the reconcile log and the backup (export/import of the exposures).
- **Tasks**: the running and completed VPN tasks — per row client, task ("VPN Key Setup", "VPN Re-enrollment", "VPN Config Removal"), status, start and end time. The "Error" column is only filled for failed tasks — since the update of 2026-10-20 in the language of the interface, with the server's untranslated raw message after it; that is also where "Retry" appears. "Completed" means: the server has done its part — the key goes to the device with the next status sync, or the access has been revoked. Whether the device is connected is shown in the **Clients** tab. (Until the update of 2026-10-20, completed tasks showed a German note in red in the "Error" column — that was not an error.)

> **"Release connection"** separates this ThinForge installation from the VPN instance. Locally, the exposures with their rules and the corresponding DNS entries are removed, and this server's VPN service is shut down permanently. **On the VPN instance everything stays in place** — rules, network and the accesses of all devices — but is no longer reachable from ThinForge and can only be removed there. To keep the exposures, export them beforehand in the **State** tab. Setting up again starts with the wizard.

> **"Enter credentials again"** opens the wizard again. An unchanged token leaves everything as it is. A **different** token is checked against the VPN instance before it is stored: if the instance carries this installation's identifier, the setup stays as it is and the wizard finishes with "Setup kept"; if the token belongs to another instance or that cannot be verified (instance unreachable, token rejected), the setup falls back to "not adopted" — then choose **"Restore"** in the Existing data step. A token the VPN instance accepts but that may not read everything the reconciliation needs (groups, policies, DNS groups, setup keys) is refused on save — the previous token stays. A URL pointing at a different VPN instance is refused as long as exposures are attached to the current one: first "Release connection", then set up again.

Once the connection is set up, internal names (e.g. `thinforge-server` or hosts of the local domain) resolve automatically on the devices through the tunnel. This requires a local domain set under **Network → DNS** (section "Local Domain", field "Domain Name", see [07 — Network](07-network.md)).

## Configuring clients and exposures

In the **Clients** tab the devices are grouped by the ThinForge group they belong to; shown are the groups with the VPN flag set ([04 — Groups](04-groups.md)) plus every device that still holds VPN access. There are no separate VPN groups: all activated devices belong to the fixed group "Clients", and the exposures decide what they may reach. Which devices hold VPN access is also visible in the device list (column "VPN" with a shield icon, filter "VPN enabled", see [03 — Clients](03-clients.md)).

The actual **exposures** are created in the **Exposures** tab via **"New exposure"**. A wizard guides through four steps — **Target → Access → Preview → Apply & verify**:

- **Name**: a label for the exposure (e.g. "W22").
- **Target address**: the target that should become reachable — either a single IP (a single host, e.g. `192.168.20.3`) or a whole subnet in CIDR notation (e.g. `192.168.20.0/24`). The target must lie in the client network.
- **DNS name** (optional): a hostname under which the target resolves for all clients; requires a local domain. The name `thinforge-server` is reserved.
- **Source group**: who may connect — currently only "Clients", i.e. all devices activated through ThinForge.
- **Rules**: per rule a protocol (TCP, UDP, ICMP or all) and the exposed ports (single ports, comma-separated; empty means all ports). Presets for RDP, VNC, HTTPS and SSH append ready-made rule rows.

The **Preview** shows which objects are created on the VPN instance; **"Apply & verify"** saves the exposure, triggers the reconcile and waits for its result. A saved exposure can be edited in the table via the pencil icon, switched on and off via the toggle, and removed via the delete icon after confirmation — the dialog says beforehand what disappears on the VPN instance.

> **Default behavior:** A freshly activated client reaches **only the ThinForge server** on its own (for name resolution and management) — nothing else. Every further access has to be allowed explicitly as an exposure. So if you want the clients to reach a single host or a whole subnet in the company network, you enter that target as an exposure. That is how "server only" (no additional exposure) differs from "subnet" (one exposure with a subnet address).

## Activating VPN for a device

In the **Clients** tab find the client and click **"Activate"** in the actions column. ThinForge checks whether the subscription has a free seat, generates an activation key and sends it to the device with the next status check-in. As long as the order has not been picked up, the row shows "Activation pending", then "awaiting first connection"; as soon as the client has registered, the status changes to **"active"**.

Important: the activation key **does not expire**. You can prepare devices in advance even if they only go into the home office weeks later.

> **Prerequisite:** The client receives the configuration only once it is switched on and reaches the ThinForge server — usually on the LAN. The agent picks up the activation key during the status check-in and sets up the tunnel; if the client network has no internet access, registering with the VPN instance only succeeds at the place of use. That is not an error and may take as long as it takes.

After that the client builds the tunnel **fully automatically** as soon as the device reaches the VPN instance (usually: as soon as it has internet) — the employee does not have to start, click or enter anything. In the office, i.e. on the ThinForge server's LAN, the tunnel stays up; the device then merely reports that it is connected locally, and the server reaches it directly over the LAN.

## Deactivating VPN for a device

Click **"Deactivate"** in the table — a confirmation dialog appears. On confirmation the device's access on the VPN instance is removed immediately; the device shuts down its VPN service on the next status check-in and deletes the local credentials. The subscription seat becomes free.

Re-activation is possible at any time (creates a new activation key).

> **Devices that reach the server only through the VPN** — for example at a site without a connection to the ThinForge server's local network; the server recognizes this because the device's last heartbeat came through the VPN tunnel: Deactivating such a device also takes away its only path to the ThinForge server. A re-activation is delivered during the status check-in and only reaches the device once it is back on the server's local network — so it can **only be re-enrolled on site**. In this case the confirmation dialog warns explicitly and requires an additional checkbox; without it the server refuses the deactivation and changes nothing. For a lost device, deactivating (with the checkbox) remains the right way — access is revoked immediately afterwards.

## FAQ

**Does the employee in the home office have to do anything?**
No. The VPN client starts automatically as soon as the device reaches the VPN instance (usually: as soon as it has internet) — in the office as at home.

**What happens if a device is lost?**
Deactivate the client in the VPN tab — VPN access is revoked immediately, even if the device is no longer reachable.

**Can I activate several employees at once?**
Yes, activations run independently of each other; "Activate entire group" handles a group in one step.

**What happens if the VPN instance is briefly unreachable?**
Existing VPN connections keep running. New activations and reconciliation are only possible once the VPN instance answers again; until then the status bar reports "VPN management unreachable".

**Why do I see "VPN subscription limit reached"?**
Your subscription allows only a certain number of activated clients (VPN seats). Solution: deactivate a client that is no longer needed, or upload a subscription file with more seats ([11 — Subscription](11-licensing.md)). "Activate entire group" stops at the first device without a free seat; the devices activated up to then stay activated.

**What does "Device reports: …" next to the status mean?**
The status itself is the state derived by ThinForge (activated? listed as connected by the VPN instance?). The small hint next to it is the agent's report about the ThinVPN service on the device: "installed, off" means the ThinVPN client is present but not running — normal for deactivated devices; "not installed" (only for activated devices) means the `netbird` package is missing on the device and has to be installed, or the device re-imaged with a suitable image; "error" means the agent could not query the ThinVPN service — then check the agent's journal on the device. Hovering shows the explanation.

**What happens when an activated device is re-cloned?**
The deployment resets the VPN pairing itself and issues a fresh activation key — the device re-registers on its own after the clone. If the connection to the VPN instance has been released, that is not possible; the warning dialog before the deployment says so ([06 — Rollouts](06-rollouts.md#rollouts-and-vpn)).

## Further reading

- Subscription and VPN seats: [11 — Subscription](11-licensing.md)
- Local domain and DNS: [07 — Network](07-network.md)
- Rollouts, delta updates and VPN: [06 — Rollouts](06-rollouts.md#rollouts-and-vpn)
