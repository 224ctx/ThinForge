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

Klon-Operationen, Deployments und Update-Zuweisungen erscheinen hier nicht; ihren Fortschritt zeigen die Tabs unter **Cloning** ([05](05-cloning.md), [06 — Rollouts](06-rollouts.md)). Die Neustart-Aufträge, mit denen ein Deployment oder eine Aufnahme online gemeldete Geräte startet, stehen dagegen hier, als SSH-Befehl.

### Tabelle

| Spalte | Bedeutung |
|--------|-----------|
| Client / Beschreibung | betroffener Client (Link zur Detailseite) bzw. Beschreibung des Tasks |
| Typ | Art des Tasks (z. B. SSH-Befehl, Agent bauen) |
| Status | `pending`, `running`, `completed`, `failed`, `cancelled` — bei laufenden Tasks mit eingebettetem Fortschrittsbalken |
| Erstellt | wann der Task angelegt wurde |
| Dauer | lauf- / gesamt-Zeit |
| Fehler | Fehlertext bei fehlgeschlagenen Tasks |

Ein SSH-Befehl, eine Inventur oder ein Agent-Update steht erst auf `completed`, wenn das Kommando auf dem Gerät erfolgreich endete. Kam die Verbindung nicht zustande, lief die Frist ab oder meldete das Kommando einen Fehler, steht der Task auf `failed` und nennt den Grund. Bei Neustart und Herunterfahren gilt auch der Abbruch der Verbindung durch das Gerät als Erfolg — der gehört dazu. (Bis zum Update vom 2026-10-01 stand jeder dieser Tasks auf `completed`, sobald der Befehl abgeschickt war.)

### Filter

- **Status** — Dropdown über alle Status (`pending`, `running`, `completed`, `failed`, `cancelled`)
- **Task-Typ** — Dropdown zur Auswahl der Task-Art
- **Suchen** — nach Gerätename oder dem Namen des Auftrags (Klon- bzw. Dateiname). Gesucht wird über alle Aufträge, nicht nur über die angezeigten; Aufträge ohne Gerät, etwa Datensicherungen, findet die Suche über ihren Dateinamen.

### Aktionen

Tasks werden direkt in der Tabelle verwaltet — eine eigene Detailansicht gibt es nicht. Jede Zeile bietet je nach Status passende Icon-Aktionen:

- **Abbrechen** — bei laufenden oder wartenden Tasks
- **Neustarten** — bei fehlgeschlagenen Tasks, die der Server an Clients zustellt (etwa SSH-Befehl oder Agent-Update); abgebrochene Tasks startest du über ihre ursprüngliche Aktion neu, denn „abgebrochen“ heißt meist ersetzt oder zurückgezogen. Datensicherung und Agent-Bau lassen sich hier nicht wiederholen
- **Löschen** — bei abgeschlossenen, fehlgeschlagenen und abgebrochenen Tasks

Schlägt ein Task fehl, steht der Fehlertext direkt in der Spalte „Fehler" der jeweiligen Zeile — in der Sprache der Oberfläche. Was das Gerät oder ein Befehl selbst gemeldet hat (etwa die Fehlerzeile von SSH oder das Ende der Ausgabe eines Agent-Baus), steht unübersetzt nach einem Gedankenstrich dahinter. Der Tooltip zeigt den ganzen Text. Tasks von vor dem Update vom 2026-10-20 zeigen ihren Text, wie er damals gespeichert wurde.

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
- **Container-Logs** — die Protokolle der ThinForge-Dienste. Hier landen Dinge, die Tasks (siehe oben) nicht abbilden — z. B. interne Fehler im Backend, dnsmasq-Meldungen, Fehlermeldungen des Proxys (Caddy).

### Audit-Log: wiederholte Anmeldeversuche

Fehlgeschlagene Anmeldeversuche („Anmeldung fehlgeschlagen", `login_failed`) und der Schritt „Kennwort richtig, zweiter Faktor angefordert" (`login_totp_challenge`) stehen nicht mehr als je eine Zeile im Log: wiederholte Versuche derselben Quelle werden je Minute zu **einem** Eintrag zusammengefasst, der mit jedem weiteren Versuch hochgezählt wird. Bei bekannten Konten gilt das zusätzlich je Konto und Grund (etwa falsches Passwort, deaktiviertes Konto, falscher TOTP-Code); alle unbekannten Namen einer Quelle landen im selben Eintrag.

- Neben dem Aktions-Chip zeigt ein Zähler-Chip (z. B. **7×**) die Zahl der Versuche; der Tooltip nennt ersten und letzten Versuch.
- Bei unbekannten Namen stehen in der Benutzer-Spalte die versuchten Namen (kursiv, höchstens zehn Beispiele, bei mehr Versuchen „(und weitere)").
- **Details** nennt Versuche, ersten und letzten Versuch und die versuchten Namen. Der Zeitstempel der Zeile ist der erste Versuch.

Wer Fehlversuche zählen will, zählt deshalb die Versuche, nicht die Zeilen.

### Audit-Log: Aufbewahrung

Einträge, die älter sind als die eingestellte Aufbewahrungsdauer (Vorgabe 365 Tage, erlaubt 30 bis 3650), löscht der Worker einmal täglich und bei jedem Neustart — einstellbar unter [09 — Einstellungen → Allgemein](09-einstellungen.md). Hat ein Lauf etwas gelöscht, steht das selbst als Eintrag „Alte Audit-Einträge gelöscht" (`audit_retention_purge`) mit Anzahl und Stichtag im Log; eine Änderung der Einstellung erscheint als „Allgemeine Einstellungen geändert" (`general_settings_update`). Die Aufbewahrung betrifft nur das Audit-Log, nicht die Sicherungen unter Backup & Restore. Eigene Fristen haben seit dem Update vom 2026-10-09 die SSH-Befehlsprotokolle, gelöste Vorfälle und beendete DHCP-Leases (ebenfalls unter [09 — Einstellungen → Allgemein](09-einstellungen.md)); deren Löschläufe stehen als „Alte SSH-Befehlsprotokolle gelöscht" (`ssh_log_retention_purge`), „Alte gelöste Vorfälle gelöscht" (`incident_retention_purge`) und „Alte DHCP-Leases gelöscht" (`dhcp_lease_retention_purge`) mit Anzahl und Stichtag im Log.

### Container-Logs: Quellen

Dropdown oben — alle Dienste der aktiven Compose-Profile, unter anderem:

- **Backend (API)** — API + Agent-Kommunikation
- **Worker** — Hintergrundjob-Runner
- **dnsmasq (DHCP/PXE)** — DHCP/PXE-Events
- **NFS Server** — Export-Events (für Rollouts relevant)
- **Caddy (Proxy)** — Laufzeit- und Fehlermeldungen des Web-Proxys; ein Zugriffsprotokoll führt er nicht ([14 — Datenschutz](14-datenschutz.md#protokolle-der-container))
- **ThinVPN** — der VPN-Dienst des Servers (NetBird-Client): Anmeldung an der VPN-Instanz, Tunnel- und Routen-Events
- **Cloner (Clonezilla) / Cloning-VM (QEMU)** — nur wenn ihr Compose-Profil aktiv ist
- je nach Profil außerdem PostgreSQL, Redis, Frontend, Guacd, Chrony, Multicast-Sender und BitTorrent-Seeder

### Container-Logs: Anzeige

Angezeigt werden die letzten Zeilen des gewählten Dienstes. Über einen zweiten Selektor wählst du, wie viele Zeilen geladen werden (100, 200, 500 oder 1000 — Standard 200). Ein Knopf aktualisiert die Ausgabe manuell. Docker bewahrt je Dienst höchstens drei Dateien zu 50 MB auf und verwirft danach die ältesten Zeilen ([14 — Datenschutz](14-datenschutz.md#protokolle-der-container)).

Hat der gewählte Dienst gerade keinen Container — etwa der BitTorrent-Seeder oder ein Multicast-Sender, solange sie nicht laufen (ThinForge startet sie nur für ein Deployment und entfernt sie danach wieder) —, erscheint seit dem Update vom 2026-10-08 eine Meldung statt einer leeren Ausgabe; ebenso, wenn Docker die Protokolle nicht liefert (die Meldung nennt dann den Grund). Bricht die Übertragung mittendrin ab, endet die Ausgabe mit dem Hinweis `[... log stream from Docker broke off ...]` — es fehlen dann die neuesten Zeilen, ein erneutes Laden holt sie.

Die Container-Logs enthalten alles, was die Dienste protokollieren — bei eingeschaltetem DNS-Protokoll ([07 — Netzwerk](07-netzwerk.md)) etwa jede DNS-Anfrage jedes Clients. Über die Schnittstelle gibt der Server sie deshalb seit dem Update vom 2026-10-08 nur noch an Admins und Operatoren heraus; vorher konnte jede angemeldete Rolle sie dort abrufen. Im Menü stehen sie wie bisher nur Admins zur Verfügung.

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
