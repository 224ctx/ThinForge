# 8 — Tasks & Logs

Two menu entries that together form the **observation and diagnostics centre**. They address different time horizons:

| Area | Timeframe | Purpose |
|------|-----------|---------|
| **Tasks** | now & recent | What's running, what just finished |
| **Logs** | hours to days | Server-side events, error stack traces |

---

## Tasks

The **Tasks** entry shows all background jobs the server is currently processing or recently processed. Examples:

- Clone capture from the cloning VM
- Delta calculation
- Tools-ISO rebuild
- Client update (one task per client)
- Ansible playbook on one or multiple clients
- Agent upgrade distribution

### Table

| Column | Meaning |
|--------|---------|
| Client / Description | affected client or task description |
| Type | task class (capture, update, deploy, playbook, …) |
| Status | `pending`, `running`, `completed`, `failed`, `cancelled` — running tasks include an embedded progress bar |
| Created | when the task was created |
| Duration | running / total time |
| Error | error text for failed tasks |

### Filter

- **Status** — dropdown across all statuses (`pending`, `running`, `completed`, `failed`, `cancelled`)
- **Type** — dropdown to select the task class
- **Text search** — by client or description name

### Actions

Tasks are managed directly in the table — there is no separate detail view. Each row offers icon actions depending on the status:

- **Cancel** — for running or pending tasks
- **Restart** — for failed or cancelled tasks
- **Delete** — for completed tasks

If a task fails, the error text appears directly in the "Error" column of its row.

### Typical daily use

- After a rollout: "How many deploys are done?"
- When a client has been quiet for a while: maybe a task for it is stuck and blocking it

---

## Logs

**Logs** combines two views in two tabs:

- **Audit log** — who changed what and when. A paginated table of write accesses, filterable by action and path.
- **Container logs** — the logs of the ThinForge services. This is where things appear that tasks (above) do not cover — e.g. internal backend errors, dnsmasq messages, Caddy access logs.

### Container logs: sources

Dropdown at the top:

- **Backend** — API + agent communication
- **Worker** — background job runner
- **dnsmasq** — DHCP/PXE events
- **NFS** — export events (relevant for rollouts)
- **Caddy** — web proxy access
- **VPN / WireGuard** — VPN handshakes and tunnel events
- **Cloner / Cloning VM** — only when these containers are running

### Container logs: display

The view shows the most recent lines of the selected service. A second selector controls how many lines are loaded (100, 200, 500 or 1000 — default 200). A button refreshes the output manually.

### When it's not enough

If the error lies deeper inside the container (e.g. a migration error during Postgres init), the messages do not surface here. Then the terminal route on the host is needed (`docker logs <container>`). For most operator tasks the web view is sufficient.

---

## Daily routine

- **Dashboard first** ([02](02-dashboard.md)) — skim the cards.
- **On anomalies**: tasks (running errors), then logs (details).
- **Alerts** appear as a card on the dashboard and can be acknowledged or resolved there ([02](02-dashboard.md#alerts)).

## Next steps

- [09 — Settings](09-settings.md) — restart services, change config
- [workflows/client-rollback.md](workflows/client-rollback.md) — when tasks/logs flag a rollout as failed
