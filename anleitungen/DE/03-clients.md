# 3 — Clients

Ein **Client** in ThinForge ist ein physischer Thin-PC mit installiertem Agent, der regelmäßig per Heartbeat Kontakt zum Server hält. Alle Verwaltungs-Aktionen — Image-Update, Rollback, Remote-Zugriff, Gruppen-Zuweisung — laufen auf Client-Objekte.

## Clients-Liste

Menü links **Clients**. Die Tabelle zeigt alle registrierten Geräte.

### Spalten

| Spalte | Inhalt |
|--------|--------|
| Status | Online (grün) / VPN-Sync (hellgrün) / Offline (grau) / Klont (orange) / Fehler (rot) |
| Hostname | Vom Agent gemeldeter Rechnername |
| IP | Aktuelle Management-IP (VPN oder LAN) |
| MAC | Primäre Netzwerkkarte |
| Version | Aktuell installierter Clone (`v1.003`, …) |
| Pending | Zielversion bei laufendem Update |
| Gruppe | Zugewiesene Gruppe ([04](04-gruppen.md)) |
| Letzter Heartbeat | Timestamp der letzten Meldung |
| Boot-Modus | `agent` (normal), `deploy` (Image wird installiert), `rollback` (Zurücksetzen läuft), `rescue` (Diagnose) |

### Filter und Suche

- **Textsuche** oben: sucht in Hostname, MAC, IP, Seriennummer.
- **Status-Filter**: Chip-Leiste über der Tabelle — klicken filtert entsprechend (Dashboard-Statusbar verlinkt hier hinein).
- **Gruppen-Filter**: Dropdown rechts oben.
- **Spalten-Sortierung**: Spaltenkopf anklicken.

### Bulk-Aktionen

Mehrere Clients per Checkbox markieren → Aktionen oben in der Leiste:

- **Gruppe zuweisen**
- **Rollout planen** — direkt mit diesen Clients als Ziel
- **Neustart** — über Agent
- **Rollback** — auf vorherige Version
- **Löschen** — entfernt aus der DB (Client-PC bleibt physisch bestehen)

## Client-Detail

Klick auf eine Zeile öffnet die Detail-Ansicht mit Tabs:

### Tab: Übersicht

- Hardware-Eckdaten (CPU, RAM, Disk, Hersteller)
- Netzwerk (aktuelle IP, MAC, VPN-IP, Outbound-IP)
- Agent-Info (Version, Uptime, Boot-Zähler)
- Installierter Clone mit Link auf Cloning-Ansicht
- Kaufdatum / Garantielaufzeit / Rechnungsnummer / Lieferant (für Garantiefall-Recherche)

### Tab: Aktionen

- **Rollout starten** — einzelnes Deployment auf diesen Client
- **Rollback** — auf den Vorgänger-Clone zurück
- **Neustart / Herunterfahren**
- **Rescue-Boot anfordern** — beim nächsten Reboot in Diagnose-Modus
- **Aus Inventar entfernen**

### Tab: Historie

Alle Events zu diesem Client: Heartbeats, Updates, Rollouts, Agent-Versionen, Fehler. Zeitlich sortiert, Export als CSV möglich.

### Tab: Remote

Siehe Abschnitt [Remote-Zugriff](#remote-zugriff) weiter unten.

### Tab: Tasks

Alle auf diesen Client gerichteten Hintergrundjobs (Updates, Playbooks, Captures) inkl. Status.

## Neuen Client anlegen

In der Praxis entstehen Clients **automatisch** beim ersten Heartbeat des Agenten — sobald ein PXE-gebootetes Gerät sich meldet, wird es in der Liste sichtbar. Manuelles Anlegen per **„+ Client hinzufügen"** ist nur nötig, wenn ein Client vorab reserviert werden soll (z. B. MAC und gewünschte Gruppe schon vor Hardware-Anlieferung).

Schritt-für-Schritt siehe [workflows/erster-client.md](workflows/erster-client.md).

## CSV-Import / -Export

Für Massen-Anlage oder Backup-Zwecke.

### Export

- **Export CSV** in der Liste-Aktionsleiste
- Datei enthält alle Felder inkl. Gruppe, Version, Heartbeat
- UTF-8, Semikolon-getrennt (Excel-kompatibel)

### Import

- **Import CSV** → Datei auswählen
- ThinForge prüft das Schema und zeigt eine Vorschau
- Konflikte (MAC schon vorhanden) werden markiert — Optionen: überspringen, updaten, abbrechen
- Nach Bestätigung werden Clients angelegt/aktualisiert

**CSV-Spalten (Mindestumfang):**

```
mac_address;gruppe_name;inventarnummer;raum;benutzer;kaufdatum;garantiezeit_monate;rechnungsnummer;lieferant
```

Nur `mac_address` ist Pflicht. Weitere Hardware-Felder (Seriennummer, CPU, Modell etc.) sind optional; ein per Export erzeugtes CSV kann direkt wieder importiert werden. Siehe [client-csv-import-export.md](../../docs/client-csv-import-export.md) für die vollständige Spaltenreferenz und unterstützte Header-Aliase.

## Boot-Modi

Jeder Client hat einen **Boot-Modus**, der steuert, was er beim nächsten Start tut. Der Modus wird per Heartbeat zum Client übertragen und nach Ausführung automatisch auf `agent` zurückgesetzt.

| Modus | Zweck |
|-------|-------|
| `agent` | Normaler Betrieb — OS startet, Agent meldet sich, alles wie gewohnt |
| `deploy` | Beim nächsten Reboot wird ein Clone installiert (im Hintergrund via Agent, oder via PXE-Deploy-Boot) |
| `rollback` | Beim nächsten Reboot wird auf die Vorversion zurückgesetzt |
| `rescue` | Client bootet in minimal-Recovery-Umgebung (für manuelle Diagnose) |

Setzen lässt sich der Modus aus der Client-Detail-Seite oder per Rollout.

## VPN-Status

Wenn der Client über WireGuard-VPN angebunden ist, zeigt ein kleines Chip neben dem Status-Punkt den VPN-Zustand: `connected`, `stale`, `error`. In der Client-Detailansicht (Tab Übersicht) gibt es einen VPN-Abschnitt mit Traffic-Statistik (sent/received, last-handshake). Siehe auch [07 — Netzwerk → VPN](07-netzwerk.md#vpn).

## Remote-Zugriff

Drei Zugriffsmethoden — je nach Anwendungsfall und Rechteeinstellung:

### Terminal (Web-SSH)

- **Button „Terminal"** auf der Client-Detail-Seite
- Öffnet eine in-Browser Shell via WebSocket + SSH
- Nutzt den ThinForge-Provisioning-Key (kein Passwort nötig)
- Rechte: Operator oder Admin
- Funktioniert nur wenn Client online und SSH-Port erreichbar (LAN oder VPN)

**Typische Aufgaben:** Log-Datei prüfen, Mount-Punkt checken, manuell Agent neustarten.

### Remote-Desktop (noVNC)

- **Button „Remote-Desktop"** auf der Client-Detail-Seite
- Startet einen Proxy-Container serverseitig, der X11 vom Client via SSH holt und über noVNC im Browser zeigt
- Client muss aktiv sein (eingeloggter User-Desktop) — nicht für Headless-Boxen geeignet
- Eingaben (Maus, Tastatur) werden per xdotool zurückgespielt
- Verbindung bleibt bestehen solange der Browser-Tab offen ist; beim Schließen wird der Proxy-Container gestoppt
- Rechte: Admin oder Operator mit zusätzlicher „Remote-Desktop"-Berechtigung

**Typische Aufgaben:** Benutzer-Support („Ich sehe einen roten Rahmen"), GUI-Einstellungen prüfen.

### Agent-Befehle

Einige Aktionen (Rollout, Neustart, Rollback) werden nicht per Remote-Login ausgeführt, sondern als **Befehl an den Agent** gesendet. Der holt sie per Heartbeat ab und führt sie aus. Dieser Weg ist immer verfügbar — auch ohne SSH-Erreichbarkeit, z. B. wenn der Client hinter NAT liegt und nur Heartbeats rausgehen.

## Häufige Probleme

- **Client taucht nach PXE-Boot nicht in der Liste auf** → Zuerst auf dem DHCP-Leases (Logs im Backend) prüfen, ob das Gerät eine IP bekommen hat. Dann prüfen, ob das Provisioning-Script per `get_file` den Server erreicht. Tools-ISO ist evtl. veraltet → neu bauen in [05 — Cloning](05-cloning.md).
- **„Offline" obwohl der Client läuft** → Agent-Service-Status (`systemctl status thinforge-agent` per Terminal). Oft ist die Server-URL falsch konfiguriert oder das TLS-Zertifikat wurde erneuert, ohne dass der Agent das akzeptiert.
- **Terminal/Remote-Desktop geht nicht auf** → SSH-Reachability prüfen (Firewall? VPN up?). Provisioning-Key neu verteilen aus [09 — Einstellungen → Signing-Keys](09-einstellungen.md).

## Nächste Schritte

- [04 — Gruppen](04-gruppen.md) — Clients organisieren
- [06 — Rollouts](06-rollouts.md) — Updates verteilen
- [workflows/erster-client.md](workflows/erster-client.md) — Neuen Client von Grund auf aufnehmen
