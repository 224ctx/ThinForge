# 2 — Dashboard

Das Dashboard ist die Start-Ansicht nach dem Login. Es gibt einen Schnellüberblick über den Systemzustand, die aktive Client-Flotte und laufende Vorgänge. Die Kacheln sind einzeln ein-/ausblendbar und umsortierbar (Zahnrad oben rechts).

Neben dem Zahnrad liegen ein **Aktualisieren**-Knopf und ein Suchfeld: **Enter** öffnet die Clients-Liste mit dem Suchbegriff. Ist gerade ein Wartungsfenster aktiv, steht über den Kacheln ein Hinweis mit seinem Namen und Ende.

## Kacheln

### Kennzahlen

Fünf Zahlen zur aktiven Flotte — eingelagerte Geräte zählen hier, in der Status-Leiste, bei den Meldungen und im Systemzustand nicht mit: **Clients gesamt** (mit „davon N auf Lager"), **Online**, **Fehler**, **Garantie läuft ab** (in den nächsten 30 Tagen) und **Garantie bereits abgelaufen**. Liegt eine der drei letzten Zahlen über 0, ist die Kachel farbig hinterlegt.

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
| Fehler | rot | Agent meldet Fehlerzustand |

Die Leiste ist eine statische Visualisierung. Verlinkt sind nur die Gruppen und der Verfügbarkeits-Bericht (Report-Symbol); die Clients-Liste filterst du über deren eigenes Status-Dropdown.

### Rollouts

Die Kachel **Aktive Rollouts** zeigt bis zu drei aktive oder pausierte Rollouts: Name, Status, Stufe x/y, einen Fortschrittsbalken (fertige Clients aller Stufen) und das Image. **„Alle anzeigen"** öffnet die Rollout-Übersicht ([06](06-rollouts.md)), das Report-Symbol den Deployments-Bericht.

### Systemzustand

Listet Compliance-Probleme: Clients ohne Gruppe, ohne Image oder mit abgelaufener Garantie. Ohne Befund steht dort „Alle Clients konform"; lässt sich der Bericht nicht laden, „Konformitätsbericht nicht abrufbar". Der Report-Button führt zum Compliance-Bericht.

### Alerts

Die Kachel **Aktive Meldungen** zeigt offene und bestätigte Vorfälle einzelner Clients — z. B. ein Client ist länger offline, CPU, RAM oder Festplatte eines Clients liegen über dem Schwellwert, die Garantie läuft ab, die installierte Version weicht ab oder die MAC-Adresse hat sich geändert. Pro Zeile (die fünf neuesten) siehst du Client, Meldung, Status, Details und Seit. Ein Klick öffnet die Client-Detailansicht; über „Alle anzeigen" gelangst du zu Einstellungen → Benachrichtigungen, wo sich Vorfälle bestätigen und lösen lassen.

### Recent Clients

Die Kachel **Zuletzt aktive Clients** zeigt die fünf zuletzt gesehenen Geräte mit Hostname, MAC-Adresse, Status, Raum und „Seit" — oft hilfreich nach einem größeren Deployment oder einem Außenstellen-Boot um zu sehen, welche Clients sich schon zurückgemeldet haben. Ein Klick öffnet das Gerät, „Alle anzeigen" die Clients-Liste.

### Disk Usage

Die Kachel **Server-Speicher** zeigt die Belegung des Datenträgers, auf dem der ThinForge-Datenordner liegt (Clones, Deltas, Captures, ISOs) — belegt, gesamt und frei in GB. Ab 75 % wird der Balken orange als Warnung, ab 90 % rot; Zeit für Altlasten aufzuräumen oder Plattenplatz nachzulegen.

### Aktivität

Laufende und fehlgeschlagene Tasks als Zahl, jeweils mit Link zur Tasks-Seite ([08](08-tasks-logs.md#tasks)); dazu „Ausstehende Anmeldungen" mit Link zur Clients-Liste. Ohne offene Punkte steht dort „Keine ausstehenden Aktivitäten". Das Report-Symbol öffnet den Tasks-Bericht.

### Lizenz

Nur für Admins sichtbar: Lizenzstatus (Lizenziert, Abgelaufen, Keine Lizenz), Restlaufzeit und die belegten VPN-Client-Plätze. Der Pfeil führt zu Einstellungen → Lizenz, das Report-Symbol zum Lizenzbericht.

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
- **Rollouts-Kachel zeigt „Aktiv", aber nichts passiert?** Die Kacheln laden etwa alle 30 Sekunden neu (die Lizenz-Kachel nur beim Aufruf der Seite), der Aktualisieren-Knopf oben sofort. Steht der Fortschritt danach immer noch, liegt es am Rollout selbst — Details in der Rollout-Übersicht ([06](06-rollouts.md)).
