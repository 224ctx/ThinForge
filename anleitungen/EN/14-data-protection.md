# 14 — Data Protection

This chapter lists the personal or person-related data ThinForge stores: where it lives, how long it stays, who can see it, and how to delete or export it. It is meant to help you keep your record of processing activities and answer requests for access or erasure.

> **Not legal advice.** This chapter describes how the software behaves. Whether a processing activity is lawful, which retention periods are appropriate and who in your organization has to be involved is for you to decide.

The roles (admin, operator, viewer) are described in the [overview](README.md#roles-in-the-system). The **data directory** is the folder set by `STORAGE_DIR` in `.env` (default `./ThinForgeDaten` in the installation folder).

## Overview

| Location | What is stored there |
|----------|----------------------|
| Database (PostgreSQL, folder `postgres` in the data directory) | accounts, devices, audit log, tasks, SSH commands, incidents, VPN assignment, settings |
| Data directory | backups (`backups`), images (`clones`), captures (`captures`), DHCP data (`dnsmasq`), clone exports (`exports`) |
| Redis | short-lived entries: block list of signed-out sessions, failed second-factor attempts, password reset links, job queue. No volume is set up for Redis |
| Container logs | whatever the services log, see [Container logs](#container-logs) |
| The managed devices | configuration and logs of the agent |
| Browsers of the people using ThinForge | sign-in cookies and display preferences |

## User accounts

| Data | Location | Retention | Visible to | Delete / export |
|------|----------|-----------|------------|-----------------|
| Username, email address, role, active switch, time of creation and last change | table `users` | until the account is deleted | admins (**Settings → Users & Roles**); every person sees their own account in the profile | admins delete under **Settings → Users & Roles**; there is no export |
| Password as an Argon2id hash, secret of the two-factor sign-in (TOTP) | table `users` | until the account is deleted; the TOTP secret until 2FA is turned off or reset | nobody in the interface | together with the account |

- Since the update of 2026-10-09 the TOTP secret is stored encrypted in the database (AES-256-GCM). Whoever gets hold of only the database, a dump of it or the `postgres` folder cannot read it. The system backup, however, also contains the key: from a backup without a password the secret can still be recovered, and older backups still contain it unencrypted (if you restore one of them, the server encrypts it when it restarts). So set a password for the backup or protect the file like the server itself ([Backups](#backups)).
- The server needs the email address only for **Forgot password?**: if an email channel is set up, the link goes there. It is valid for 15 minutes and can be used once ([10 — Profile & 2FA](10-profile-and-2fa.md)).
- **Deactivating** instead of deleting blocks sign-in but keeps all data.
- After deletion, references to the account remain. Audit log entries keep the account's ID, sign-in entries the username as well. Incidents the account acknowledged or resolved, maintenance windows it created, saved settings and tasks keep its ID. In the SSH command logs and the task templates the reference is removed; the entries themselves stay. Your own account cannot be deleted.

## Sign-in and sessions

| Data | Location | Retention | Visible to | Delete |
|------|----------|-----------|------------|--------|
| Sign-ins and failed attempts: time, account or attempted username, sender address (IP) | audit log (`audit_log`) | like the [audit log](#audit-log) | admins | like the audit log |
| Sign-in cookies `tf_access` and `tf_refresh` | browser | `tf_access` 15 minutes; `tf_refresh` for the configured session duration, which restarts with every use (default 7 days, 1 hour to 30 days in the interface) | the server only (httpOnly) | sign out; changing or resetting the password ends all sessions of the account |
| Block list of signed-out sessions, failed second-factor attempts, password reset links | Redis | until the respective token expires; the lock after failed attempts 15 minutes; the reset link 15 minutes | nobody in the interface | expire on their own |

- The server keeps no list of signed-in sessions.
- The server takes the sender address from the proxy (Caddy), not from anything the browser sends. If it is missing, the field stays empty.
- The audit log merges failed attempts from the same source into one entry per minute. For unknown usernames it holds up to ten of the names entered, exactly as they were typed (cut to 128 characters). Details: [08 — Tasks & Logs](08-tasks-logs.md).
- The server keeps the limit on sign-in attempts per sender in memory only.
- Admins set the session duration under **Settings → General** ([09 — Settings](09-settings.md)).

## Audit log

| Data | Location | Retention | Visible to | Delete / export |
|------|----------|-----------|------------|-----------------|
| Who (account) did what and when, with sender address and details (for example names of devices, files or changed values) | table `audit_log` | default 365 days, adjustable from 30 to 3650 days under **Settings → General** (admins only); the worker deletes daily and at every restart | admins (**Logs → Audit log**) | deleted only through the retention, not individually. The interface offers no export; the list can be filtered by action and path, not by account |

- The audit log records, among other things, sign-ins, changes to accounts and settings, backups, creating, changing and deleting devices (also by CSV import and as a group assignment for several devices) and groups, and commands sent to devices (wake, reboot, shutdown, **Accept MAC**, **Re-issue token**, **Reset to install token**). It also records task templates created, changed, deleted or run through the API; a run lists the number of tasks and the target devices. For a change, the entry names only the changed fields, not their values — whatever was in the **user** field does not end up in the audit log, nor does a group's description or a task template's command (the executed command is kept in the SSH command logs).
- Since the update of 2026-10-16 it also records changes under **Settings → Alerts** (**Alert channels changed**, **Alert thresholds changed**), again only with the names of the changed fields: which address, mail server, username or password was entered does not end up in the audit log. Before that, only the setting itself recorded who had saved it last.
- Terminal and remote desktop sessions appear in the audit log with their start and end: account, sender address, device, duration and whether the connection came about. What is typed or shown during a session does not ([SSH commands, terminal and remote desktop](#ssh-commands-terminal-and-remote-desktop)).
- The audit log is not part of the system backup ([Backups](#backups)).

## Devices and tasks

| Data | Location | Retention | Visible to | Delete / export |
|------|----------|-----------|------------|-----------------|
| Master data: hostname, MAC address, inventory number, room, **user** (free text), purchase date, warranty, invoice number, supplier, group | table `clients` | until the device is deleted | all roles (client list and detail) | admins and operators edit; only admins delete the device. Export: **Export CSV** in the client list (all roles) |
| Operating data: status, last seen, IP addresses, load, agent and image version, VPN status, reason for a rejected heartbeat | table `clients` | overwritten continuously | all roles | together with the device |
| Hardware inventory: manufacturer, model, serial numbers of device and disk, BIOS version, CPU, memory | table `clients` | until the next inventory run or until the device is deleted | all roles | together with the device |
| Tasks sent to devices: type, status, times, error message, parameters, triggering account | table `client_tasks` | completed, failed and aborted tasks for 30 days, adjustable under **Tasks → Scheduled Tasks** | all roles (**Tasks**) | automatically; individually under **Tasks** (admins and operators); together with the device |

- A device relates to a person mainly through the **user** field and through room or inventory number. What goes there is up to you, entered by hand or by CSV import ([03 — Clients](03-clients.md)).
- The agent does not report in its heartbeat who is signed in on the device. It reads the name of the signed-in person only on the device itself, to show notices there, for example during remote desktop.
- The CSV export contains hostname, MAC address, status, user, room, group, installed version, inventory number, invoice number and supplier. The browser builds it from the loaded list.
- When an admin deletes a device, the server also removes: the VPN assignment (revoking the VPN access), DHCP leases, incidents, tasks, SSH command logs, and the device's entries in deployments, captures, updates and rollbacks. Audit log entries that name the device stay until the retention ends, and so do copies in older backups.

## On the devices

- The agent keeps its configuration on the device's data partition (`/data/thinforge/agent.conf`) and writes its messages to the device's system journal. The helpers for remote desktop and notifications log to `/var/log/tf-remote-desktop.log` and `/var/log/tf-notify.log`. These logs stay on the device; the server does not collect them.
- ThinForge does not record what people store on the device itself. It does, however, end up in a **capture** of that device ([Images, captures and exports](#images-captures-and-exports)).

## DHCP and DNS

| Data | Location | Retention | Visible to | Delete |
|------|----------|-----------|------------|--------|
| Active leases: MAC address, IP address, hostname, expiry | file `dnsmasq.leases` in the folder `dnsmasq` | until the lease expires or is released | all roles (**Network**, table "Active DHCP Leases") | **Reset leases** (admins) |
| History of address assignments: MAC address, IP address, hostname, start and end | table `dhcp_leases` | active entries while the lease is valid; ended ones by default 90 days after they ended, adjustable from 30 to 3650 days under **Settings → General** (admins only); the worker deletes daily and at every restart | no list; **Reports → DHCP** counts them (all roles) | ended ones automatically through the retention; together with the device. **Reset leases** ends the active entries but deletes none |
| Every DHCP assignment (MAC address, IP address, hostname) | log of the dnsmasq container | see [Container logs](#container-logs) | admins (**Logs → Container logs**) | — |
| Every DNS query of every device | log of the dnsmasq container | only while **Log DNS queries** is on (default off, [07 — Network](07-network.md)) | admins | turn the switch off |

ThinForge assigns addresses only to devices created in the client list; unknown devices on the network therefore do not appear in the leases.

## SSH commands, terminal and remote desktop

| Data | Location | Retention | Visible to | Delete |
|------|----------|-----------|------------|--------|
| Commands the server runs on a device via SSH (for example reboot, shutdown, hardware inventory, agent distribution): command, output (at most 256 KiB per output stream), exit code, duration, time, triggering account | table `ssh_command_logs` | default 90 days after execution, adjustable from 30 to 3650 days under **Settings → General** (admins only); the worker deletes daily and at every restart | no view shows the commands themselves. Under **Reports → Activity** all roles see the number of commands in total and per device; the server returns a breakdown per username to admins and operators, not to viewers (through the API, the view does not show it) | automatically through the retention; together with the device |
| Terminal sessions (web SSH) and remote desktop (via Guacamole): start and end with account, sender address, device, duration and whether the connection came about | audit log (`audit_log`) | like the [audit log](#audit-log) | admins (**Logs → Audit log**) | like the audit log |
| Content of these sessions (input, output, screen) | — | not recorded | — | — |

- Admins and operators open the terminal and remote desktop ([03 — Clients](03-clients.md#remote-access)). Neither input nor screen content is stored. The start and end of every session appear in the audit log (**Terminal session started/ended**, **Remote desktop session started/ended**); both entries carry the same session ID, the end entry the duration. If a start has no end, the session is still running or ended with a restart of the backend.
- During remote desktop the device shows the signed-in person the notice **"● Remote session active"**. There is no prompt asking for consent. If nobody is signed in graphically or the notice cannot be shown, the session runs anyway.

## Incidents and notifications

| Data | Location | Retention | Visible to | Delete |
|------|----------|-----------|------------|--------|
| Incidents: device, condition, details, times, acknowledging and resolving account, resolution note (free text) | table `alert_incidents` | open and acknowledged ones until they are resolved; resolved ones by default 365 days after resolution, adjustable from 30 to 3650 days under **Settings → General** (admins only); the worker deletes daily and at every restart | all roles (**Settings → Alerts**, dashboard) | resolved ones automatically through the retention; together with the device |
| Recipient addresses, mail server credentials, webhook address | table `settings` | until changed | admins and operators; only admins change them | **Settings → Alerts** |

- The mail server password, the webhook secret and the values of the webhook headers have been stored encrypted in the database since the update of 2026-10-10 (AES-256-GCM, with the same key as the TOTP secret), and the webhook address since the update of 2026-10-14. The interface shows the secrets to nobody, not even to admins, and of the webhook address only the scheme and host (for example `https://hooks.slack.com/…`) — the path and query, where Slack, Microsoft Teams and similar services carry the token, never leave the server. Before that, the address was stored in plain text, and admins and operators saw it in full.
- Admins can replace or remove the password, the secret and the webhook address (**Change**, **Remove**); once removed, no value is left in the database. Until the update of 2026-10-16 the password and the secret could only be replaced — anyone who no longer needed them could not delete them. The values of the webhook headers disappear together with their row.
- The settings are not part of the system backup; a restore leaves the settings of the target installation unchanged. If the backup brings a different key (for example when moving to a new installation), the restore re-encrypts the credentials and the webhook address with that key. If that fails, the backend log names the affected fields; enter them again under **Settings → Alerts**.

What a notification contains is listed under [Data that leaves the system](#data-that-leaves-the-system).

## VPN

| Data | Location | Retention | Visible to | Delete |
|------|----------|-----------|------------|--------|
| Assignment device ↔ VPN peer, activation state, connection status, last handshake, whether the device is connected on the LAN or from outside | table `vpn_clients` | until the device is deleted; **deactivating VPN** ([13 — VPN](13-vpn.md)) removes the assignment to the VPN peer and the activation key from the row and deletes the peer and any unused key on the VPN instance — the row itself stays, with the time of deactivation | admins and operators (**VPN**) | together with the device |
| Log of the reconciliation runs against the VPN instance (object names, result) | table `vpn_apply_log` | 14 days | admins and operators | automatically |

- The VPN instance runs outside ThinForge. For every activated device, ThinForge creates an activation key named `client-<hostname>` there, and the device registers there under its hostname; when connecting, the instance sees the public IP address through which the device reaches the internet. ThinForge reads name and hostname, VPN address, group membership, connection status and time of the last connection of each device from the instance. Which further data the instance stores is up to whoever runs it. With the booked VPN option of ThinForge, thinforge.org provides the instance ([13 — VPN](13-vpn.md)).

## Container logs

| Service | What may appear in it | Size limit |
|---------|-----------------------|------------|
| Backend, worker | device details (hostname, MAC and IP addresses), account IDs and occasionally account names, error messages. At the default log level the backend writes no line per request | per service three files of 50 MB |
| dnsmasq | every DHCP assignment (MAC address, IP address, hostname); with the DNS log on, every DNS query | per service three files of 50 MB |
| Caddy (proxy) | no access log. Runtime and error messages; when forwarding a request fails (for example while the backend restarts), with details of the request, including the sender address | per service three files of 50 MB |
| Other services (for example Guacd, ThinVPN, PostgreSQL) | technical messages | per service three files of 50 MB |

- Admins read them under **Logs → Container logs**; through the API, operators can read them too ([08 — Tasks & Logs](08-tasks-logs.md)).
- Once the limit is reached, Docker discards the oldest lines; how far back a log reaches therefore depends on how much the service writes. The limit applies to all services since the update of 2026-10-09. Before that only the backend and the worker had one; the other services, among them dnsmasq with every assignment, wrote without a limit unless the Docker service on the server (`/etc/docker/daemon.json`) set one. Containers that ThinForge itself starts for a single job (multicast sender, BitTorrent seeder, cloner, helper containers) have the same limit since the update of 2026-10-14; before that they followed that Docker service setting. ThinForge removes them after the job, together with their logs.
- A container's logs disappear with the container, for example when an update recreates it. Deleting a device or the factory reset does not remove them.

## Backups

| Kind | Content related to persons | Location | Retention | Visible to |
|------|----------------------------|----------|-----------|------------|
| System backup | the database **without** audit log, DHCP leases, tasks, incidents and settings. It therefore contains accounts (including password hashes and encrypted TOTP secrets), devices (including the user field and inventory), SSH command logs and the VPN assignment, plus all keys of the installation | folder `backups` | the latest 3 per kind, adjustable from 0 to 100 (0 = unlimited) | admins (**Info & Backup → Backup & Restore**) |
| Data backup | images (clones) and delta updates, with everything the images contain | folder `backups` | as above | admins |

- Without a password a system backup is an open archive; with a password it is encrypted. Data backups have no password option ([09 — Settings](09-settings.md#backup--restore)).
- Backups are deleted individually under **Info & Backup → Backup & Restore** or by the retention. Renamed files do not count toward the retention and stay where they are.
- Whatever was deleted in the running system, such as an account or a device, stays in older backups until they are removed. A restore brings it back.
- Downloaded copies live outside ThinForge and are not subject to any retention by ThinForge.

## Images, captures and exports

- A **capture** saves the complete disk of a physical device, with everything on it: user profiles, browser data, locally stored files. Rolled out as an image, this data lands on every target device. Remove personal data from the source device before you capture it ([05 — Cloning](05-cloning.md)).
- Images built in the cloning VM contain whatever was set up in the VM.
- Admins and operators delete and export clones (**Cloning → Clones**). An export is created as an archive, optionally with a password, and is deleted after the download; leftovers of an aborted download are cleared by the next export.

## In the browser

- Sign-in uses the cookies `tf_access` and `tf_refresh`. They are set as httpOnly, Secure and SameSite=Strict; scripts in the browser cannot read them.
- The browser's local storage holds display preferences only: the dashboard layout, the dismissed first-run notice and the setup status. No sign-in data is stored there.

## Data that leaves the system

- **Email** through the configured mail server: incident notifications (hostname, condition, details, time, counter) to the configured recipients, and password reset links to the account's email address.
- **Webhook**: the same incident details, plus the incident ID, to the configured address.
- **VPN instance**: device names and activation keys, see [VPN](#vpn).
- **Downloads** by the people using ThinForge: CSV exports, backups, clone exports.

[12 — Security → Outgoing connections](12-security-and-cve-scan.md#outgoing-connections) lists every outgoing connection of the system with target, purpose, trigger and how to turn it off.

## Information about a person

There is no function that collects all data about one person. These are the places to look:

- **Account** — username, email address and role under **Settings → Users & Roles**.
- **Devices assigned to the person** — client list, **user** field; **Export CSV** delivers the master data.
- **Audit log** — the view does not filter by account. An account's entries can be evaluated directly in the database (table `audit_log`, column `user_id`; for sign-ins the name is also in the details).
- **SSH commands** and **incidents** an account triggered, acknowledged or resolved — only directly in the database (`ssh_command_logs.user_id`, `alert_incidents.acknowledged_by` and `resolved_by`).

## Erasing everything: factory reset

Admins reset the entire state under **Settings → Factory Reset** (with their own password, [09 — Settings](09-settings.md)). This empties all tables of the database and Redis and deletes everything in the data directory, including the backups in the folder `backups`, the images and the captures.

What remains: the container logs, files outside the data directory (such as `.env` and the folder `license`), downloaded copies, and everything on the devices. Instead of an audit log entry — the audit log is erased as well — the backend log holds a warning line naming the triggering account.

## Next steps

- [08 — Tasks & Logs](08-tasks-logs.md) — audit log and container logs in detail
- [09 — Settings](09-settings.md) — users, retention, backups
- [12 — Security](12-security-and-cve-scan.md) — TLS, keys and outgoing connections
