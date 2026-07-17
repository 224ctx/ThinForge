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
| Client / Beschreibung | betroffener Client bzw. Beschreibung des Tasks |
| Typ | Klasse des Tasks (capture, update, deploy, playbook, …) |
| Status | `pending`, `running`, `completed`, `failed`, `cancelled` — bei laufenden Tasks mit eingebettetem Fortschrittsbalken |
| Erstellt | wann der Task angelegt wurde |
| Dauer | lauf- / gesamt-Zeit |
| Fehler | Fehlertext bei fehlgeschlagenen Tasks |

### Filter

- **Status** — Dropdown über alle Status (`pending`, `running`, `completed`, `failed`, `cancelled`)
- **Typ** — Dropdown zur Auswahl der Task-Art
- **Text-Suche** — nach Client- bzw. Beschreibungsname

### Aktionen

Tasks werden direkt in der Tabelle verwaltet — eine eigene Detailansicht gibt es nicht. Jede Zeile bietet je nach Status passende Icon-Aktionen:

- **Abbrechen** — bei laufenden oder wartenden Tasks
- **Neustarten** — bei fehlgeschlagenen oder abgebrochenen Tasks
- **Löschen** — bei abgeschlossenen Tasks

Schlägt ein Task fehl, steht der Fehlertext direkt in der Spalte „Fehler" der jeweiligen Zeile.

### Typischer Nutzen im Alltag

- Nach einem Rollout: „Wie viele Deploys sind bereits durch?"
- Wenn ein Client lange nichts meldet: ggf. hängt ein Task für ihn, der das blockiert

---

## Logs

**Logs** bündelt zwei Ansichten in zwei Tabs:

- **Audit-Log** — wer hat wann was geändert. Eine paginierte Tabelle der schreibenden Zugriffe, filterbar nach Aktion und Pfad.
- **Container-Logs** — die Protokolle der ThinForge-Dienste. Hier landen Dinge, die Tasks (siehe oben) nicht abbilden — z. B. interne Fehler im Backend, dnsmasq-Meldungen, Caddy-Zugriffslogs.

### Container-Logs: Quellen

Dropdown oben:

- **Backend** — API + Agent-Kommunikation
- **Worker** — Hintergrundjob-Runner
- **dnsmasq** — DHCP/PXE-Events
- **NFS** — Export-Events (für Rollouts relevant)
- **Caddy** — Web-Proxy-Zugriffe
- **VPN / WireGuard** — VPN-Handshakes und Tunnel-Events
- **Cloner / Cloning-VM** — nur wenn diese Container laufen

### Container-Logs: Anzeige

Angezeigt werden die letzten Zeilen des gewählten Dienstes. Über einen zweiten Selektor wählst du, wie viele Zeilen geladen werden (100, 200, 500 oder 1000 — Standard 200). Ein Knopf aktualisiert die Ausgabe manuell.

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
