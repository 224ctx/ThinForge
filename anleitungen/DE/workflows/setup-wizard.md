# Workflow: Setup-Wizard — Erst-Installation des Servers

Beim allerersten Aufruf einer frischen ThinForge-Installation leitet der Router-Guard automatisch auf `/setup` um. Dort führt ein Stepper durch alle Pflichtangaben. Dieses Dokument beschreibt die Schritte in der Reihenfolge, in der sie tatsächlich erscheinen — mit allen Validierungs-Regeln und den typischen Stolpersteinen.

## Vorbereitung

Bevor du den Wizard startest:

- Server-Host hat eine feste IP (Management-Interface).
- Zugriff über HTTPS auf den Server-FQDN ist grundsätzlich möglich (Selfsigned ist okay — wird im Wizard ersetzt).

## Wiederherstellen (entfallen)

Einen Restore-Schritt hat der Wizard nicht mehr — er richtet immer frisch ein, und die früheren Endpunkte (`/setup/validate-backup`, `/setup/restore`, `/setup/partial-restore`) gibt es nicht mehr. Eine Sicherung spielst du nach dem Setup unter **Info & Backup → Backup & Restore** ein. Wer `/setup` nach abgeschlossener Einrichtung aufruft, landet mit einem Hinweis auf dem Dashboard.

## Schritt 1: Admin-Account

| Feld | Regel |
|---|---|
| Benutzername | Pflicht, mindestens 3 Zeichen |
| E-Mail | Pflicht, RFC-Format |
| Passwort | Pflicht, mindestens 8 Zeichen |
| Passwort bestätigen | Muss exakt übereinstimmen |

Der Admin-Account hat volle Rechte. Zusätzliche Benutzer (Operator, Viewer) legst du später unter **Einstellungen → Benutzer** an.

Im Hintergrund lädt der Wizard bereits Interface-Vorschläge für Schritt 3 (`GET /setup/network-defaults`), damit die Auswahl dort schneller geht.

## Schritt 2: Server-Identität

| Feld | Regel |
|---|---|
| Hostname | Pflicht — z. B. `thinforge` |
| Domain | Pflicht — z. B. `thinforge.local`, `firma.de` |

Daraus baut der Wizard später den FQDN für das TLS-Zertifikat in Schritt 5.

## Schritt 3: Netzwerk / DHCP

Die wichtigste Seite. Zwei logische Interfaces:

- **Management-Interface** — Traffic zu und vom Admin-Browser (meist das LAN-Interface des Servers).
- **Rollout-Interface** — das Netz, in dem die Thin-Clients stehen (kann identisch mit dem Management-Interface sein oder ein dediziertes Clone-VLAN).

Wenn beide identisch sind, reicht es, sie beim Management anzugeben und beim Rollout dasselbe auszuwählen.

| Feld | Regel |
|---|---|
| Management-Interface | Auswahl aus den Interfaces mit Adresse, Vorschlag aus `GET /setup/network-defaults`; dient zum Vorbelegen des Upstream-DNS |
| Management-DNS | Optional — Upstream-DNS für den Server |
| Rollout-Interface | Auswahl aus allen physischen Netzkarten; eine andere weist der Abschluss ab |
| Rollout-IP | Feste IP des Rollout-Interfaces. Leer lassen geht nur, wenn das Interface schon eine IPv4-Adresse trägt — sonst lehnt der Abschluss ab. Aus IP und CIDR rechnet der Wizard IP-Bereich (Netzadresse + 10 bis Broadcast − 1; ab /29 bleibt er leer, siehe Server-Modus unten), Netzmaske, Gateway und DNS-Server vor |
| Rollout-CIDR | 1–32 |
| DHCP-Modus | `server` (ThinForge-dnsmasq ist DHCP) oder `proxy` (es gibt bereits einen DHCP, ThinForge liefert nur PXE-Optionen) |

Je nach Modus:

- **Server-Modus:** Range-Start, Range-End, Netmask, Lease-Zeit (Pflicht, Vorgabe `2h`), Netzwerkinterface, Gateway, zwei DNS-Server, Domain. Den Bereich schlägt der Wizard aus Rollout-IP und CIDR vor (siehe Tabelle); in Netzen ab /29 ist dafür kein Platz, die Felder bleiben dann leer und müssen von Hand gefüllt werden. **Weiter** geht es nur, wenn Start und Ende im Rollout-Netz liegen und der Start nicht hinter dem Ende steht.
- **Proxy-Modus:** Subnetz des bestehenden DHCPs, Netzwerkinterface.

In beiden Modi bekommen nur registrierte Clients eine Antwort (MAC-Filter).

## Schritt 4: NTP

Zeit-Synchronisation ist Pflicht — sonst klappen signierte Tokens und Delta-Signaturen später nicht zuverlässig.

- **NTP aktivieren** (Switch).
- **Upstream-Server** (1 Pflicht, 2 optional) — Server 1 wird mit dem Standard-Gateway des Servers vorausgefüllt; überschreiben, wenn ein anderer Firmen-NTP vorliegt.
- **NTP-Server für Clients** (Pflicht) — wird mit der Rollout-IP vorausgefüllt (sonst steht dort `0.pool.ntp.org`), damit Thin-Clients den ThinForge-Server als NTP-Quelle nutzen; die Clients bekommen ihn per DHCP.

Fertige Installationen ohne Außenkontakt deaktivieren den Switch und versorgen Clients manuell mit Zeit.

Eine **Zeitzone** fragt der Wizard nicht ab: nach dem Abschluss gilt die Vorgabe `Europe/Berlin`. In dieser Betriebszeitzone rechnen Aufgaben-Vorlagen, Wartungsfenster, geplante Deployments und die Tagesgrenzen der Berichte. Eine andere Zone stellst du danach unter **Einstellungen → Allgemein**, Karte **Zeitserver (NTP)** ein ([09 — Einstellungen → Zeitzone](../09-einstellungen.md#zeitzone)).

## Signing-Key (automatisch)

Einen eigenen Schritt dafür gibt es nicht: beim Abschluss erzeugt der Wizard das minisign-Ed25519-Paar selbst und signiert danach im Hintergrund alle signierbaren Artefakte mit diesem Schlüssel neu — auch ein schon vorhandenes Agent-Binary. Ohne Key können später keine signierten Delta-Updates verteilt werden.

Auf die Tools-ISO kommt der öffentliche Schlüssel erst beim ersten Start der Cloning-VM. Dieser ISO-Bau verlangt ein Agent-Binary, das zu genau diesem Schlüssel passend signiert ist; fehlt es, startet die VM nicht, und die Meldung nennt den Schritt (unter **Clients → Agent** bauen bzw. signieren).

Scheitert die Erzeugung des Keys, zeigt der Abschluss eine Warnung; den Key erzeugst du dann unter **Einstellungen → Sicherheit → Signing-Key** (siehe [12 — Sicherheit](../12-sicherheit-und-cve-scan.md)).

## Schritt 5: HTTPS / TLS

| Feld | Regel |
|---|---|
| Common Name | Pflicht, vorbelegt mit FQDN aus Schritt 2; ein DNS-Name wie die SAN-Namen (Buchstaben, Ziffern, `-`, `_` je Label, keine Platzhalter) |
| Gültigkeit in Tagen | 30–3650, default 365 |
| SAN-Namen | Kommagetrennt; vorbelegt mit FQDN + Hostname + erkannten Server-IPs + Rollout-IP + `localhost`; Platzhalter wie `*.firma.de` weist der Abschluss ab |

Der Wizard erzeugt ein selbstsigniertes Zertifikat. Nach Abschluss des Setups kannst du es jederzeit unter **Einstellungen → Sicherheit → TLS** durch ein CA-signiertes ersetzen.

## Schritt 6: Zusammenfassung

Read-only-Tabelle mit allen Eingaben. Nochmal durchlesen, dann **Abschließen**.

Was passiert hinter den Kulissen:

1. `POST /setup/complete` mit allen Configs. Das Backend prüft zuerst alle Eingaben und meldet sämtliche Beanstandungen auf einmal (400), bevor es irgendetwas schreibt.
2. Backend: Admin-User wird angelegt, TLS-Zertifikat erzeugt, dnsmasq-Config geschrieben, NTP konfiguriert, Heartbeat-Token, SSH- und Signing-Key erzeugt (danach im Hintergrund alle Artefakte mit dem neuen Key signiert). Anschließend startet es Caddy, Worker und Backend neu. Eine Tools-ISO baut der Wizard **nicht** — das geschieht erst beim ersten Start der Cloning-VM.
3. Frontend zählt 15 Sekunden herunter (damit Caddy den neuen Cert picken kann) und leitet dann auf `https://<adresse>/login` um — dieselbe Adresse, unter der du den Wizard aufgerufen hast. Scheitert ein nicht kritischer Teilschritt (etwa dnsmasq-Reload, Zertifikat oder ein Schlüssel), zeigt der Wizard stattdessen die Warnungen und den Knopf **„Weiter zur Anmeldung"**; die Punkte lassen sich nach der Anmeldung in den Einstellungen nachholen.

## Beim ersten Login

- Mit dem Admin-User aus Schritt 1 anmelden.
- Das Browser-Zertifikat ist selbstsigniert → Ausnahme hinzufügen oder CA-signiertes Zertifikat hochladen.
- Empfehlung: sofort TOTP aktivieren ([10 — Profil & 2FA](../10-profil-und-2fa.md)).

## Troubleshooting

- **`POST /setup/complete` scheitert mit 400** → Die Meldung nennt alle beanstandeten Felder. Häufig: Rollout-IP leer, obwohl das Rollout-Interface noch keine IPv4-Adresse hat; ein Interface, das keine physische Netzkarte des Servers ist; eine ungültige IPv4-Angabe.
- **`POST /setup/complete` scheitert mit 500** → Server-Log prüfen (`docker compose logs backend`).
- **Redirect zu `/login` kommt nie** → Caddy-Zertifikat steht noch nicht; nach 30 s manuell `https://<fqdn>/login` aufrufen. Bei Warnungen leitet der Wizard ohnehin nicht selbst weiter — dann **„Weiter zur Anmeldung"** klicken.
- **Aktuelle Installation soll zurückgesetzt werden** → nicht über den Wizard, sondern **Einstellungen → Werkeinstellungen** (Factory-Reset); danach erscheint der Wizard wieder. Der Wizard ist nur für frische Installationen gedacht.

## Nächste Schritte

- [01 — Erste Schritte](../01-erste-schritte.md) für die Tour durchs frische Dashboard.
- [workflows/erster-client.md](erster-client.md) um direkt einen Client aufzunehmen.
- [12 — Sicherheit](../12-sicherheit-und-cve-scan.md) für Signing-Key, TLS-Austausch und den initialen CVE-Scan.
