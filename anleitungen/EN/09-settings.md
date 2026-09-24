# 9 — Settings

The **Settings** menu gathers every administrative area. The menu is visible to everyone, but many actions are **admin-only** and blocked for operators and viewers: user management, certificate upload, factory reset and — since 2026-08-31 — **starting, stopping and restarting services** in the Services tab.

Blocked means the server refuses the action. The buttons stay visible; clicking one without the required role produces an error rather than an effect (see the [role overview](README.md#roles-in-the-system)). One exception: only admins see the **Users** tab; operators and viewers open Settings on **General** (since 2026-09-15).

The view has tabs; this guide walks through them in roughly the order they become relevant in everyday work.

## Tab: Services

Tab **Services**: full view of Docker containers (the dashboard card is a summary). Grouped by profile: core, network, testing, monitoring, plus an **On-demand containers** group. An **Auto-Refresh** switch and **Refresh** keep the view current.

Per container:

- **Label + container name** (e.g. Backend, `thinforge-backend-1`)
- **Status** — Running / Stopped / Not Found / Paused / Restarting
- **Health** — Healthy / Unhealthy / Starting (when a healthcheck is defined)
- **Uptime**, for stopped containers the stop time and exit code, for missing ones the `docker compose` command to create them
- **Start / Restart / Stop** — buttons; "Start" only for containers that are not running (disabled for "Not Found"), "Stop" always with a confirmation dialog, with a warning for critical services. **Admins only** — the list, status and logs remain open to every role

An **On-Demand badge** (grey) marks containers that intentionally run only on demand (`cloning-vm`, `cloner`, `multicast-sender`, `bt-seeder`). Their idle state is not an error — the view shows them as neutral grey instead of red.

Which profiles the view shows is set by `THINFORGE_ENABLED_PROFILES` in the server's `.env` (comma-separated; empty = all shipped profiles). To hide, say, the `testing` profile on a server without KVM, put your own list there — `rebuild.sh` and `deploy.sh` keep your value and only fill in the line when it is missing or still holds an earlier default. Takes effect once the backend container is recreated (e.g. via `./deploy.sh`).

**Typical tasks:** a service hung after a reboot? Click Start here. Want to cleanly re-initialise a container? Restart.

## Security → HTTPS / TLS

Sub-tab **HTTPS / TLS** in the **Security** tab (see below): the server-side HTTPS certificate. Default after install: self-signed for the server hostname. **"Generate Self-Signed Certificate"** creates a new one (hostname or IP address, validity 1–3650 days, additional hostnames/IPs comma-separated). Names must not contain whitespace, control characters, `/`, `+` or `\`, and a single name must not contain a comma — they would add extra entries to the certificate, so the server rejects them. Wildcards such as `*.example.org` and IPv6 addresses are allowed.

### Replace certificate

- **"Upload Custom Certificate"** → pick certificate (`.pem`/`.crt`) and private key (`.pem`/`.key`) separately, then **"Upload Certificate"**
- Format: PEM, unprotected (key without passphrase — otherwise Caddy stalls on start)
- Validation checks that the certificate and key match each other
- After upload: Caddy auto-reloads (~5 s downtime for the web UI)

### Certificate info

The **HTTPS Status** card shows CN, type (self-signed / custom certificate), validity, subject alternative names (SAN), serial number and SHA-1 fingerprint. While the certificate is valid it shows the remaining days; once it has lapsed a red "Expired" notice appears.

## Tab: Users & Roles

Tab **Users** (visible to admins only): list of all created users with email, role, active state and creation date.

### Create a new user

- **"Create User"** — username, email, password (at least 8 characters), role (default Viewer). There is no invitation or reset link by email.

### Roles

| Role | What they can do |
|------|------------------|
| **Admin** | Everything — user management, TLS, signing keys, factory reset |
| **Operator** | Clients, cloning, rollouts, tasks, remote desktop |
| **Viewer** | Read-only: dashboard, lists, reports |

### Reset password

In the user's row, the **"Reset password"** icon. A dialog asks for the new password (≥ 8 characters) and its confirmation. The server sets the password directly, turns off an active 2FA and ends every existing session of the account; the person then signs in with the new password.

For admin accounts and for your own account the icon is greyed out; the server refuses the action there as well. Another admin account's password is set by an admin via **Edit** (pencil icon, password field) — with the same effect on 2FA and sessions. Everyone changes their own password in their profile.

There is currently no reset by email link: **Forgot your password?** on the sign-in page is not available yet (see [01 — Getting started](01-getting-started.md#signing-in)).

### Reset TOTP

The **"Reset 2FA"** button only appears when the user has 2FA enabled. Confirmation dialog → the seed is deleted, together with a started but never confirmed setup attempt; every existing session of the account ends (since 2026-09-15). The person signs in with the password alone again and can set up TOTP again in their profile. For **your own** user the button is disabled — you turn off your own 2FA in your profile. For **admin accounts** the server refuses the action; another admin account's 2FA goes away when an admin sets a new password there via **Edit** (see above).

### Disable / delete user

- **Disable** (the **Active** switch in the edit dialog) — login blocked; account and history remain
- **Delete** — permanently removed. If the user has already created rollouts, those are kept — only the reference to the creator is cleared. The button does not work on your own account.

On your own account, role and the active switch cannot be changed either, so nobody locks themselves out.

## Tab: Security

Gathers all cryptographic areas. Sub-tabs:

- **HTTPS / TLS** — web certificate (status, generate self-signed, upload your own; see above).
- **SSH Access** — server key (provisioning) + heartbeat token (generate / rotate / previous keys and tokens).
- **Minisign Key** — Minisign Ed25519 key pair for delta and agent-binary signatures. Public key display, **Rotate Key**, unsigned-delta counter with **Sign all**, signature state of the agent binary. Rotation is a chain of trust: the new key is signed by the old one, and clients accept it automatically via heartbeat.
- **Vulnerability Scan** (admins only) — syft + grype across all container images, severity overview (raw vs. VEX-effective), per-image CVE list.
- **SBOM Download** (admins only) — download of the SBOM artefacts per scan run (syft, cyclonedx, spdx).

## Tab: Alerts

Incident management for client warnings: client offline, CPU, RAM or disk above the threshold, client error, warranty expiring, version mismatch, MAC address changed.

- **Active Incidents** — open incidents. Per row: client, condition, details, status, occurred, number of notifications. **Acknowledge** (stays open) or **Resolve** (close with an optional note) — admin or operator.
- **History** — closed incidents with the time they were resolved.
- **Configuration** (saving and testing admins only):
  - **Thresholds**: CPU, RAM and disk in percent, warranty pre-warning in days, "Offline after" and notification cooldown in minutes.
  - **Email Channel** (can be switched on): SMTP host, port, username, password, from address, TLS/STARTTLS, recipients; a port outside 1–65535 is rejected on save. **Test** sends a test message.
  - **Webhook Channel** (can be switched on): URL, HTTP method, secret (header `X-ThinForge-Secret`), further HTTP headers. **Test** sends a test call. The URL must point directly at the receiver: redirects (HTTP 3xx) are not followed and count as a failure, so the webhook secret never goes to another host.

Without a channel switched on, incidents are only visible in the UI — no push notification.

## Tab: Remote Desktop

Defaults for remote desktop sessions, admins only:

- **Default quality** — which preset (DSL, VDSL or LAN) a session starts with
- **Idle timeout** — a session is disconnected after this many seconds without input; allowed are 30 to 86400 seconds (24 hours)
- **Max concurrent sessions / client** — allowed are 1 to 50 sessions per device

New values apply from the next session on. Until the update of 2026-09-23, 0 meant "unlimited" — anyone trying to lock sessions down with 0 actually lifted the limit. The field now rejects 0. A 0 stored earlier is shown as the value in effect — 86400 (24 hours) for the idle timeout, the default of 5 for sessions — until you save once.

If the stored values cannot be retrieved when the tab opens (for example while the backend restarts), the tab shows an error notice with the reason and a **Retry** button. The fields then hold defaults only (VDSL, 900 seconds, 5 sessions). **Save** therefore stays disabled until a fetch succeeds: saving always sends all values at once and would otherwise replace the stored ones with the defaults.

## Tab: License

Admin view of the current license status plus upload (**"Upload and activate"**) or **"Remove license"** of a `.7z` bundle. Bundles come from the vendor.

## Tab: General

Settings that did not have a better home elsewhere. The tab has two cards, each with its own **Save**.

### Card "General Settings"

- **Session duration** — after how much inactivity a login expires (sliding window; 1 hour to 30 days, default 7 days)
- **Audit log retention** — after how many days audit log entries are deleted (default 365, allowed 30 to 3650; outside that range **Save** is disabled and the server rejects the value). The worker deletes once a day and on every restart; a run that deleted something is itself recorded in the audit log (see [08 — Tasks & Logs](08-tasks-logs.md#audit-log-retention)). Only admins may change it. Retention arrived with the update of 2026-09-15; the first worker start afterwards immediately deletes all entries older than 365 days — before that, ThinForge never deleted anything from the audit log.

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
- "today" for warranty alerts and the day and week buckets of reports.

It is set here in the **Time zone** field (an IANA name such as `Europe/Vienna`; the server rejects unknown names on save). Devices pick up the zone with their next heartbeat. The time zone of the server host itself is set by `install-deps.sh`; the field does not change it. The setup wizard does not ask for a time zone — after setup `Europe/Berlin` applies until another one is chosen here.

Daylight saving time: a template at 02:30 runs at 03:00 on the day clocks spring forward, and exactly once on the day they fall back.

Until the update of 2026-09-15, task templates unintentionally ran on UTC, two hours later than configured in summer; they now run at the configured local time — earlier than before. Recurring maintenance windows shifted by an hour across the clock change and, at night, partly fell on the wrong weekday; they now follow local time as well.

## Backup & Restore

Backup & Restore lives under **Info**, tab **Backup & Restore**, not under Settings. There you create backups of the ThinForge state for disaster recovery.

- **"Create system backup"** — database, configuration and keys; small, done in seconds, as a file to download
- **"Start data backup"** — clones and deltas; runs in the background and can take hours depending on the amount of data
- **"Restore Backup"** — pick one or both files, confirm the overwrite and authorise it with your own password. **Careful**: overwrites the running installation. After a system backup has been restored, all devices boot locally again; deployments, captures and rollouts that were running or scheduled when the backup was taken are ended (note "durch Wiederherstellung ungueltig" — invalidated by the restore — on the device row) and have to be started again if still needed.

There are no automatic, scheduled backups — every backup is created on demand, and ThinForge does not clean up stored files by itself.

## Tab: Factory Reset

Tears down the entire ThinForge state: Postgres tables (including all user accounts), Redis, storage dir, secrets. **Not reversible.** The checkbox, your own password and a confirmation dialog are required; afterwards the setup wizard guides you through setting it up again.

Use case: a test server back to factory state before redeployment.

## Next steps

- [08 — Tasks & Logs](08-tasks-logs.md) — when setting changes don't behave as expected
- [workflows/golden-image.md](workflows/golden-image.md) — after certificate renewal, restart the cloning VM so the Tools ISO is rebuilt
