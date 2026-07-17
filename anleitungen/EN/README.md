# ThinForge — User Manual

This manual is for **IT administrators** who operate ThinForge through the web interface: manage thin clients, build images, roll out updates, and monitor the system in day-to-day operation.

## Where to start?

| Role | Starting point |
|------|----------------|
| New to ThinForge | [01 — Getting Started](01-getting-started.md) |
| Familiar with the UI, focus on clients | [03 — Clients](03-clients.md) |
| Onboard a new client | [workflows/first-client.md](workflows/first-client.md) |
| Build a golden image | [workflows/golden-image.md](workflows/golden-image.md) |
| Deploy an update | [workflows/deploy-update.md](workflows/deploy-update.md) |
| Fix a problem | [workflows/client-rollback.md](workflows/client-rollback.md), [08 — Tasks & Logs](08-tasks-logs.md) |

## Table of contents

**Basics**
1. [Getting Started](01-getting-started.md) — login, setup wizard, UI tour
2. [Dashboard](02-dashboard.md) — cards, status indicators, customisation

**Core areas**

3. [Clients](03-clients.md) — list, detail view, CSV import/export, boot modes, remote access
4. [Groups](04-groups.md) — assignment and filtering
5. [Cloning](05-cloning.md) — cloning VM, ISOs, captures, clones
6. [Rollouts](06-rollouts.md) — plan and start deployments

**Infrastructure**

7. [Network](07-network.md) — DHCP/PXE, DNS, VPN
8. [Tasks & Logs](08-tasks-logs.md) — jobs, logs, diagnostics
9. [Settings](09-settings.md) — services, TLS, users, signing keys

**Workflows (end-to-end)**

- [Onboard a new client](workflows/first-client.md)
- [Create a golden image](workflows/golden-image.md)
- [Deploy an update to a group](workflows/deploy-update.md)
- [Roll a client back to a previous version](workflows/client-rollback.md)

## Key terms

| Term | Meaning |
|------|---------|
| **Thin Client** | Physical endpoint (PC, laptop) running a ThinForge-managed OS image |
| **Clone** | A stored disk image with a version number (e.g. `v2026.06.22-004`), deployed to thin clients |
| **Capture** | The action of extracting a disk image from a running cloning VM |
| **Baseline** | The first version of a clone chain (`vX.000`), a complete image without a delta parent |
| **Delta update** | Incremental update from the previous clone to a new version (e.g. `v2026.06.22-004 → v2026.06.22-005`) |
| **Rollout** | Distribution of a clone to a list or group of thin clients |
| **Agent** | Small service on each thin client, handling heartbeat, updates, and remote commands |
| **Cloning VM** | Virtual machine on the server, used to install and modify the base OS |
| **Tools ISO** | Boot ISO for the initial provisioning of a new thin client |

## Roles in the system

- **Admin** — full access including user management, TLS, signing keys, factory reset
- **Operator** — day-to-day work: clients, cloning, rollouts, tasks
- **Viewer** — read-only: dashboard, client list

This manual takes the **operator** perspective. Admin-specific topics are grouped in [09 — Settings](09-settings.md).
