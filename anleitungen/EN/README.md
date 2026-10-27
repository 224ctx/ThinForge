# ThinForge — User Manual

This manual is for **IT administrators** who operate ThinForge through the web interface: manage thin clients, build images, roll out updates, and monitor the system in day-to-day operation.

## Where to start?

| Role | Starting point |
|------|----------------|
| Server freshly installed, no setup yet | [workflows/setup-wizard.md](workflows/setup-wizard.md) |
| New to ThinForge | [01 — Getting Started](01-getting-started.md) |
| Familiar with the UI, focus on clients | [03 — Clients](03-clients.md) |
| Onboard a new client | [workflows/first-client.md](workflows/first-client.md) |
| Build a golden image | [workflows/golden-image.md](workflows/golden-image.md) |
| Deploy an update | [workflows/deploy-update.md](workflows/deploy-update.md) |
| Deploy an image to several groups at once | [workflows/multi-group-deployment.md](workflows/multi-group-deployment.md) |
| Fix a problem | [workflows/client-rollback.md](workflows/client-rollback.md), [08 — Tasks & Logs](08-tasks-logs.md) |
| Turn on 2FA / change password | [10 — Profile & 2FA](10-profile-and-2fa.md) |
| Renew / upload a subscription | [11 — Subscription](11-licensing.md) |
| Check CVE status / TLS / signing key | [12 — Security](12-security-and-cve-scan.md) |
| Set up VPN for home-office access | [13 — VPN](13-vpn.md) |
| Compile data protection facts (record of processing activities, access requests) | [14 — Data Protection](14-data-protection.md) |
| Configure the company firewall for ThinForge (ports, hostnames) | [15 — Firewall Rules](15-firewall.md) |

## Table of contents

**Prerequisites**

15. [Firewall Rules](15-firewall.md) — ports, directions and hostnames for management network, client network, internet and VPN; allow them at the company firewall before installing

**Basics**
1. [Getting Started](01-getting-started.md) — login, setup wizard, UI tour
2. [Dashboard](02-dashboard.md) — cards, status indicators, customization

**Core areas**

3. [Clients](03-clients.md) — list, detail view, CSV import/export, boot modes, remote access
4. [Groups](04-groups.md) — assignment and filtering
5. [Cloning](05-cloning.md) — cloning VM, ISOs, captures, clones
6. [Rollouts](06-rollouts.md) — plan and start deployments

**Infrastructure**

7. [Network](07-network.md) — DHCP/PXE, DNS, VPN
8. [Tasks & Logs](08-tasks-logs.md) — jobs, logs, diagnostics
9. [Settings](09-settings.md) — services, TLS, users, signing, subscription overview

**Advanced (admin)**

10. [Profile & 2FA](10-profile-and-2fa.md) — own password, TOTP setup, forgotten password
11. [Subscription](11-licensing.md) — VPN seats, subscription file upload, behavior at the limit
12. [Security](12-security-and-cve-scan.md) — TLS, SSH provisioning keys, signing key, vulnerability scan, SBOMs, outgoing connections
13. [VPN](13-vpn.md) — ThinVPN setup, activating home-office clients
14. [Data Protection](14-data-protection.md) — stored data, retention, visibility, deletion and export

**Workflows (end-to-end)**

- [First installation with the setup wizard](workflows/setup-wizard.md)
- [Onboard a new client](workflows/first-client.md)
- [Create a golden image](workflows/golden-image.md)
- [Deploy an update to a group](workflows/deploy-update.md)
- [Deploy an image to several groups at once](workflows/multi-group-deployment.md)
- [Roll a client back to a previous version](workflows/client-rollback.md)

## Key terms

| Term | Meaning |
|------|---------|
| **Thin Client** | Physical endpoint (PC, laptop) running a ThinForge-managed OS image |
| **Clone** | A stored disk image with a version number (e.g. `v2026.06.22-004`), deployed to thin clients |
| **Capture** | Recording the disk of a physical client as an image — the device boots into a capture environment via PXE (Cloning → Captures) |
| **Baseline** | The first version of a clone chain (e.g. `v2026.06.22-001`; older chains still carry `vX.000`), a complete image without a delta parent |
| **Delta update** | Incremental update from the previous clone to a new version (e.g. `v2026.06.22-004 → v2026.06.22-005`) |
| **Rollout** | Distribution of a clone to a list or group of thin clients |
| **Agent** | Small service on each thin client, handling heartbeat, updates, and remote commands |
| **Cloning VM** | Virtual machine on the server, used to install and modify the base OS |
| **Tools ISO** | Boot ISO for the initial provisioning of a new thin client |

## Roles in the system

- **Admin** — full access. On top of what an operator may do: user management, TLS, signing keys, subscription, backup & restore, factory reset, saving the settings (operators also maintain maintenance windows), deleting clients and groups, **the entire network infrastructure** (DHCP, DNS, PXE, server interfaces), **service control** (starting, stopping and restarting containers) and the **Logs** menu (audit log and container logs, [08](08-tasks-logs.md))
- **Operator** — day-to-day work: clients, groups, cloning, capture jobs, images, rollouts, tasks
- **Viewer** — read-only: dashboard, lists, reports

Regardless of role, everyone may change their own password and turn two-factor sign-in on or off ([10 — Profile & 2FA](10-profile-and-2fa.md)).

This manual takes the **operator** perspective. Admin-specific topics are grouped in [09 — Settings](09-settings.md); the network settings in [07 — Network](07-network.md) became admin territory on 2026-08-31 as well.

> **A visible menu is not the same as an allowed action.** Since 2026-08-31 the role check lives consistently on the server. Since the update of 2026-09-30 the interface hides the admin-only actions from other roles: the network view is then read-only, the services lack start/stop, the Subscription and Factory Reset tabs are missing, and in the first-run wizard only an admin runs the Clonezilla download (viewers do not see the wizard at all). Since the update of 2026-10-08 the tabs whose content a role may not even read are missing as well: **Backup & Restore** (Info & Backup) and **Certificates** (Clients) for everyone but admins, **Remote Desktop** and **SSH Access** (Settings) as well as **Agent** (Clients) for viewers. Likewise, without the admin role the **General** and **Alerts** settings are read-only, and generating, uploading, rotating and re-signing certificates and keys are not offered; viewers also get no buttons to acknowledge or resolve incidents. Deleting clients and groups, **Re-issue token**, **Reset to install token** and **Sign agent** are shown to admins only, and the agent settings are read-only for operators. Where the interface still shows an action the role does not allow, the server refuses it and the interface shows an error — that is not a defect, it is the role check.
