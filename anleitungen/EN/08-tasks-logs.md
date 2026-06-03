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
| Type | task class (capture, update, deploy, playbook, …) |
| Status | `pending`, `running`, `completed`, `failed`, `cancelled` |
| Target | client, clone, or system |
| Started | when |
| Duration | running / total time |
| Progress | % or stage indicator |

### Filter

- **Status chips** at the top — only running / only failed / only completed
- **Text search** — target name, task ID
- **Timeframe** — today / this week / last month

### Detail

Clicking a task opens the detail:

- **Logs** — live output (when `running`) or complete trace
- **Parameters** — arguments the task was started with
- **Event list** — milestones (started, stage X reached, completed)
- **Actions** — cancel (only when `running`), restart (when `failed`)

### Typical daily use

- After a rollout: "How many deploys are done?"
- After a frontend snack error: look up the task ID from the message → full details
- When a client has been quiet for a while: maybe a task for it is stuck and blocking it

---

## Logs

**Logs** shows server-side logs of the ThinForge services. This is about things tasks (above) do not cover — e.g. internal backend errors, dnsmasq messages, Caddy access logs.

### Sources

Dropdown at the top:

- **Backend** — API + agent communication
- **Worker** — background job runner
- **dnsmasq** — DHCP/PXE events
- **NFS** — export events (relevant for rollouts)
- **Caddy** — web proxy access
- **VPN / WireGuard** — VPN handshakes and tunnel events
- **Cloner / Cloning VM** — only when these containers are running

### Filter

- **Level** — info, warn, error (or all)
- **Timeframe** — default: last 30 min, adjustable
- **Text search** — in the log message
- **Live follow** — button top right, streams new lines live

### Export

- **As text** — raw log lines
- **As CSV** — structured with timestamp/level/message columns

Helpful for support tickets: filter the relevant window, export, attach to the ticket.

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
