# 4 — Groups

Groups are the primary organisation tool for the client fleet. Typical reasons to group clients:

- **Location** — Branch A, Branch B, HQ
- **Role** — POS, training, back office, info kiosk
- **Hardware generation** — different image variants for old vs. new devices
- **Rollout waves** — pilot, early adopter, broad rollout
- **VPN reach** — clients on the local LAN vs. clients connecting via WireGuard (field service, home office, branch-office kiosks). Bandwidth characteristics differ and matter when choosing a deployment method: multicast is LAN-only, unicast/BitTorrent for VPN clients.

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

Each row shows the group name, number of directly assigned clients, and a compact status bar (online/offline/version).

### Per-group actions

- **Show details** — all assigned clients, tag filter, average version
- **Start rollout** — all clients of this group receive an image
- **Edit** — rename, change description, move parent
- **Delete** — dissolves the group (clients become "ungrouped")

## Creating a new group

1. In the groups overview click **"+ New group"**
2. **Name** (unique), **description** (optional)
3. **Parent group** — none if top level. An existing subgroup can be promoted back to root level via **Edit** → clear the parent group → Save.
4. **Save**

The group is empty. Add clients via the clients list (bulk action → assign group) or directly from the client detail tab.

## Assigning clients

Two ways:

### From the clients list

1. Menu → **Clients**
2. Select clients via checkbox (also "select all" for filtered results)
3. Actions at the top → **"Assign group"**
4. Choose group, confirm

### From the group

1. Menu → **Groups** → Group detail
2. **"Add clients"** → dialog with available (unassigned) clients
3. Select, confirm

## Filtering in other views

The group assignment is filterable throughout:

- **Clients list** — "Group" dropdown at the top right
- **Rollouts** — target selection: "Group" instead of client list
- **Dashboard** — the Compliance card can be broken down per group

## Sub-groups

Sub-groups are purely **organisational** (tree view, filtering). An action — e.g. a rollout — applies **only to the clients directly assigned to the selected group** and is **not** propagated to sub-groups.

To reach a parent group together with its sub-groups, select the groups individually or use a client list.

## Best practices

- **Keep group names short** — they appear in many dropdowns; long names get truncated.
- **Consistent naming** — e.g. always `Location / Role`. Saves searching and typos.
- **Not too flat, not too deep** — 2–3 levels usually suffice (Location → Role). More becomes unwieldy.
- **A "Quarantine" group** — practical for freshly-provisioned clients that need testing before moving into production groups.

## Next steps

- [06 — Rollouts](06-rollouts.md) — start deployments to groups
- [workflows/deploy-update.md](workflows/deploy-update.md) — wave-based rollouts
