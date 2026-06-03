# 9 — Settings

The **Settings** menu gathers every administrative area. Most are **admin-only** — operators and viewers don't see them.

The view has tabs; this guide walks through them in roughly the order they become relevant in everyday work.

## Tab: Services

Full view of Docker containers (the dashboard card is a summary). Grouped by profile: core, network, monitoring, testing.

Per container:

- **Label + container name** (e.g. Backend, `thinforge-backend-1`)
- **Status** — running / exited / not_found / paused / restarting
- **Health** — healthy / unhealthy / starting (when a healthcheck is defined)
- **Uptime** or last run duration
- **Start / Stop / Restart** — buttons; "Start" only when possible, "Stop" with confirmation dialog for critical services

An **On-Demand badge** (grey) marks containers that intentionally run only on demand (`cloning-vm`, `cloner`). Their idle state is not an error — the view shows them as neutral grey instead of red.

**Typical tasks:** a service hung after a reboot? Click Start here. Want to cleanly re-initialise a container? Restart.

## Tab: TLS

The server-side HTTPS certificate. Default after install: self-signed for the server hostname.

### Replace certificate

- **"Upload"** → pick `.crt` and `.key` separately
- Format: PEM, unprotected (key without passphrase — otherwise Caddy stalls on start)
- Validation checks CN / Subject Alternative Names match the server hostname
- After upload: Caddy auto-reloads (~5 s downtime for the web UI)

### Certificate info

Shows CN, issuer, validity (From/To). When expiry < 30 days a yellow warning appears; < 7 days red.

## Tab: Users & Roles

List of all created users with role, last login, state.

### Create a new user

- **"+ User"** — email, display name, password (or reset link via email), role

### Roles

| Role | What they can do |
|------|------------------|
| **Admin** | Everything — user management, TLS, signing keys, factory reset |
| **Operator** | Clients, cloning, rollouts, tasks, remote desktop |
| **Viewer** | Read-only: dashboard, client list |

### Reset password

On a user via menu → **"Reset password"**. Sends an email (when SMTP is configured) or generates a one-time password to copy.

### Disable / delete user

- **Disable** — login blocked; account and history remain
- **Delete** — permanently removed. If the user has already created rollouts, those stay historically visible as "(deleted user)"

## Tab: Signing Keys

Minisign key pair used to sign delta updates and agent binaries. The public part is rolled out to clients; the private part stays on the server.

### Actions

- **"Regenerate"** — rotates the key pair. **Warning**: all provisioned clients must then receive the new public key (agent update); otherwise they will reject future updates. So: plan the rotation, don't do it during peak times.
- **"Show public key"** — for verify checks
- **"Export public key"** — as a file

The private key is **not** exportable via the UI — it stays deliberately only on the server.

## Tab: NTP

Settings for chrony upstream servers. Chrony runs in the `network` profile and ensures the server host (and transitively all clients) is on the correct time.

- **Upstream servers** — list of NTP servers (e.g. `pool.ntp.org`, internal servers)
- **Stratum info** — current clock quality
- **Offset** — how far server time deviates from reference

Saving writes atomically to the chrony config and reloads via SIGHUP — no container restart needed.

## Tab: General

Settings that did not have a better home elsewhere:

- **Automatic agent updates** — during heartbeat the agent checks for a new version and installs (on/off)
- **Heartbeat interval** — default 60 s; shorter = more reactive but more traffic
- **Log retention** — how many days of log history to keep
- **Branding** — replace the login-page logo (file upload, PNG/SVG)

## Tab: Backup & Restore

Creates a snapshot of the ThinForge state (Postgres dump + secrets + config files) for disaster recovery.

- **"Backup now"** — saves as `.tar.gz` under `/data/backups` (and offers a download)
- **"Restore from file"** — upload, confirm. **Careful**: overwrites the running database.
- **Automatic backups** — cron schedule configurable

## Tab: Factory Reset

Tears down the entire ThinForge state: Postgres tables, Redis, storage dir, secrets. **Not reversible.** Double confirmation required.

Use case: a test server back to factory state before handover to a customer.

## Next steps

- [08 — Tasks & Logs](08-tasks-logs.md) — when setting changes don't behave as expected
- [workflows/golden-image.md](workflows/golden-image.md) — after certificate renewal the Tools ISO often needs to be rebuilt
