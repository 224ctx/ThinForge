# 8 — Tasks & Logs

Two menu entries that together form the **observation and diagnostics center**. They address different time horizons:

| Area | Timeframe | Purpose |
|------|-----------|---------|
| **Tasks** | now & recent | What's running, what just finished |
| **Logs** | hours to days | Server-side events, error stack traces |

---

## Tasks

The **Tasks** entry has two tabs: **Tasks** (menu "Running Tasks") shows the jobs the server is currently processing or recently processed; **Scheduled Tasks** lists the recurring server jobs (see below). Examples of tasks:

- SSH commands to clients, such as a bulk reboot
- Setting up a client after cloning
- Agent update (one task per client)
- Agent build
- Data backup

Clone operations, deployments and update assignments do not appear here; their progress is shown in the tabs under **Cloning** ([05](05-cloning.md), [06 — Rollouts](06-rollouts.md)). The reboot tasks with which a deployment or a capture starts clients reported online do appear here, as SSH commands.

### Table

| Column | Meaning |
|--------|---------|
| Client / Description | affected client (link to its detail page) or task description |
| Type | kind of task (e.g. SSH command, build agent) |
| Status | `pending`, `running`, `completed`, `failed`, `cancelled` — running tasks include an embedded progress bar |
| Created | when the task was created |
| Duration | running / total time |
| Error | error text for failed tasks |

An SSH command, an inventory or an agent update only shows `completed` once the command ended successfully on the device. If the connection could not be established, the deadline ran out or the command reported an error, the task shows `failed` with the reason. For reboot and shutdown, the device dropping the connection also counts as success — that is part of it. (Until the update of 2026-10-01, each of these tasks showed `completed` as soon as the command had been sent.)

### Filter

- **Status** — dropdown across all statuses (`pending`, `running`, `completed`, `failed`, `cancelled`)
- **Task type** — dropdown to select the kind of task
- **Search** — by device name or the task's name (clone or file name). The search covers all tasks, not just the ones shown; tasks without a device, such as data backups, are found by their file name.

### Actions

Tasks are managed directly in the table — there is no separate detail view. Each row offers icon actions depending on the status:

- **Cancel** — for running or pending tasks
- **Restart** — for failed tasks that the server delivers to clients (such as SSH command or agent update); start a cancelled task again through its original action, since "cancelled" usually means replaced or withdrawn. Data backups and agent builds cannot be repeated here
- **Delete** — for completed, failed and cancelled tasks

If a task fails, the error text appears directly in the "Error" column of its row — in the language of the interface. Whatever the device or a command reported itself (for example the error line from SSH or the end of an agent build's output) follows untranslated after a dash. The tooltip shows the full text. Tasks from before the update of 2026-10-20 show their text as it was stored back then.

### Scheduled tasks

The tab lists the recurring server jobs with interval, last run and an error marker:

- **Clean up export files** — hourly; deletes clone exports older than 12 hours
- **Clean up finished tasks** — daily; deletes completed, failed and cancelled tasks older than 30 days
- **Synchronize Semaphore inventory** — hourly
- **Fleet daily snapshot** — daily; basis for the availability trend in the reports

Each entry offers **Run now**, **Edit** (interval in minutes, for the two clean-ups also the maximum age) and a switch to enable or disable it; admins and operators may change them.

### Typical daily use

- After a bulk command or agent update: "How many clients are done?"
- When a client has been quiet for a while: maybe a task for it is stuck and blocking it

---

## Logs

**Logs** appears in the menu for admins only and combines two views in two tabs:

- **Audit log** — who changed what and when, plus sign-ins and sign-outs including failed attempts. A paginated table, filterable by action and path.
- **Container logs** — the logs of the ThinForge services. This is where things appear that tasks (above) do not cover — e.g. internal backend errors, dnsmasq messages, proxy (Caddy) errors.

### Audit log: repeated sign-in attempts

Failed sign-in attempts ("Login failed", `login_failed`) and the step "Password correct, second factor requested" (`login_totp_challenge`) no longer produce one row each: repeated attempts from the same source are combined per minute into **one** entry that is counted up with every further attempt. For known accounts this additionally applies per account and reason (e.g. wrong password, disabled account, wrong TOTP code); all unknown names from one source end up in the same entry.

- Next to the action chip, a counter chip (e.g. **7×**) shows the number of attempts; its tooltip names the first and the last attempt.
- For unknown names the user column shows the attempted names (italic, at most ten examples, "(and more)" when there were more attempts).
- **Details** lists the attempts, the first and last attempt and the attempted names. The row's timestamp is the first attempt.

To count failed attempts, count the attempts, not the rows.

### Audit log: retention

Entries older than the configured retention period (default 365 days, allowed 30 to 3650) are deleted by the worker once a day and on every restart — configurable under [09 — Settings → General](09-settings.md). When a run deleted something, that is itself recorded as an "Old audit entries deleted" entry (`audit_retention_purge`) with count and cutoff date; a change of the setting shows up as "General settings changed" (`general_settings_update`). Retention only affects the audit log, not the backups under Backup & Restore. Since the update of 2026-10-09 the SSH command logs, resolved incidents and ended DHCP leases have retention periods of their own (also under [09 — Settings → General](09-settings.md)); their deletion runs are recorded as "Old SSH command logs deleted" (`ssh_log_retention_purge`), "Old resolved incidents deleted" (`incident_retention_purge`) and "Old DHCP leases deleted" (`dhcp_lease_retention_purge`) with count and cutoff date.

### Container logs: sources

Dropdown at the top — all services of the active compose profiles, among them:

- **Backend (API)** — API + agent communication
- **Worker** — background job runner
- **dnsmasq (DHCP/PXE)** — DHCP/PXE events
- **NFS Server** — export events (relevant for rollouts)
- **Caddy (Proxy)** — runtime and error messages of the web proxy; it keeps no access log ([14 — Data Protection](14-data-protection.md#container-logs))
- **ThinVPN** — the server's VPN service (NetBird client): login to the VPN instance, tunnel and route events
- **Cloner (Clonezilla) / Cloning-VM (QEMU)** — only when their compose profile is active
- depending on the profile also PostgreSQL, Redis, Frontend, Guacd, Chrony, Multicast-Sender and BitTorrent-Seeder

### Container logs: display

The view shows the most recent lines of the selected service. A second selector controls how many lines are loaded (100, 200, 500 or 1000 — default 200). A button refreshes the output manually. Docker keeps at most three files of 50 MB per service and then discards the oldest lines ([14 — Data Protection](14-data-protection.md#container-logs)).

If the selected service currently has no container — for example the BitTorrent seeder or a multicast sender while they are not running (ThinForge starts them only for a deployment and removes them afterwards) — a message appears instead of an empty output since the update of 2026-10-08; likewise when Docker does not deliver the logs (the message then names the reason). If the transfer breaks off midway, the output ends with the note `[... log stream from Docker broke off ...]` — the newest lines are missing then, loading again fetches them.

The container logs contain everything the services log — with DNS query logging switched on ([07 — Network](07-network.md)), for example, every DNS query of every client. Since the update of 2026-10-08 the server therefore hands them out through the API only to admins and operators; before that, every signed-in role could fetch them there. In the menu they remain available to admins only.

### When it's not enough

If the error lies deeper inside the container (e.g. a migration error during Postgres init), the messages do not surface here. Then the terminal route on the host is needed (`docker logs <container>`). For most operator tasks the web view is sufficient.

---

## Daily routine

- **Dashboard first** ([02](02-dashboard.md)) — skim the cards.
- **On anomalies**: tasks (running errors), then logs (details).
- **Alerts** appear as a card on the dashboard ([02](02-dashboard.md#alerts)); they are acknowledged or resolved under **Settings → Alerts** ([09](09-settings.md)).

## Next steps

- [09 — Settings](09-settings.md) — restart services, change config
- [workflows/client-rollback.md](workflows/client-rollback.md) — when a rollout or update went wrong
