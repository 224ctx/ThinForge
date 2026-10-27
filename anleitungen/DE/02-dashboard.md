# 2 — Dashboard

Das Dashboard ist die Start-Ansicht nach dem Login. Es gibt einen Schnellüberblick über den Systemzustand, die aktive Client-Flotte und laufende Vorgänge. Die Kacheln sind einzeln ein-/ausblendbar und umsortierbar (Zahnrad oben rechts).

Neben dem Zahnrad liegen ein **Aktualisieren**-Knopf und ein Suchfeld: **Enter** öffnet die Clients-Liste mit dem Suchbegriff. Ist gerade ein Wartungsfenster aktiv, steht über den Kacheln ein Hinweis mit seinem Namen und Ende.

## Kacheln

### Kennzahlen

Vier Zahlen zur aktiven Flotte — eingelagerte Geräte zählen hier, in der Status-Leiste, bei den Meldungen und im Systemzustand nicht mit: **Clients gesamt** (mit „davon N auf Lager"), **Online**, **Garantie läuft ab** (innerhalb der eingestellten Garantie-Vorwarnung, Vorgabe 30 Tage — [09 — Einstellungen → Benachrichtigungen](09-einstellungen.md#tab-benachrichtigungen); heute eingeschlossen, der Tag des Garantieendes ist noch gedeckt; die Kachel nennt den Zeitraum, bis zum Update vom 2026-10-03 galten fest 30 Tage) und **Garantie bereits abgelaufen** (ab dem Tag danach; bis zum Update vom 2026-10-01 zählte schon der Endtag als abgelaufen). Liegt eine der beiden letzten Zahlen über 0, ist die Kachel farbig hinterlegt. Die frühere Kachel **Fehler** gibt es seit dem Update vom 2026-10-01 nicht mehr: den Geräte-Status „Fehler" hat nie etwas gesetzt, sie zeigte immer 0. Fehler zeigen sich an Aufträgen, Deployments und am VPN-Zustand.

### Services

Die Kachel **Dienste** zeigt den Status aller Docker-Container. Zwei Zahlen prominent:

- **X aktiv** (grün) — laufende Container wie Backend, Datenbank, VPN, Frontend
- **Y inaktiv** (rot, wenn > 0) — unerwartet nicht laufende Dienste

Ein Container, der absichtlich nur bei Bedarf läuft (`cloning-vm`, `cloner`, Multicast-Sender, BitTorrent-Seeder), erscheint **nicht** als Warnung, solange er gestoppt ist oder gar nicht angelegt wurde. Jeder andere Zustand (etwa `restarting`, `paused`) wird gemeldet.

Darunter tauchen ausgefallene Dienste namentlich auf — direkt von der Kachel aus lassen sie sich per Knopfdruck starten (nur Admins).

Detailansicht über den Pfeil: Einstellungen → Dienste ([09](09-einstellungen.md#tab-services-dienste)).

### Client-Status-Leiste

Balken mit Verteilung nach Status:

| Status | Farbe | Bedeutung |
|--------|-------|-----------|
| Online | grün | Letzter Heartbeat < 5 Min — über LAN oder VPN |
| Offline | grau | Kein Heartbeat mehr |
| Klonen | orange | Client installiert gerade ein Image |

Die Leiste ist eine statische Visualisierung. Verlinkt sind nur die Gruppen und der Verfügbarkeits-Bericht (Report-Symbol); die Clients-Liste filterst du über deren eigenes Status-Dropdown.

### Deployments

Die Kachel **Aktive Deployments** zeigt bis zu drei offene Clone-Deployments (geplant oder aktiv): Clone-Name, Gruppe (bei einzeln gewählten Clients „Einzelne Clients"), Status — bei geplanten den Termin in der Server-Zeitzone —, einen Fortschrittsbalken (fertige von allen Clients) und die Zahl fehlgeschlagener Clients. **„Alle anzeigen"** öffnet **Cloning → Deployments** ([06](06-rollouts.md)), das Report-Symbol den Deployments-Bericht. Ohne offenes Deployment steht „Keine aktiven Deployments". (Bis 2026-10-01 hieß die Kachel „Aktive Rollouts" und zeigte die gestaffelten Rollouts; die Funktion ist entfallen.)

### Systemzustand

Listet Compliance-Probleme: Clients ohne Gruppe, ohne Image oder mit abgelaufener Garantie. Ohne Befund steht dort „Alle Clients konform"; lässt sich der Bericht nicht laden, „Konformitätsbericht nicht abrufbar". Der Report-Button führt zum Compliance-Bericht.

### Alerts

Die Kachel **Aktive Meldungen** zeigt offene und bestätigte Vorfälle einzelner Clients — z. B. ein Client ist länger offline, CPU, RAM oder Festplatte eines Clients liegen über dem Schwellwert, die Garantie läuft ab, die installierte Version weicht ab oder die MAC-Adresse hat sich geändert. Pro Zeile (die fünf neuesten) siehst du Client, Meldung, Status, Details und Seit. Ein Klick öffnet die Client-Detailansicht; über „Alle anzeigen" (steht nur da, solange Meldungen anstehen) gelangst du zu Einstellungen → Benachrichtigungen, wo sich Vorfälle bestätigen und lösen lassen. Das Report-Symbol öffnet den Störungen-Bericht. Ohne Meldung steht „Keine aktiven Meldungen".

### Recent Clients

Die Kachel **Zuletzt aktive Clients** zeigt die fünf zuletzt gesehenen Geräte mit Hostname, MAC-Adresse, Status, Raum und „Seit" — oft hilfreich nach einem größeren Deployment oder einem Außenstellen-Boot um zu sehen, welche Clients sich schon zurückgemeldet haben. Ein Klick öffnet das Gerät, „Alle anzeigen" die Clients-Liste.

### Disk Usage

Die Kachel **Server-Speicher** zeigt die Belegung des Datenträgers, auf dem der ThinForge-Datenordner liegt (Clones, Deltas, Captures, ISOs) — belegt, gesamt und frei in GB. Ab 75 % wird der Balken orange als Warnung, ab 90 % rot; Zeit für Altlasten aufzuräumen oder Plattenplatz nachzulegen. Das Report-Symbol öffnet den Speicher-Bericht.

### Aktivität

Laufende und fehlgeschlagene Tasks als Zahl, jeweils mit Link zur Tasks-Seite ([08](08-tasks-logs.md#tasks)); dazu „Ausstehende Anmeldungen" mit Link zur Clients-Liste. Ohne offene Punkte steht dort „Keine ausstehenden Aktivitäten". Das Report-Symbol öffnet den Tasks-Bericht.

### Abonnement

Nur für Admins sichtbar: Status des Abonnements (Aktiv, Abgelaufen, Kein Abonnement), Restlaufzeit und die belegten VPN-Client-Plätze. Der Pfeil führt zu Einstellungen → Abonnement, das Report-Symbol zum Abonnement-Bericht.

## Anpassung

Das **Zahnrad-Icon** oben rechts öffnet „Dashboard anpassen":

- Kacheln einzeln **ein-/ausblenden**
- **Reihenfolge** per Drag-&-Drop
- **Breite** je Kachel (1/4 bis volle Breite)
- **Zurücksetzen** auf Werkseinstellung

Die Einstellungen werden lokal im Browser gespeichert — die Anpassung gilt also pro Gerät und Browser, nicht kontoübergreifend.

## Tipps für den Alltag

- **„inaktiv"-Zähler rot?** Erst in die Dienste-Detailansicht schauen, bevor man panisch wird — dort stehen Status, Health-Zustand, Exit-Code und Logs; oft ist ein Dienst nur gerade beim Neustart (`restarting`).
- **Client-Status-Balken plötzlich mit vielen „Offline"?** Meist ein Netzwerk-Problem zentral (VPN-Instanz oder Relay nicht erreichbar, DHCP-Lease-Aussetzer). Logs checken ([08](08-tasks-logs.md#logs)); bei VPN-Clients auch die Karte **VPN-Verbindung** im Menü VPN ([13](13-vpn.md)).
- **Deployments-Kachel zeigt „Aktiv", aber nichts passiert?** Die Kacheln laden etwa alle 30 Sekunden neu (die Abonnement-Kachel nur beim Aufruf der Seite), der Aktualisieren-Knopf oben sofort. Steht der Fortschritt danach immer noch, liegt es am Deployment selbst — Details unter **Cloning → Deployments** ([06](06-rollouts.md#fortschritt-und-troubleshooting)).
