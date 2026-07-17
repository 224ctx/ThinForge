# 2 — Dashboard

Das Dashboard ist die Start-Ansicht nach dem Login. Es gibt einen Schnellüberblick über den Systemzustand, die aktive Client-Flotte und laufende Vorgänge. Die Kacheln sind einzeln ein-/ausblendbar und umsortierbar (Zahnrad oben rechts).

## Kacheln

### Services

Zeigt den Status aller Docker-Container. Zwei Zahlen prominent:

- **X Aktiv** (grün) — Dauerläufer wie Backend, Datenbank, VPN, Frontend
- **Y Inaktiv** (rot, wenn > 0) — unerwartet nicht laufende Dienste

Ein Container, der absichtlich nur bei Bedarf läuft (`cloning-vm`, `cloner`), erscheint **nicht** als Warnung, solange er in seinem erwarteten Ruhezustand ist. Nur wirkliche Problemzustände (`restarting`, `paused`) werden gemeldet.

Darunter tauchen ausgefallene Dienste namentlich auf — direkt von der Kachel aus lassen sie sich per Knopfdruck neustarten.

Detailansicht: Einstellungen → Services ([09](09-einstellungen.md#dienste)).

### Client-Status-Leiste

Balken mit Verteilung nach Status:

| Status | Farbe | Bedeutung |
|--------|-------|-----------|
| Online | grün | Letzter Heartbeat < 5 Min |
| VPN-Sync | hellgrün | Online über VPN, Konfiguration synchron |
| Offline | grau | Kein Heartbeat mehr |
| Klont | orange | Client installiert gerade ein Image |
| Fehler | rot | Agent meldet Fehlerzustand |

Die Leiste ist eine statische Visualisierung. Verlinkt sind nur die Gruppen und der Verfügbarkeits-Bericht (Report-Symbol); die Clients-Liste filterst du über deren eigenes Status-Dropdown.

### Rollouts

Aktive (und pausierte) Rollouts. Zeigt pro Rollout: Image und Fortschritt (x/y Clients). Klick springt zur Rollout-Detailseite ([06](06-rollouts.md)).

### Systemzustand

Listet Compliance-Probleme: Clients ohne Gruppe, ohne Image oder mit abgelaufener Garantie. Der Report-Button führt zum Compliance-Bericht.

### Alerts

Offene Vorfälle — z. B. wenn ein Client mehrfach in Folge keinen Heartbeat sendet, Disk-Füllstand kritisch wird, oder ein Update-Rollout failt. Pro Zeile siehst du Client, Bedingung, Status und Seit. Ein Klick öffnet die Client-Detailansicht; über „Alle anzeigen" gelangst du zu Einstellungen → Alarme, wo sich Vorfälle bestätigen und lösen lassen.

### Recent Clients

Die zuletzt aktiv gewordenen Geräte — oft hilfreich nach einem größeren Deployment oder einem Außenstellen-Boot um zu sehen, welche Clients sich schon zurückgemeldet haben.

### Disk Usage

Fortschrittsbalken für den ThinForge-Daten-Ordner (Clones, Deltas, Captures, ISOs). Ab ≥ 75 % wird der Balken gelb als Warnung, ab ≥ 90 % rot; Zeit für Altlasten aufzuräumen oder Plattenplatz nachzulegen.

### Running Tasks

Zahl laufender Hintergrundjobs (Captures, Builds, Deployments). Klick leitet zur Tasks-Seite ([08](08-tasks-logs.md#tasks)).

## Anpassung

Das **Zahnrad-Icon** oben rechts öffnet „Dashboard-Einstellungen":

- Kacheln einzeln **ein-/ausblenden**
- **Reihenfolge** per Drag-&-Drop
- **Zurücksetzen** auf Werkseinstellung

Die Einstellungen werden lokal im Browser gespeichert — die Anpassung gilt also pro Gerät und Browser, nicht kontoübergreifend.

## Tipps für den Alltag

- **„Inaktiv"-Kachel gelb/rot?** Erst in die Services-Detailansicht schauen, bevor man panisch wird — `unhealthy` hat oft triviale Ursachen (noch im `start_period`, nach einem Reboot etc.).
- **Client-Status-Balken plötzlich mit vielen „Offline"?** Meist ein Netzwerk-Problem zentral (VPN-Gateway down, DHCP-Lease-Aussetzer). Logs checken ([08](08-tasks-logs.md#logs)).
- **Rollouts-Kachel zeigt „In Fortschritt" aber nichts passiert?** Status-, Alarm- und Disk-Kacheln aktualisieren sich etwa alle 30 Sekunden; Rollouts, Services, Systemzustand und Recent Clients hingegen erst beim Neuladen. Bei einem scheinbar stehenden Rollout den Browser neu laden oder den Refresh-Button auf der Rollout-Detailseite nutzen.
