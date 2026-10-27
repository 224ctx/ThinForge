# 4 — Groups

Groups are the primary organization tool for the client fleet. Typical reasons to group clients:

- **Location** — Branch A, Branch B, HQ
- **Role** — POS, training, back office, info kiosk
- **Hardware generation** — different image variants for old vs. new devices
- **Rollout waves** — pilot, early adopter, broad rollout
- **VPN reach** — clients on the local LAN vs. clients connecting via the VPN (field service, home office, branch-office kiosks). The group's VPN flag decides which devices can be activated in the VPN menu ([13](13-vpn.md)); clone deployments run on the LAN only, VPN clients receive delta updates ([06](06-rollouts.md#rollouts-and-vpn)).

A client belongs to **at most one** group. Groups can be nested (parent / child), which enables "Branch A → POS" for example.

## Groups overview

The **Groups** menu entry shows a tree view:

```
HQ (42 clients)
├── Back office (12)
└── Training (8)
Branch North (25)
├── POS (15)
└── Info kiosk (10)
Branch South (18)
```

Each row shows the group name, the number of directly assigned clients and the number of subgroups; nesting is shown by indentation, to any depth. The pencil at the end of the row opens the edit form.

### Per-group actions

- **Show details** (click the row) — key figures (clients, parent group, subgroups), the group's most recent clone deployment with progress and buttons to cancel, restart failed and cancelled clients (shown as soon as at least one client has failed) and delete, and below it the **Contained Clients** table (inventory number, hostname, MAC address, status, room; clicking opens the device)
- **Distribute an image** — the group view no longer has a button for this. Create a deployment for the group under **Cloning → Deployments** with the target "group" ([06](06-rollouts.md)); the group view then shows it.
- **Edit** — rename, change description, move parent
- **Delete** (admins only, button in the edit form) — an empty group is deleted after the usual confirmation. If subgroups, clients, task templates or uploaded certificates are still attached, the interface lists every consequence and asks whether to force the deletion: subgroups move up one level, clients become "ungrouped", templates are switched off, certificates deleted. (Until the update of 2026-10-03 the server refused a group with subgroups or clients without VPN access, and the deletion could not be forced.) Ungrouped clients can be found in the client list with the group filter "No group". If devices with active VPN access belong to the group, the dialog force-deletes it after its own confirmation: subgroups move up one level, clients become "ungrouped". If subgroups, task templates or uploaded certificates are attached as well, it asks first as described above (until the update of 2026-10-02 the VPN path skipped that question). The question names everything of that kind that is attached.

## Creating a new group

1. In the groups overview, top right, click **"+ Create Group"**
2. **Name** (unique), **description** (optional)
3. **Parent group** — none if top level. An existing subgroup can be promoted back to root level via **Edit** → clear the parent group → Save.
4. **Save**

The group is empty. Add clients via the clients list (bulk action → assign group) or directly in the client detail view.

## Assigning clients

Two ways:

### From the clients list

1. Menu → **Clients**
2. Select clients via checkbox (also "select all" for filtered results)
3. In the bar above the table, pick the group in the **"Assign Group"** field
4. **Apply**

### From the client detail view

1. Menu → **Clients** → click the device
2. Pick the group in the **Groups** field
3. **Save**

The group can also be set when creating clients — in the **"Register Client"** form or during CSV import via the `gruppe_name` column (the import creates missing groups after asking).

## Filtering in other views

The group assignment is filterable throughout:

- **Clients list** — "Groups" dropdown in the filter row
- **Deployments, updates and rollback** — target selection: group instead of client list
- **Reports** — group column in the compliance report, utilization and distribution per group in the "Usage" report

## Sub-groups

Sub-groups are purely **organizational** (tree view, filtering). An action — e.g. a rollout — applies **only to the clients directly assigned to the selected group** and is **not** propagated to sub-groups.

To reach a parent group together with its sub-groups, select the groups individually or use a client list.

## Best practices

- **Keep group names short** — they appear in many dropdowns; long names get truncated.
- **Consistent naming** — e.g. always `Location / Role`. Saves searching and typos.
- **Not too flat, not too deep** — 2–3 levels usually suffice (Location → Role). More becomes unwieldy.
- **A "Quarantine" group** — practical for freshly-provisioned clients that need testing before moving into production groups.

## Next steps

- [06 — Rollouts](06-rollouts.md) — start deployments to groups
- [workflows/deploy-update.md](workflows/deploy-update.md) — wave-based rollouts
