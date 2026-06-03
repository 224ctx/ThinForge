# Workflow: Setup-Wizard — Erst-Installation des Servers

Beim allerersten Aufruf einer frischen ThinForge-Installation leitet der Router-Guard automatisch auf `/setup` um. Dort führt ein Stepper durch alle Pflichtangaben. Dieses Dokument beschreibt die Schritte in der Reihenfolge, in der sie tatsächlich erscheinen — mit allen Validierungs-Regeln und den typischen Stolpersteinen.

## Vorbereitung

Bevor du den Wizard startest:

- Server-Host hat eine feste IP (Management-Interface).
- Zugriff über HTTPS auf den Server-FQDN ist grundsätzlich möglich (Selfsigned ist okay — wird im Wizard ersetzt).
- Falls du eine alte Installation **teilweise wiederherstellen** willst: Backup-Datei parat (`.tar.gz`, wurde über das Backup-Panel erzeugt).

## Schritt 0: Restore-Entscheidung

Zwei Kacheln:

- **Fresh Setup** — alles neu aufsetzen.
- **Partial Restore** — eine Teilmenge aus einem vorhandenen Backup einspielen (z. B. nur Benutzer + Secrets + Clients, Images und Clones bleiben dort, wo sie sind).

Bei Partial Restore: Datei-Upload → Validierung (`POST /setup/validate-backup`) → Passwort → **Restore**. Nach Erfolg übernimmt der Wizard Default-Werte aus dem Backup und du navigierst direkt zu Schritt 7 (Review).

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

Daraus baut der Wizard später den FQDN für das TLS-Zertifikat in Schritt 6.

## Schritt 3: Netzwerk / DHCP

Die wichtigste Seite. Zwei logische Interfaces:

- **Management-Interface** — Traffic zu und vom Admin-Browser (meist das LAN-Interface des Servers).
- **Rollout-Interface** — das Netz, in dem die Thin-Clients stehen (kann identisch mit dem Management-Interface sein oder ein dediziertes Clone-VLAN).

Wenn beide identisch sind, reicht es, sie beim Management anzugeben und beim Rollout dasselbe auszuwählen.

| Feld | Regel |
|---|---|
| Management-Interface | Pflicht, Vorschlag aus `GET /setup/network-defaults` |
| Management-DNS | Optional — Upstream-DNS für den Server |
| Rollout-Interface | Pflicht |
| Rollout-IP | Optional — feste IP des Rollout-Interfaces; leer lassen, wenn per DHCP |
| Rollout-CIDR | 1–32 |
| DHCP-Modus | `server` (ThinForge-dnsmasq ist DHCP) oder `proxy` (es gibt bereits einen DHCP, ThinForge liefert nur PXE-Optionen) |

Je nach Modus:

- **Server-Modus:** Range-Start, Range-End, Netmask, Gateway, DNS-Server.
- **Proxy-Modus:** Subnetz des bestehenden DHCPs.

## Schritt 4: NTP

Zeit-Synchronisation ist Pflicht — sonst klappen signierte Tokens und Delta-Signaturen später nicht zuverlässig.

- **NTP aktivieren** (Switch).
- **Upstream-Server** (Primary + Secondary) — werden mit dem Management-Gateway vorausgefüllt; überschreiben, wenn ein anderer Firmen-NTP vorliegt.
- **Client-Server** (Primary + Secondary) — werden mit der Rollout-IP vorausgefüllt, damit Thin-Clients den ThinForge-Server als NTP-Quelle nutzen.

Fertige Installationen ohne Außenkontakt deaktivieren den Switch und versorgen Clients manuell mit Zeit.

## Optional: Signing-Key generieren

Wenn du frisch startest, ist dieser Schritt sinnvoll. Der Wizard erzeugt ein minisign-Ed25519-Paar und bettet den öffentlichen Schlüssel in die Tools-ISO ein. Ohne Key können später keine signierten Delta-Updates verteilt werden.

Wer den Schritt überspringt, kann den Key jederzeit unter **Einstellungen → Sicherheit → Signing-Key** nachträglich erzeugen (siehe [12 — Sicherheit](12-sicherheit-und-cve-scan.md)).

## Schritt 6: TLS-Zertifikat

| Feld | Regel |
|---|---|
| Common Name | Pflicht, vorbelegt mit FQDN aus Schritt 2 |
| Gültigkeit in Tagen | 30–3650, default 365 |
| SAN-Namen | Kommagetrennt; vorbelegt mit FQDN + Hostname + Server-IPs |

Der Wizard erzeugt ein selbstsigniertes Zertifikat. Nach Abschluss des Setups kannst du es jederzeit unter **Einstellungen → Sicherheit → TLS** durch ein CA-signiertes ersetzen.

## Schritt 7: Review & Complete

Read-only-Tabelle mit allen Eingaben. Nochmal durchlesen, dann **Abschließen**.

Was passiert hinter den Kulissen:

1. `POST /setup/complete` mit allen Configs.
2. Backend: Admin-User wird angelegt, Signing-Key (wenn gewählt) generiert, TLS-Zertifikat erzeugt, dnsmasq-Config geschrieben, NTP konfiguriert, Tools-ISO neu gebaut.
3. Frontend zählt 10 Sekunden herunter (damit Caddy den neuen Cert picken kann) und leitet dann auf `https://<fqdn>/login` um.

## Beim ersten Login

- Mit dem Admin-User aus Schritt 1 anmelden.
- Das Browser-Zertifikat ist selbstsigniert → Ausnahme hinzufügen oder CA-signiertes Zertifikat hochladen.
- Empfehlung: sofort TOTP aktivieren ([10 — Profil & 2FA](../10-profil-und-2fa.md)).

## Troubleshooting

- **`POST /setup/complete` scheitert mit 500** → Server-Log prüfen (`docker compose logs backend`). Häufige Ursache: DHCP-Range außerhalb des angegebenen Subnetzes.
- **Redirect zu `/login` kommt nie** → Caddy-Zertifikat steht noch nicht; nach 30 s manuell `https://<fqdn>/login` aufrufen.
- **Aktuelle Installation soll zurückgesetzt werden** → nicht über den Wizard, sondern **Einstellungen → Factory-Reset**. Der Wizard ist nur für frische Installationen oder Partial-Restores gedacht.

## Nächste Schritte

- [01 — Erste Schritte](../01-erste-schritte.md) für die Tour durchs frische Dashboard.
- [workflows/erster-client.md](erster-client.md) um direkt einen Client aufzunehmen.
- [12 — Sicherheit](../12-sicherheit-und-cve-scan.md) für Signing-Key, TLS-Austausch und den initialen CVE-Scan.
