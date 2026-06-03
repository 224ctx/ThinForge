# 8 — Tasks & Logs

Zwei Menüpunkte, die zusammen das **Beobachtungs- und Diagnose-Zentrum** bilden. Sie adressieren unterschiedliche Zeithorizonte:

| Bereich | Zeitraum | Zweck |
|---------|----------|-------|
| **Tasks** | jetzt & kürzlich | Was läuft gerade, was ist gerade fertig geworden |
| **Logs** | Stunden bis Tage | Server-seitige Ereignisse, Fehler-Stack-Traces |

---

## Tasks

Der **Tasks**-Menüpunkt zeigt alle Hintergrundjobs, die der Server aktuell bearbeitet oder kürzlich bearbeitet hat. Beispiele:

- Clone-Capture aus der Cloning-VM
- Delta-Berechnung
- Tools-ISO-Rebuild
- Client-Update (pro Client ein Task)
- Ansible-Playbook auf einem oder mehreren Clients
- Agent-Upgrade-Verteilung

### Tabelle

| Spalte | Bedeutung |
|--------|-----------|
| Typ | Klasse des Tasks (capture, update, deploy, playbook, …) |
| Status | `pending`, `running`, `completed`, `failed`, `cancelled` |
| Ziel | Client, Clone oder System |
| Gestartet | wann |
| Dauer | lauf- / gesamt-Zeit |
| Fortschritt | % oder Stufen-Anzeige |

### Filter

- **Status-Chips** oben — nur laufende / nur fehlgeschlagene / nur abgeschlossene
- **Text-Suche** — Ziel-Name, Task-ID
- **Zeitraum** — heute / diese Woche / letzter Monat

### Detail

Klick auf einen Task öffnet das Detail:

- **Logs** — Live-Output des Tasks (bei `running`) oder kompletter Verlauf
- **Parameter** — mit welchen Argumenten gestartet
- **Event-Liste** — Meilensteine (gestartet, Zwischenschritt X erreicht, abgeschlossen)
- **Aktionen** — Abbrechen (nur bei `running`), Neustarten (bei `failed`)

### Typischer Nutzen im Alltag

- Nach einem Rollout: „Wie viele Deploys sind bereits durch?"
- Nach einem Fehler im Frontend-Snack: Task-ID aus der Meldung in Tasks suchen → volle Details
- Wenn ein Client lange nichts meldet: ggf. hängt ein Task für ihn, der das blockiert

---

## Logs

**Logs** zeigt Server-seitige Protokolle der ThinForge-Dienste. Es geht hier um Dinge, die Tasks (siehe oben) nicht abbilden — z. B. interne Fehler im Backend, dnsmasq-Meldungen, Caddy-Zugriffslogs.

### Quellen

Dropdown oben:

- **Backend** — API + Agent-Kommunikation
- **Worker** — Hintergrundjob-Runner
- **dnsmasq** — DHCP/PXE-Events
- **NFS** — Export-Events (für Rollouts relevant)
- **Caddy** — Web-Proxy-Zugriffe
- **VPN / WireGuard** — VPN-Handshakes und Tunnel-Events
- **Cloner / Cloning-VM** — nur wenn diese Container laufen

### Filter

- **Level** — info, warn, error (oder alle)
- **Zeitraum** — Standard: letzte 30 Minuten, anpassbar
- **Textsuche** — in der Log-Message
- **Livefollow** — Knopf rechts oben, streamt neue Zeilen live

### Export

- **Als Text** — reine Log-Zeilen
- **Als CSV** — strukturiert mit Timestamp/Level/Message-Spalten

Hilfreich bei Support-Tickets: den relevanten Zeitraum filtern, exportieren, als Anhang schicken.

### Wann reicht das nicht?

Wenn der Fehler tiefer im Container sitzt (z. B. Migrations-Fehler beim Postgres-Init) kommen die Meldungen nicht hier an. Dann bleibt nur der Terminal-Weg auf den Host und `docker logs <container>`. Für die meisten Operator-Aufgaben reicht aber die Web-Ansicht.

---

## Arbeitsweise im Alltag

- **Erst Dashboard** ([02](02-dashboard.md)) — Kacheln schnell überfliegen.
- **Bei Anomalien**: Tasks (laufende Fehler), dann Logs (Detail).
- **Alerts** erscheinen als Kachel auf dem Dashboard und lassen sich dort quittieren oder auflösen ([02](02-dashboard.md#alerts)).

## Nächste Schritte

- [09 — Einstellungen](09-einstellungen.md) — Dienste neu starten, Konfiguration ändern
- [workflows/client-rollback.md](workflows/client-rollback.md) — wenn Tasks/Logs ein Rollout als Fehler anzeigen
