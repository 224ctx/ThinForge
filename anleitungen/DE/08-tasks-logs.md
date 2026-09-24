# 8 — Tasks & Logs

Zwei Menüpunkte, die zusammen das **Beobachtungs- und Diagnose-Zentrum** bilden. Sie adressieren unterschiedliche Zeithorizonte:

| Bereich | Zeitraum | Zweck |
|---------|----------|-------|
| **Tasks** | jetzt & kürzlich | Was läuft gerade, was ist gerade fertig geworden |
| **Logs** | Stunden bis Tage | Server-seitige Ereignisse, Fehler-Stack-Traces |

---

## Tasks

Der **Tasks**-Menüpunkt hat zwei Tabs: **Aufgaben** (Menü „Laufende Tasks") zeigt die Aufträge, die der Server aktuell bearbeitet oder kürzlich bearbeitet hat; **Geplante Aufgaben** listet die wiederkehrenden Server-Jobs (siehe unten). Beispiele für Aufgaben:

- SSH-Befehle an Clients, etwa ein Sammel-Neustart
- Einrichtung eines Clients nach dem Klonen
- Agent-Update (pro Client ein Task)
- Agent bauen
- Datensicherung

Klon-Operationen, Deployments und Rollouts erscheinen hier nicht; ihren Fortschritt zeigen **Cloning** ([05](05-cloning.md)) und [06 — Rollouts](06-rollouts.md).

### Tabelle

| Spalte | Bedeutung |
|--------|-----------|
| Client / Beschreibung | betroffener Client (Link zur Detailseite) bzw. Beschreibung des Tasks |
| Typ | Art des Tasks (z. B. SSH-Befehl, Agent bauen) |
| Status | `pending`, `running`, `completed`, `failed`, `cancelled` — bei laufenden Tasks mit eingebettetem Fortschrittsbalken |
| Erstellt | wann der Task angelegt wurde |
| Dauer | lauf- / gesamt-Zeit |
| Fehler | Fehlertext bei fehlgeschlagenen Tasks |

### Filter

- **Status** — Dropdown über alle Status (`pending`, `running`, `completed`, `failed`, `cancelled`)
- **Task-Typ** — Dropdown zur Auswahl der Task-Art
- **Suchen** — nach Gerätename oder dem Namen des Auftrags (Klon- bzw. Dateiname). Gesucht wird über alle Aufträge, nicht nur über die angezeigten; Aufträge ohne Gerät, etwa Datensicherungen, findet die Suche über ihren Dateinamen.

### Aktionen

Tasks werden direkt in der Tabelle verwaltet — eine eigene Detailansicht gibt es nicht. Jede Zeile bietet je nach Status passende Icon-Aktionen:

- **Abbrechen** — bei laufenden oder wartenden Tasks
- **Neustarten** — bei fehlgeschlagenen oder abgebrochenen Tasks, die der Server an Clients zustellt (etwa SSH-Befehl oder Agent-Update); Datensicherung und Agent-Bau lassen sich hier nicht wiederholen
- **Löschen** — bei abgeschlossenen, fehlgeschlagenen und abgebrochenen Tasks

Schlägt ein Task fehl, steht der Fehlertext direkt in der Spalte „Fehler" der jeweiligen Zeile.

### Geplante Aufgaben

Der Tab listet die wiederkehrenden Server-Jobs mit Intervall, letztem Lauf und einer Fehler-Markierung:

- **Export-Dateien bereinigen** — stündlich; löscht Clone-Exporte, die älter als 12 Stunden sind
- **Abgeschlossene Tasks bereinigen** — täglich; löscht abgeschlossene, fehlgeschlagene und abgebrochene Tasks, die älter als 30 Tage sind
- **Semaphore Inventory synchronisieren** — stündlich
- **Flotten-Tagessnapshot** — täglich; Grundlage für den Verfügbarkeits-Trend in den Berichten

Je Eintrag gibt es **Jetzt ausführen**, **Bearbeiten** (Intervall in Minuten, bei den beiden Bereinigungen das Höchstalter) und einen Schalter zum Ein- und Ausschalten; ändern dürfen Admins und Operatoren.

### Typischer Nutzen im Alltag

- Nach einem Sammel-Befehl oder Agent-Update: „Wie viele Clients sind bereits durch?"
- Wenn ein Client lange nichts meldet: ggf. hängt ein Task für ihn, der das blockiert

---

## Logs

**Logs** ist nur für Admins im Menü und bündelt zwei Ansichten in zwei Tabs:

- **Audit-Log** — wer hat wann was geändert, dazu An- und Abmeldungen samt Fehlversuchen. Eine paginierte Tabelle, filterbar nach Aktion und Pfad.
- **Container-Logs** — die Protokolle der ThinForge-Dienste. Hier landen Dinge, die Tasks (siehe oben) nicht abbilden — z. B. interne Fehler im Backend, dnsmasq-Meldungen, Caddy-Zugriffslogs.

### Audit-Log: wiederholte Anmeldeversuche

Fehlgeschlagene Anmeldeversuche („Anmeldung fehlgeschlagen", `login_failed`) und der Schritt „Kennwort richtig, zweiter Faktor angefordert" (`login_totp_challenge`) stehen nicht mehr als je eine Zeile im Log: wiederholte Versuche derselben Quelle werden je Minute zu **einem** Eintrag zusammengefasst, der mit jedem weiteren Versuch hochgezählt wird. Bei bekannten Konten gilt das zusätzlich je Konto und Grund (etwa falsches Passwort, deaktiviertes Konto, falscher TOTP-Code); alle unbekannten Namen einer Quelle landen im selben Eintrag.

- Neben dem Aktions-Chip zeigt ein Zähler-Chip (z. B. **7×**) die Zahl der Versuche; der Tooltip nennt ersten und letzten Versuch.
- Bei unbekannten Namen stehen in der Benutzer-Spalte die versuchten Namen (kursiv, höchstens zehn Beispiele, bei mehr Versuchen „(und weitere)").
- **Details** nennt Versuche, ersten und letzten Versuch und die versuchten Namen. Der Zeitstempel der Zeile ist der erste Versuch.

Wer Fehlversuche zählen will, zählt deshalb die Versuche, nicht die Zeilen.

### Audit-Log: Aufbewahrung

Einträge, die älter sind als die eingestellte Aufbewahrungsdauer (Vorgabe 365 Tage, erlaubt 30 bis 3650), löscht der Worker einmal täglich und bei jedem Neustart — einstellbar unter [09 — Einstellungen → Allgemein](09-einstellungen.md). Hat ein Lauf etwas gelöscht, steht das selbst als Eintrag „Alte Audit-Eintraege geloescht" (`audit_retention_purge`) mit Anzahl und Stichtag im Log; eine Änderung der Einstellung erscheint als „Allgemeine Einstellungen geaendert" (`general_settings_update`). Die Aufbewahrung betrifft nur das Audit-Log, nicht die Sicherungen unter Backup & Restore.

### Container-Logs: Quellen

Dropdown oben — alle Dienste der aktiven Compose-Profile, unter anderem:

- **Backend (API)** — API + Agent-Kommunikation
- **Worker** — Hintergrundjob-Runner
- **dnsmasq (DHCP/PXE)** — DHCP/PXE-Events
- **NFS Server** — Export-Events (für Rollouts relevant)
- **Caddy (Proxy)** — Web-Proxy-Zugriffe
- **ThinVPN** — der VPN-Dienst des Servers (NetBird-Client): Anmeldung an der VPN-Instanz, Tunnel- und Routen-Events
- **Cloner (Clonezilla) / Cloning-VM (QEMU)** — nur wenn ihr Compose-Profil aktiv ist
- je nach Profil außerdem PostgreSQL, Redis, Frontend, Guacd, Chrony, Multicast-Sender und BitTorrent-Seeder

### Container-Logs: Anzeige

Angezeigt werden die letzten Zeilen des gewählten Dienstes. Über einen zweiten Selektor wählst du, wie viele Zeilen geladen werden (100, 200, 500 oder 1000 — Standard 200). Ein Knopf aktualisiert die Ausgabe manuell.

### Wann reicht das nicht?

Wenn der Fehler tiefer im Container sitzt (z. B. Migrations-Fehler beim Postgres-Init) kommen die Meldungen nicht hier an. Dann bleibt nur der Terminal-Weg auf den Host und `docker logs <container>`. Für die meisten Operator-Aufgaben reicht aber die Web-Ansicht.

---

## Arbeitsweise im Alltag

- **Erst Dashboard** ([02](02-dashboard.md)) — Kacheln schnell überfliegen.
- **Bei Anomalien**: Tasks (laufende Fehler), dann Logs (Detail).
- **Alerts** erscheinen als Kachel auf dem Dashboard ([02](02-dashboard.md#alerts)); quittiert oder aufgelöst werden sie unter **Einstellungen → Benachrichtigungen** ([09](09-einstellungen.md)).

## Nächste Schritte

- [09 — Einstellungen](09-einstellungen.md) — Dienste neu starten, Konfiguration ändern
- [workflows/client-rollback.md](workflows/client-rollback.md) — wenn ein Rollout oder Update schiefgegangen ist
