# 9 — Settings

The **Settings** menu gathers every administrative area. The menu is visible to everyone, but many actions are **admin-only** and blocked for operators and viewers: user management, certificate upload, factory reset and — since 2026-08-31 — **starting, stopping and restarting services** in the Services tab.

Blocked means the server refuses the action. Only admins see the **Users**, **Subscription** and **Factory Reset** tabs, admins and operators the **Maintenance Windows** and **Remote Desktop** tabs and the **SSH Access** sub-tab under Security (the latter two since the update of 2026-10-08; before that a viewer saw them and only got errors when opening them); operators and viewers open Settings on **General**. In the **Services** tab the start, restart and stop buttons are hidden without the admin role (since the update of 2026-09-30; before that Subscription, Factory Reset and these buttons were visible to everyone, and a click ended in an error). Where the interface still shows an action the role does not allow, the server refuses it (see the [role overview](README.md#roles-in-the-system)).

The view has tabs; this guide walks through them in roughly the order they become relevant in everyday work.

> **In-depth chapters:** Subscription management → [11 — Subscription](11-licensing.md). TLS/SSH/signing key/vulnerability scan details → [12 — Security](12-security-and-cve-scan.md). VPN setup for home office → [13 — VPN](13-vpn.md). Own profile + 2FA → [10 — Profile & 2FA](10-profile-and-2fa.md).

## Tab: Services

Tab **Services**: full view of Docker containers (the dashboard card is a summary). Grouped by profile: core, network, testing, monitoring, plus an **On-demand containers** group. An **Auto-Refresh** switch and the refresh icon (circular arrow) keep the view current.

Per container:

- **Label + container name** (e.g. Backend, `thinforge-backend-1`)
- **Status** — Running / Stopped / Not Found / Paused / Restarting
- **Health** — Healthy / Unhealthy / Starting (when a healthcheck is defined)
- **Uptime**, for stopped containers the stop time and exit code, for missing ones the `docker compose` command to create them
- **Start / Restart / Stop** — buttons; "Start" only for containers that are not running (disabled for "Not Found"), "Stop" always with a confirmation dialog, with a warning for critical services. **Admins only** — the list and status remain visible to every role; the container logs are under the **Logs** menu, which only admins see ([08 — Tasks & Logs](08-tasks-logs.md))

An **On-Demand badge** (gray) marks containers that intentionally run only on demand (`cloning-vm`, `cloner`, `multicast-sender`, `bt-seeder`). Their idle state is not an error — the view shows them as neutral gray instead of red.

Which profiles the view shows is set by `THINFORGE_ENABLED_PROFILES` in the server's `.env` (comma-separated; empty = all shipped profiles). To hide, say, the `testing` profile on a server without KVM, put your own list there — `rebuild.sh` and `deploy.sh` keep your value and only fill in the line when it is missing or still holds an earlier default. Takes effect once the backend container is recreated (e.g. via `./deploy.sh`).

**Typical tasks:** a service hung after a reboot? Click Start here. Want to cleanly re-initialize a container? Restart.

## Security → HTTPS / TLS

Sub-tab **HTTPS / TLS** in the **Security** tab (see below): the server-side HTTPS certificate. Default after install: self-signed for the server hostname. Generating and uploading are admin tasks; since the update of 2026-10-08 other roles only see the status card. **"Generate Self-Signed Certificate"** creates a new one (hostname or IP address, validity 1–3650 days, additional hostnames/IPs comma-separated). Names must not contain whitespace, control characters, `/`, `+` or `\`, and a single name must not contain a comma — they would add extra entries to the certificate. The form flags such names while you type, and the server rejects them as well. Wildcards such as `*.example.org` and IPv6 addresses are allowed.

### Replace certificate

- **"Upload Custom Certificate"** → pick certificate (`.pem`/`.crt`) and private key (`.pem`/`.key`) separately, then **"Upload Certificate"**
- Format: PEM, unprotected (key without passphrase — the check on upload rejects a passphrase-protected key)
- Validation checks that the certificate and key match each other; if it fails, the previous certificate stays active
- After upload: the Caddy container restarts automatically (~5 s downtime for the web UI)

### Certificate info

The **HTTPS Status** card shows CN, type (self-signed / custom certificate), validity, subject alternative names (SAN), serial number and SHA-1 fingerprint. While the certificate is valid it shows the remaining days; once it has lapsed a red "Expired" notice appears.

## Tab: Users & Roles

Tab **Users** (visible to admins only): list of all created users with email, role, active state and creation date.

### Create a new user

- **"Create User"** — username, email, password (at least 8 characters), role (default Viewer). There is no invitation by email. The email address is the one **Forgot password?** sends the link to.

### Roles

| Role | What they can do |
|------|------------------|
| **Admin** | Everything — user management, TLS, signing keys, factory reset |
| **Operator** | Clients, cloning, rollouts, tasks, remote desktop |
| **Viewer** | Read-only: dashboard, lists, reports |

### Reset password

In the user's row, the **"Reset password"** icon. A dialog asks for the new password (≥ 8 characters) and its confirmation. The server sets the password directly, turns off an active 2FA and ends every existing session of the account; the person then signs in with the new password.

For admin accounts and for your own account the icon is grayed out; the server refuses the action there as well. Another admin account's password is set by an admin via **Edit** (pencil icon, password field) — with the same effect on 2FA and sessions. Everyone changes their own password in their profile ([10 — Profile & 2FA](10-profile-and-2fa.md)).

With the email channel set up (tab **Alerts**), anyone can have a one-time link sent to themselves via **Forgot password?** on the sign-in page (see [10 — Profile & 2FA](10-profile-and-2fa.md#forgot-password)); without email delivery this way via an admin remains.

### Reset TOTP

The **"Reset 2FA"** button only appears when the user has 2FA enabled. Confirmation dialog → the seed is deleted, together with a started but never confirmed setup attempt; every existing session of the account ends (since 2026-09-15). The person signs in with the password alone again and can set up TOTP again in their profile. For **your own** user the button is disabled — you turn off your own 2FA in your profile ([10 — Profile & 2FA](10-profile-and-2fa.md)). For **admin accounts** the button is disabled as well, because the server refuses the action there (until the update of 2026-10-01 it was clickable and ended in an error); another admin account's 2FA goes away when an admin sets a new password there via **Edit** (see above).

### Disable / delete user

- **Disable** (the **Active** switch in the edit dialog) — login blocked; account and history remain
- **Delete** — permanently removed. Task templates the user created are kept — only the reference to the creator is cleared; the logs of their SSH commands and their audit log entries remain as well. The button does not work on your own account.

On your own account, role and the active switch cannot be changed either, so nobody locks themselves out.

## Tab: Security

Gathers all cryptographic areas. Sub-tabs:

- **HTTPS / TLS** — web certificate (status, generate self-signed, upload your own; see above).
- **SSH Access** (admins and operators) — server key (provisioning) + heartbeat token (generate / rotate / previous keys and tokens). Rotating and deleting admins only.
- **Minisign Key** — Minisign Ed25519 key pair for delta and agent-binary signatures. Public key display, **Rotate Key**, unsigned-delta counter with **Sign all**, signature state of the agent binary. Generating, rotating and re-signing admins only. Rotation is a chain of trust: the new key is signed by the old one, and clients accept it automatically via heartbeat.
- **Vulnerability Scan** (admins only) — syft + grype across all container images, severity overview (raw vs. VEX-effective), per-image CVE list.
- **SBOM Download** (admins only) — download of the SBOM artifacts per scan run (syft, cyclonedx, spdx).

Detailed descriptions of all actions including their pitfalls: [12 — Security](12-security-and-cve-scan.md).

## Tab: Alerts

Incident management for client warnings: client offline, CPU, RAM or disk above the threshold, warranty expiring, version mismatch, MAC address changed, heartbeat rejected, since the update of 2026-10-21 agent integrity and agent silent. (The condition "client error" is gone since the update of 2026-10-01 — it depended on a client status that nothing ever set.)

**Heartbeat rejected** (since the update of 2026-10-08): the server rejected the last heartbeat of a registered client — for example because it reports with the install token although it is already enrolled (such as after reimaging outside a deployment), or because enrollment from its network origin is not allowed, or because it reports with a token the server does not know (for example after an aborted reimage — then only reimaging helps, **Reset to install token** alone is not enough). While this lasts, the client reports no values, and nothing the server hands out through the heartbeat (such as updates) reaches it; the client list shows **"Install token detected!"**, or **"Unknown token!"** for an unknown token since the update of 2026-10-08 ([03 — Clients](03-clients.md)). The incident details give the time and reason of the last rejection. The server checks every five minutes: the incident resolves itself as soon as the server has accepted a heartbeat from the client again or an admin has chosen **Reset to install token**. As with the other conditions, a maintenance window only suppresses the notification, and clients in storage raise no incident. Heartbeats from unknown MAC addresses raise no incident.

**MAC Address Changed** (with both addresses since the update of 2026-10-08): a client reports a MAC address other than the registered one — usually after the network card was replaced. Admins accept the new address with **Accept MAC** right on the incident or in the client's detail view; DHCP reservation, PXE boot files and Wake-on-LAN follow, the hostname stays ([03 — Clients](03-clients.md#new-network-card)). The incident resolves with the acceptance and on its own as soon as the client reports the registered address again. It is also raised when the agent reports that the hostname stored on the client comes from another network card (for example a disk taken from another client) — then there is nothing to accept, and an admin confirms the registered address with **Confirm MAC** instead if that state is intended (on the incident the button is labeled **Confirm MAC** in that case too since the update of 2026-10-08, before that always **Accept MAC**). Accepting and confirming remember the address and the stored hostname: the same state opens no further incident (after an acceptance the hostname stays the old one), a different address or stored hostname does. Like the other conditions, the server checks every five minutes: the incident shows up at most five minutes after the client first reports the change and notifies through the configured channels, a maintenance window only suppresses the notification, and clients in storage raise no incident.

**Agent Integrity** (since the update of 2026-10-21, agent 2.27.0): a client's agent rejected or repaired something — for example an update, a certificate or a key with an invalid signature, or a modified systemd unit —, or the server found while comparing that the client's agent binary, agent version or signing key does not match its own state ([03 — Clients](03-clients.md#agent-events)). The incident stays as long as the client has open agent events; the details give the latest one as the English catalog sentence (in English like the other incident details; the card in the device view words some rejections in more detail) and the number of the others. An admin closes one-time events with **Acknowledge** in the “Agent events” card of the device view, persisting conditions end as soon as the client no longer reports them; once nothing is open, the incident resolves at the next check. **Resolve** here does not close the events — as long as one is open, the next check opens a new incident. The **Go to device** button on the incident leads to the device view. A unit repaired right after a reimage, a rollback or an agent update opens no incident.

**Agent Silent** (since the update of 2026-10-21): the client no longer sends heartbeats but answers ping — the agent is stopped, removed or hangs, or it cannot reach the server. After five minutes without a heartbeat the server marks the client as silent (chip “Agent silent” in the client list, the status shows “Offline”), after another 15 minutes it opens the incident; the 15 minutes cover a client that is still applying an update while shutting down. A silent client gets no “Client Offline” incident. The incident resolves with the next heartbeat, or when the client stops answering ping too (it is then an ordinary offline client). Here, too, **Go to device** leads to the device view; **Resolve** alone brings the incident back at the next check. If the server rejects a client's heartbeats (“Heartbeat rejected”), the client does not count as silent — it does report in, it is just rejected: like any client without a heartbeat it goes “Offline” after five minutes, but without the “Agent silent” chip and without this incident, and a silent marking already set is dropped (since the addendum of 2026-10-21; before that both incidents stood side by side).

For both, as for the other conditions: the server checks every five minutes and notifies through the configured channels, a maintenance window only suppresses the notification, clients in storage raise no incident. Neither has a threshold — there is nothing to configure for them.

- **Active Incidents** — open incidents. Per row: client, condition, details, status, occurred, number of notifications. **Acknowledge** (stays open) or **Resolve** (close with an optional note) — admin or operator; since the update of 2026-10-08 viewers no longer see these buttons. Since the update of 2026-10-21, acknowledged also means “seen”: an acknowledged incident sends no further notifications while it stands — before, every notification cooldown reported it again. The only exception is “Agent Integrity”: if a new agent event arrives after the acknowledgement, the incident is active again and reports right away. On the “Agent Integrity” and “Agent Silent” incidents, **Go to device** leads to the device view (every role).
- **History** — closed incidents with the time they were resolved.
- **Configuration** (every role sees the thresholds, admins and operators the channels; saving and testing admins only — since the update of 2026-10-08 the fields are read-only without the admin role, Save and Test are missing, and viewers see a notice instead of the channels):
  - **Thresholds**: CPU, RAM and disk in percent, warranty pre-warning in days, "Offline after" and notification cooldown in minutes. Since the update of 2026-10-03 the **warranty pre-warning** (1–36,500 days, default 30) applies wherever "warranty expiring" appears: the alert, the dashboard, the client list (Warranty tab) and the lifecycle report — before, the dashboard and the client list used a fixed 30 days. The warranty duration itself is set per client under "Warranty (Months)". Values outside the allowed ranges (percent above 0 up to 100, warranty pre-warning and minutes as whole numbers) are marked red in the form, and nothing is saved.
  - **Email Channel** (can be switched on): SMTP host, port, username, password, from address, TLS/STARTTLS, recipients; without TLS/STARTTLS (and on a port other than 465) also **Allow sign-in without encryption** — if the mail server requires a username and password, ThinForge sends them unencrypted only with this box checked, otherwise sending fails (**Test** then names the two boxes that fix this: **Use TLS/STARTTLS** or **Allow sign-in without encryption**); once it is checked, the card shows a warning, because anyone eavesdropping on the LAN can use the credentials to sign in to the mail server (since the update of 2026-10-08; before that, the setting could not be made); a port outside 1–65535 is rejected on save; if such a value is still stored from an earlier version, the card shows the port actually used for sending (587), and the next save stores it. For a stored password the field shows only a mask and is read-only, with **Change** (clears the field for a new password — if it stays empty, saving keeps the stored one), **Remove** (deletes it on save) and **Cancel**; since the update of 2026-10-16, before that it could be replaced but not removed. If an SMTP username is still set afterwards, the channel sends nothing, **Test** says that the password is missing, and the sign-in page no longer offers **Forgot password?** — if the mail server accepts mail without sign-in, clear the username as well. **Test** sends a test message. If the channel is switched on, names an SMTP host and — with a username — has a password and then either connects with TLS/STARTTLS (or via port 465) or has **Allow sign-in without encryption** checked, the server also sends the links of **Forgot password?** through it ([10 — Profile & 2FA](10-profile-and-2fa.md#forgot-password)); otherwise the link disappears from the sign-in page (the encryption condition since the update of 2026-10-18 — before, the link appeared and sending failed).
  - **Webhook Channel** (can be switched on): URL, HTTP method, secret (header `X-ThinForge-Secret`), further HTTP headers. **Test** sends a test call. The URL must point directly at the receiver: redirects (HTTP 3xx) are not followed and count as a failure, so the webhook secret never goes to another host. Since the update of 2026-10-14 the URL is stored encrypted in the database like the secret — with Slack, Microsoft Teams and similar services it carries the access token. For a stored URL the field therefore shows only the scheme and host (for example `https://hooks.slack.com/…`) and is read-only: **Change** clears the field for a new address (if it stays empty, saving keeps the stored one), **Remove** deletes it on save, **Cancel** undoes either. A new URL must be entered in full with `http://` or `https://` and a host name; otherwise **Save** rejects it and stores nothing. The field shows the secret only as a mask too, with the same three buttons (since the update of 2026-10-16); without a secret the call goes out without the header `X-ThinForge-Secret`. The values of the further HTTP headers appear as `••••`: left empty or unchanged, the stored value is kept; the trash icon removes the header together with its value.
  - Since the update of 2026-10-16, every save of the thresholds or channels that changes something appears in the audit log (**Alert thresholds changed** or **Alert channels changed**, [08 — Tasks & Logs](08-tasks-logs.md)) — with the account, the sender address and the names of the changed fields, never their values. Saving without a change writes no entry.

If the stored thresholds or channels cannot be retrieved when the tab opens (for example while the backend restarts), the configuration shows an error notice with the reason and a **Retry** button; the matching **Save** stays disabled until a fetch succeeds (since the update of 2026-10-08). Before that the fields then held defaults only, and saving replaced the stored configuration with them — for the channels that meant both switched off and the SMTP host and username, sender, recipients, URL and webhook headers gone.

**Test** sends through the last **saved** state of the channel, not through what is currently in the form — save first, then test. If sending fails, the message names the reason since the update of 2026-10-08: for example "The email channel has no recipients configured", the mail server's answer, the webhook receiver's HTTP status, or the cause of a failed request such as `Connection refused`. Password, secret, header values and the webhook URL are not included. The same reason is logged as a warning on the server. Before that the message only said "Send failed — check server logs", and nothing was logged.

Since the update of 2026-10-10, ThinForge stores the password, the secret and the header values encrypted ([14 — Data protection](14-data-protection.md#incidents-and-notifications)). If a stored value can no longer be decrypted — for example after a restore whose re-encryption failed —, **Test** names the affected field, and the channel sends no alerts until you enter the value again and save.

Without a channel switched on, incidents are only visible in the UI — no push notification.

## Tab: Maintenance Windows

In the interface since the update of 2026-09-30; visible to **admins and operators** (reading requires one of these roles, too). While a maintenance window applies, ThinForge suppresses the alerts for the affected devices, and the dashboard shows it as a notice above the tiles.

- **List** — name, scope (all devices or a selection), start, end, repetition and status (**Active**, **Upcoming** — for recurring windows until the end of the repetition —, **Past**). **Edit** and **Delete** per row.
- **Create / edit** — name, description, start and end, scope (**All Clients** or **Specific Clients** with a device selection, filterable by group) and optionally a **repetition**: daily, weekly (weekdays) or monthly (days of the month), with an optional end. All times are in the server time zone (tab **General**), weekdays and repetitions included.
- A saved **repetition end** can only be moved when editing, not removed — for the window to repeat indefinitely, create it anew and delete the old one.

## Tab: Remote Desktop

Defaults for remote desktop sessions. Admins and operators see the tab (viewers no longer since the update of 2026-10-08 — they may not read the values). Only admins can change them; operators see the values read-only — the default quality also applies to the sessions they open (since the update of 2026-09-30; before that they got a load error here, and their sessions always started with VDSL):

- **Default quality** — which preset (DSL, VDSL or LAN) a session starts with
- **Idle timeout** — a session is disconnected after this many seconds without input; allowed are 30 to 86400 seconds (24 hours)
- **Max concurrent sessions / client** — allowed are 1 to 50 sessions per device

New values apply from the next session on. Until the update of 2026-09-23, 0 meant "unlimited" — anyone trying to lock sessions down with 0 actually lifted the limit. The field now rejects 0. A 0 stored earlier is shown as the value in effect — 86400 (24 hours) for the idle timeout, the default of 5 for sessions — until you save once.

If the stored values cannot be retrieved when the tab opens (for example while the backend restarts), the tab shows an error notice with the reason and a **Retry** button. The fields then hold defaults only (VDSL, 900 seconds, 5 sessions). **Save** therefore stays disabled until a fetch succeeds: saving always sends all values at once and would otherwise replace the stored ones with the defaults.

## Tab: Subscription

Admin view of the current subscription status plus upload (**"Upload and activate"**) or **"Remove subscription"** of a `.7z` subscription file. Subscription files come from the vendor.

Detailed description (states, VPN seats, error codes): [11 — Subscription](11-licensing.md).

## Tab: General

Settings that did not have a better home elsewhere. The tab has two cards, each with its own **Save**. Every role may read them, only admins may save; without the admin role both cards are read-only without a Save button since the update of 2026-10-08.

If the stored values of a card cannot be retrieved when the tab opens (for example while the backend restarts), the card shows an error notice with the reason and a **Retry** button; its **Save** stays disabled until a fetch succeeds (since the update of 2026-10-08). Before that the fields then held defaults only, and whoever changed one setting afterwards overwrote the card's other settings with those defaults on save — such as the audit log retention with 365 days or the time servers with the two pool servers.

### Card "General Settings"

- **Session duration** — after how much inactivity a login expires (sliding window; 1 hour to 30 days, default 7 days)
- **Audit log retention** — after how many days audit log entries are deleted (default 365, allowed 30 to 3650; outside that range **Save** is disabled and the server rejects the value). The worker deletes once a day and on every restart; a run that deleted something is itself recorded in the audit log (see [08 — Tasks & Logs](08-tasks-logs.md#audit-log-retention)). Only admins may change it. Retention arrived with the update of 2026-09-15; the first worker start afterwards immediately deletes all entries older than 365 days — before that, ThinForge never deleted anything from the audit log.
- **History data retention** — after how many days the worker deletes three further histories, each allowed from 30 to 3650 days (outside that range **Save** is disabled and the server rejects the value):
  - **SSH command logs** — command, output and triggering account of every command the server ran on a device via SSH; counted from the execution, default 90 days.
  - **Resolved incidents** — counted from the resolution, default 365 days. Open and acknowledged incidents stay, however old. Since the update of 2026-10-21 the same duration applies to closed agent events (acknowledged or no longer reported, counted from closing; open ones stay); a run that deleted some is recorded in the audit log as “Old closed agent events deleted”.
  - **Ended DHCP leases** — the history of address assignments, counted from the end of the lease, default 90 days. Active leases stay.

  As with the audit log, the worker deletes once a day and on every restart; every run that deleted something is recorded in the audit log as "Old SSH command logs deleted", "Old resolved incidents deleted" or "Old DHCP leases deleted" with count and cutoff date. Reports on older periods (activity, incidents, DHCP, usage) then only count what is still retained. Only admins may change it. Retention arrived with the update of 2026-10-09; the first worker start afterwards immediately deletes whatever is older than the defaults — before that, ThinForge deleted none of it.
- **Language of device dialogs** — the language in which the devices show their own notices: the countdown before the restart after an update (title, text and the buttons **Reboot Now** and **Cancel**) and the “Remote session active” indicator during remote control. **German** (default) or **English**; devices pick up the choice with their next heartbeat, a dialog already on screen keeps its language. The language of this interface is independent of it (switch in the top bar). Only admins may change it; a change is recorded in the audit log as “General settings changed”. The setting arrived with the update of 2026-10-10 — before that, the dialogs were always in German. Only agents from version 2.26.0 on translate the countdown's title and restart button; older ones show “ThinForge Update” and “Reboot Now” there in both languages.

### Card "Time Server (NTP)"

There is no separate "NTP" tab — the time sources and the time zone live in this card. Chrony runs in the `network` profile and ensures the server host (and transitively all clients) is on the correct time.

- **Upstream NTP servers** — list of NTP servers (e.g. `0.pool.ntp.org`, internal servers). At least one is required, otherwise **Save** is disabled.
- **Time zone** — the operating time zone, see below.

Only admins may save.

The card does not show clock quality (stratum) or deviation (offset). If the server list changed on save, ThinForge rewrites the chrony config and restarts the chrony container; a time-zone-only change leaves chrony alone. If the restart fails, the save is still reported as successful — the new servers then only take effect after a manual restart (Services tab, Chrony).

### Time zone

The NTP settings also hold the **operating time zone** (default `Europe/Berlin`). It governs:

- the time and weekdays of task templates,
- start, end, weekdays and days of month of recurring maintenance windows,
- the time of scheduled deployments (input and display),
- "today" for warranty alerts and the day and week buckets of reports,
- since the update of 2026-10-01 every time shown in the interface (logs, tasks, reports, timestamps of devices and backups). If the browser runs in a different time zone, every time of day carries the abbreviation of the server zone (e.g. "CEST"); before that these places showed the browser's time.

It is set here in the **Time zone** field (an IANA name such as `Europe/Vienna`; the server rejects unknown names on save). Devices pick up the zone with their next heartbeat. The time zone of the server host itself is set by `install-deps.sh`; the field does not change it. The first choice is made in the setup wizard (NTP step, pre-selected `Europe/Berlin`); it can be changed here at any time.

Daylight saving time: a template at 02:30 runs at 03:00 on the day clocks spring forward, and exactly once on the day they fall back.

Until the update of 2026-09-15, task templates unintentionally ran on UTC, two hours later than configured in summer; they now run at the configured local time — earlier than before. Recurring maintenance windows shifted by an hour across the clock change and, at night, partly fell on the wrong weekday; they now follow local time as well.

## Backup & Restore

Backup & Restore lives under **Info & Backup**, tab **Backup & Restore**, not under Settings. There you create backups of the ThinForge state for disaster recovery. Every action there — including listing the existing backups — is reserved for admins; since the update of 2026-10-08 other roles no longer see the tab at all (before that, merely opening it ended in an error).

- **"Create system backup"** — database, configuration and keys; small, done in seconds, as a file to download. The dialog asks for a **backup password (optional)**, at least 8 characters: with a password the whole archive is encrypted (`system-<time>.tar.gz.enc`, lock icon in the list). Without one you get an open `system-<time>.tar.gz` as before — it holds **every key of the installation in plain text** (database encryption key, sign-in, signing, SSH and TLS keys); whoever gets the file has the keys, so protect storage and transport accordingly. A forgotten password cannot be recovered — the backup can no longer be opened.
- **"Start data backup"** — clones and deltas; runs in the background and can take hours depending on the amount of data. Data backups hold no keys and have no password option.
- **"Restore Backup"** — pick one or both files, confirm the overwrite and authorize it with your own password. If a system backup is encrypted, its card asks for the **backup password** and validates the whole archive with it before anything is restored; a wrong password is reported at the field. Backups without a password — including all older ones — restore as before. **Careful**: overwrites the running installation. After a system backup has been restored, all devices boot locally again; deployments and captures that were running or scheduled when the backup was taken are ended (note "durch Wiederherstellung ungueltig" — invalidated by the restore — on the device row) and have to be started again if still needed.

There are no automatic, scheduled backups — every backup is created on demand.

### Retention

ThinForge cleans up older backups by itself: in the **"Retention"** card you set, separately for system and data backups, how many of the newest are kept — default **3** each, allowed 0 to 100, **0 = unlimited** (nothing is deleted).

- Deletion happens right after every **successful** backup and only among backups of the same kind; the one just created always stays. The message after creating a backup says how many older ones were deleted. A failed or cancelled backup deletes nothing.
- If you **lower** a value, ThinForge deletes the surplus older backups of that kind **right away when you save** — the page asks first and names the number. Raising a value or setting 0 deletes nothing.
- Only files with their original name (`system-<time>.tar.gz`, `system-<time>.tar.gz.enc`, `data-<time>.tar`) are counted and deleted. To keep a backup permanently, rename it in the backup folder (for example `system-before-update.tar.gz`) — it stays in the list but is not counted and never deleted. Important backups belong on another medium anyway.
- Every automatic deletion is recorded in the audit log (**"Backup deleted by retention"**, with file name and size), a change of the value as **"Backup retention changed"**.
- After the update, the default of 3 also applies to an existing installation: if more backups of one kind were in the folder, the next backup of that kind deletes the older ones. To keep more, raise the value or set it to 0 beforehand.
- The setting belongs to the installation itself; restoring a system backup does not change it.

### Aborted backups

A backup first writes to an intermediate file (`<name>.tmp`) and only renames it at the very end. If ThinForge is restarted in the middle of a backup (update, server restart, out of memory), this unfinished file stays in the backup folder — for data backups often many gigabytes. It does not appear in the list and does not count towards retention. ThinForge cleans up such leftovers by itself:

- Leftovers of data backups (`data-<time>.tar.tmp`) when the worker service starts and right before every new data backup — but only as long as no other data backup is running.
- Leftovers of system backups (`system-<time>.tar.gz.tmp`, `system-<time>.tar.gz.enc.tmp`) when the server starts, before it accepts requests.
- Only unfinished files with their original name and the `.tmp` ending are deleted; finished backups, renamed files and everything else in the folder stay.
- Every deletion is recorded in the audit log (**"Leftover of an aborted backup deleted"**, with file name, size and trigger). The first start after the update therefore also removes leftovers that have been sitting in the folder for a while.
- An aborted backup cannot be resumed — it has to be started again.

## Tab: Factory Reset

Tears down the entire ThinForge state: Postgres tables (including all user accounts), Redis, storage dir, secrets. **Not reversible.** The checkbox, your own password and a confirmation dialog are required; afterwards the setup wizard guides you through setting it up again.

Use case: a test server back to factory state before redeployment.

## Next steps

- [08 — Tasks & Logs](08-tasks-logs.md) — when setting changes don't behave as expected
- [workflows/golden-image.md](workflows/golden-image.md) — after certificate renewal, restart the cloning VM so the Tools ISO is rebuilt
