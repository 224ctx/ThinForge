# 3 — Clients

Ein **Client** in ThinForge ist ein physischer Thin-PC mit installiertem Agent, der regelmäßig per Heartbeat Kontakt zum Server hält. Alle Verwaltungs-Aktionen — Image-Update, Rollback, Remote-Zugriff, Gruppen-Zuweisung — laufen auf Client-Objekte.

> **Empfohlenes System:** Für die Thin-Clients ist Debian die bevorzugte Wahl — installiert als Minimal-System mit XFCE als grafischer Oberfläche. Grundsätzlich funktioniert aber jede Linux-Distribution.

## Clients-Liste

Menü links **Clients**. Die Tabelle zeigt alle registrierten Geräte und lädt alle 30 Sekunden neu. Die weiteren Tabs der Ansicht beschreibt der Abschnitt [Weitere Tabs](#weitere-tabs).

### Spalten

| Spalte | Inhalt |
|--------|--------|
| Inventarnummer | Eigene Inventarnummer; danach ist die Liste anfangs sortiert |
| Hostname | Rechnername `TF-<MAC>` — vergibt ThinForge beim Anlegen |
| MAC-Adresse | Primäre Netzwerkkarte |
| Status | Online (grün; bei bekanntem Weg „Online (LAN)" bzw. „Online (VPN)" mit Schild-Symbol) / Offline (grau) / Klont (orange) / Fehler (rot) |
| Aktuelle IP | Die Adresse, von der der letzte Heartbeat kam (LAN oder VPN-Overlay) |
| Installierte Version | Aktuell installierter Clone (`v2026.06.22-004`, …); ohne Versionsangabe der Image-Name mit Link in die Cloning-Ansicht |
| Benutzer, Raum | Frei gepflegte Angaben |
| Gruppen | Zugewiesene Gruppe ([04](04-gruppen.md)) |

Eingelagerte Geräte (**Lager**) erscheinen abgeblendet mit orangem Chip. Rot wird der Status auch, wenn ein Gerät seit mehr als drei Wochen nicht gesehen wurde oder der Server seinen Heartbeat abweist — dann steht dort **„Install Token erkannt!"**, der Tooltip nennt den Grund. Ein Klick auf einen Online- oder Offline-Chip prüft per Ping, ob das Gerät gerade erreichbar ist.

Am Zeilenende: **Bearbeiten** (öffnet die Detailansicht), **Löschen**, **Token neu ausstellen** und **Reset auf Install Token** (nur bei „Install Token erkannt!" aktiv; der Client meldet sich danach beim nächsten Heartbeat neu an). Löschen und die beiden Token-Aktionen sind Admin-Sache.

### Filter und Suche

- **Suchfeld** oben: filtert die angezeigte Liste über die Tabellenspalten (z. B. Hostname, MAC-Adresse, Inventarnummer, Benutzer, Raum, Gruppe); ein Suchbegriff aus dem Dashboard wird übernommen.
- **Status-Filter**: Dropdown in der Filterzeile (Online, Offline, Klonen, Fehler).
- **Gruppen-Filter**: Dropdown „Gruppen" in der Filterzeile; daneben der Filter „Verbindung" und der Aktualisieren-Knopf.
- **Spalten-Sortierung**: Spaltenkopf anklicken.

### Bulk-Aktionen

Mehrere Clients per Checkbox markieren → Aktionen oben in der Leiste:

- **Gruppe zuweisen** — Gruppe wählen, dann **Zuweisen**
- Menü **Aktionen**:
  - **Einschalten (WoL)**, **Neustart**, **Herunterfahren** — Neustart und Herunterfahren schickt der Server per SSH
  - **Ping Check** — prüft die Erreichbarkeit der markierten Geräte
  - **Token neu ausstellen** — erneuert die Heartbeat-Tokens; jedes Gerät übernimmt seinen neuen Token beim nächsten Heartbeat (nur Admins). Scheitert es für ein Gerät, nennt eine Warnung seinen Namen
  - **Löschen** — entfernt den Client aus der Verwaltung (der physische PC bleibt bestehen); er taucht nicht von selbst wieder auf und muss zum erneuten Verwalten manuell mit seiner MAC-Adresse neu angelegt werden (nur Admins). Lässt sich ein Gerät nicht löschen, nennt eine Warnung seinen Namen

## Client-Detail

Klick auf eine Zeile öffnet die Detail-Ansicht. Sie hat keine Tabs, sondern drei Bereiche; die Seite lädt alle 15 Sekunden neu, der Aktualisieren-Knopf oben sofort.

### Client-Details

- Hostname und MAC-Adresse (nur lesend)
- Inventarnummer (muss eindeutig sein, wird beim Tippen geprüft), Raum, Benutzer, Gruppe
- **Lager** — eingelagertes Gerät: keine Alerts, nicht in Kennzahlen und Berichten
- Installierte Version bzw. Image und „Installiert am" (nur lesend)
- Kaufdatum / Garantie (Monate) mit berechnetem Garantieende / Rechnungsnummer / Lieferant (für Garantiefall-Recherche)
- **Speichern** übernimmt nur die geänderten Felder — was jemand anderes inzwischen an einem anderen Feld geändert hat, bleibt erhalten

### Aktionen

- **Einschalten (WoL)**, **Neustart**, **Herunterfahren**
- **Terminal öffnen** und **Remote Desktop** — nur wenn der Client online ist, siehe [Remote-Zugriff](#remote-zugriff)
- **Löschen** (nur Admins)

### Systeminformationen

Zuletzt gesehen sowie CPU-, RAM- und Festplattenauslastung mit Balken (CPU und RAM ab 60 % orange, ab 80 % rot; Festplatte ab 75 % orange, ab 90 % rot).

Die Aufträge eines Geräts findest du unter **Tasks** mit dem Client-Filter ([08](08-tasks-logs.md)).

## Neuen Client anlegen

Clients werden **manuell** angelegt — eine automatische Registrierung neuer Geräte gibt es nicht. Über **„+ Client registrieren"** trägst du die **MAC-Adresse** ein (Pflichtfeld) und optional Inventarnummer, Raum, Benutzer, Kauf- und Garantiedaten, Gruppe und Lager. Erst ein angelegtes Gerät wird vom Server akzeptiert; Heartbeats von unbekannten MAC-Adressen werden abgewiesen. Für die Massen-Anlage gibt es den CSV-Import (siehe unten).

Schritt-für-Schritt siehe [workflows/erster-client.md](workflows/erster-client.md).

## CSV-Import / -Export

Für Massen-Anlage oder Backup-Zwecke.

### Export

- **CSV exportieren** in der Aktionsleiste über der Liste
- Datei `clients.csv` mit Hostname, MAC-Adresse, Status, Benutzer, Raum, Gruppe, installierter Version, Inventarnummer, Rechnungsnummer und Lieferant — exportiert werden die gerade geladenen Clients, bei gesetztem Status-, Verbindungs- oder Gruppenfilter also nur diese
- UTF-8 mit BOM, kommagetrennt, jedes Feld in Anführungszeichen; Spaltenköpfe in der Sprache der Oberfläche

### Import

- **CSV importieren** → CSV-Inhalt in das Textfeld einfügen (eine Datei wird nicht hochgeladen); ein exportiertes `clients.csv` lässt sich direkt einfügen
- ThinForge erkennt die Kopfzeile (deutsche und englische Spaltennamen, auch die des Exports) und zeigt eine Vorschau; Zeilen mit ungültiger MAC sind markiert und werden übersprungen
- Fehlen Gruppen, fragt ein Dialog, ob sie angelegt werden sollen
- Nach **„N Client(s) importieren"** legt der Server die neuen Clients an. Ist eine MAC schon vorhanden, legt er nichts an — eine angegebene Gruppe übernimmt er für das vorhandene Gerät. Zeilen mit einer schon vergebenen Inventarnummer überspringt er und meldet sie

**CSV-Spalten (Mindestumfang):**

```
mac_address,gruppe_name,inventarnummer,raum,benutzer,kaufdatum,garantiezeit_monate,rechnungsnummer,lieferant
```

Nur `mac_address` ist Pflicht; `kaufdatum` im Format `JJJJ-MM-TT`. Andere Spalten (etwa Hostname, Status oder installierte Version aus dem Export) werden ignoriert, ein per Export erzeugtes CSV kann also direkt wieder importiert werden. Ohne erkennbare Kopfzeile gilt die feste Reihenfolge `mac_address, inventarnummer, raum, benutzer, kaufdatum, garantiezeit_monate, rechnungsnummer, lieferant`.

## Boot-Modi

Jeder Client hat einen **Boot-Modus**, der steuert, was er beim nächsten Start per PXE tut. Der Modus liegt als PXE-Konfiguration auf dem Server; nach einem abgeschlossenen Deployment oder Capture steht er automatisch wieder auf Lokal-Boot.

| Modus | Zweck |
|-------|-------|
| Lokal | Normaler Betrieb — der Client bootet vom lokalen Datenträger |
| Deploy | Beim nächsten Start wird ein Image installiert |
| Capture | Beim nächsten Start wird der Datenträger des Geräts als Image aufgenommen |
| Keine Config | Es ist keine Boot-Konfiguration hinterlegt — der Client bootet normal weiter |

Einsehen und setzen lässt sich der Modus unter **Netzwerk → PXE Boot** (nur Admins): Lokal oder Capture setzen, Konfiguration löschen ([07](07-netzwerk.md#tab-pxe-boot)). Deploy setzt ThinForge selbst, sobald ein Deployment oder Rollout den Client scharfschaltet.

## VPN-Status

Kommt der Heartbeat eines Clients über das VPN, zeigt die Liste den Status als „Online (VPN)" mit einem Schild-Symbol; über den Filter **Verbindung** lassen sich LAN- und VPN-Clients trennen. Mehr steht hier nicht: den eigentlichen VPN-Zustand eines Geräts (aktiviert, verbunden, letzter Handshake, Verbindung über Vermittler) zeigt der Reiter **Clients** im Menü **VPN** ([13 — VPN](13-vpn.md)); eine Traffic-Statistik gibt es nicht.

## Remote-Zugriff

Drei Zugriffsmethoden — je nach Anwendungsfall und Rechteeinstellung:

### Terminal (Web-SSH)

- **Button „Terminal öffnen"** auf der Client-Detail-Seite
- Öffnet eine in-Browser Shell (als `root`) via WebSocket + SSH
- Nutzt den ThinForge-Provisioning-Key (kein Passwort nötig)
- Rechte: Operator oder Admin
- Funktioniert nur wenn Client online und SSH-Port erreichbar (LAN oder VPN)

**Typische Aufgaben:** Log-Datei prüfen, Mount-Punkt checken, manuell Agent neustarten.

### Remote-Desktop

- **Button „Remote Desktop"** auf der Client-Detail-Seite
- Der Server baut einen SSH-Tunnel zum Client auf, startet dort `x11vnc` auf dem Bildschirm `:0` und reicht die Sitzung über den Guacamole-Dienst (`guacd`) in den Browser; Maus und Tastatur gehen denselben Weg zurück
- Der Client braucht eine laufende grafische Sitzung auf `:0` (Anmeldebildschirm oder Desktop) — nicht für Headless-Boxen geeignet
- Auf dem Client zeigt ein Hinweisfenster „Remote-Sitzung aktiv", solange die Sitzung läuft; beim Beenden räumt der Server `x11vnc` wieder ab
- Die Qualitätsstufe (DSL, VDSL, LAN) lässt sich im Dialog umschalten; Vorgabe, Leerlauf-Timeout und die Zahl gleichzeitiger Sitzungen je Client stehen unter **Einstellungen → Remote Desktop**
- Rechte: Operator oder Admin

**Typische Aufgaben:** Benutzer-Support („Ich sehe einen roten Rahmen"), GUI-Einstellungen prüfen.

### Agent-Befehle

Delta-Updates und Rollbacks laufen nicht über einen Remote-Login: der **Agent** holt sie mit seinem Heartbeat ab und führt sie aus. Dieser Weg funktioniert auch ohne SSH-Erreichbarkeit, z. B. wenn der Client hinter NAT liegt und nur Heartbeats rausgehen. Neustart und Herunterfahren schickt der Server dagegen per SSH — dafür muss das Gerät erreichbar sein.

## Weitere Tabs

- **Garantie** — Kacheln für gültige, bald (90 Tage) ablaufende und abgelaufene Garantien, Filter und Tabelle mit Garantieende; **CSV exportieren** schreibt `inventar.csv`.
- **Agent** — das Agent-Binary des Servers: bauen, hochladen, signieren und per SSH auf die Flotte verteilen.
- **Zertifikate** — Vertrauens-Zertifikate, die der Server an alle Clients oder an eine Gruppe verteilt (nur Admins).

## Häufige Probleme

- **Client bleibt nach dem Deployment offline** → Zuerst unter **Netzwerk → DHCP / DNSMASQ → Leases** prüfen, ob das Gerät eine IP bekommen hat (nur angelegte MACs bekommen eine), dann den Status im Deployment. Wurde das Golden-Image mit einer veralteten Tools-ISO eingerichtet, fehlen dem Agent passende Token oder Zertifikate → Image mit aktueller ISO neu einrichten ([05 — Cloning](05-cloning.md)).
- **„Offline" obwohl der Client läuft** → Agent-Service-Status (`systemctl status thinforge-agent` direkt am Gerät — das Terminal der Oberfläche ist bei „Offline" gesperrt). Oft ist die Server-URL falsch konfiguriert oder das TLS-Zertifikat wurde erneuert, ohne dass der Agent das akzeptiert. Steht in der Liste **„Install Token erkannt!"**, weist der Server den Heartbeat ab → **Reset auf Install Token** (Admin).
- **Terminal/Remote-Desktop geht nicht auf** → SSH-Reachability prüfen (Firewall? VPN up?). Den Provisioning-Key unter **Einstellungen → Sicherheit → SSH-Zugang** prüfen bzw. rotieren — online Clients übernehmen einen neuen Schlüssel mit dem nächsten Heartbeat ([12 — Sicherheit](12-sicherheit-und-cve-scan.md)).
- **Ein Gerät zeigt die aktuelle Agent-Version, verhält sich aber wie eine alte** → Die Agent-Version in der Liste ist die **Meldung des Geräts**; der Server kann sie nicht nachprüfen. **Alle aktualisieren** (Tab **Agent**) nimmt bei „Alle Clients“ und „Gruppe“ nur Geräte mit abweichender gemeldeter Version — ein Gerät, das die aktuelle Version bloß meldet, bleibt dabei außen vor. Im Verdachtsfall das Gerät gezielt behandeln: **Reinstall** (installiert unabhängig von der gemeldeten Version neu) oder im Dialog **Einzelne Clients** auswählen.

## Nächste Schritte

- [04 — Gruppen](04-gruppen.md) — Clients organisieren
- [06 — Rollouts](06-rollouts.md) — Updates verteilen
- [workflows/erster-client.md](workflows/erster-client.md) — Neuen Client von Grund auf aufnehmen
