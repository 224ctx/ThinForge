# 9 — Einstellungen

Im Menü **Einstellungen** sind alle administrativen Bereiche gebündelt. Die meisten sind **Admin-only** — Operator und Viewer sehen sie nicht.

Die Ansicht ist in Tabs aufgeteilt; diese Anleitung behandelt sie in der Reihenfolge, in der sie im Alltag relevant werden.

> **Vertiefung in eigenen Kapiteln:** Lizenz-Verwaltung → [11 — Lizenzierung](11-lizenz.md). TLS-/SSH-/Signing-Key-/Vulnerability-Scan-Details → [12 — Sicherheit](12-sicherheit-und-cve-scan.md). VPN-Setup für Homeoffice → [13 — VPN](13-vpn.md). Eigenes Profil + 2FA → [10 — Profil & 2FA](10-profil-und-2fa.md).

## Tab: Services (Dienste)

Vollansicht der Docker-Container (die Dashboard-Kachel ist eine Zusammenfassung). Gruppiert nach Profil: Core, Network, Monitoring, Testing.

Pro Container:

- **Label + Container-Name** (z. B. Backend, `thinforge-backend-1`)
- **Status** — running / exited / not_found / paused / restarting
- **Health** — healthy / unhealthy / starting (wenn Healthcheck definiert)
- **Uptime** oder letzte Laufzeit
- **Start / Stop / Restart** — Buttons; „Start" nur wenn möglich, „Stop" mit Bestätigungsdialog bei kritischen Diensten

Ein **On-Demand-Badge** (grau) kennzeichnet Container, die absichtlich nur bei Bedarf laufen (`cloning-vm`, `cloner`). Deren Leerlauf ist kein Fehler — die Ansicht zeigt sie als neutrales Grau statt Rot.

**Typische Aufgaben**: Hängt ein Dienst nach einem Reboot? Hier Start klicken. Will man einen Container sauber neu initialisieren? Restart.

## Tab: TLS

Das serverseitige HTTPS-Zertifikat. Default nach Installation: selbstsigniert für den Hostname des Servers.

### Zertifikat ersetzen

- **„Hochladen"** → `.crt` und `.key` einzeln auswählen
- Format: PEM, ungeschützt (Key ohne Passphrase — sonst hält Caddy beim Start)
- Validierung prüft CN / Subject Alt Names passend zum Server-Hostname
- Nach Upload: Caddy wird automatisch neu geladen (~5 s Downtime für die Web-UI)

### Zertifikats-Info

Zeigt CN, Aussteller, Gültigkeit (From/To). Bei Ablauf < 30 Tagen erscheint ein gelber Hinweis; < 7 Tage rot.

## Tab: Benutzer & Rollen

Liste aller angelegten Benutzer mit Rolle, letztem Login, Status.

### Neuen Benutzer anlegen

- **„+ Benutzer"** — E-Mail, Anzeigename, Passwort (oder Reset-Link per E-Mail), Rolle

### Rollen

| Rolle | Was er darf |
|-------|-------------|
| **Admin** | Alles — Benutzerverwaltung, TLS, Signing-Keys, Factory-Reset |
| **Operator** | Clients, Cloning, Rollouts, Tasks, Remote-Desktop |
| **Viewer** | Nur lesen: Dashboard, Clients-Liste |

### Passwort zurücksetzen

Auf einem Benutzer per Menü → **„Passwort zurücksetzen"**. Dialog mit neuem Passwort (≥ 8 Zeichen) + Bestätigung. Schreibt den Wert direkt; der betroffene User muss sich beim nächsten Login umstellen.

Ein Reset per E-Mail-Link ist **nicht** diese Aktion — das macht der Benutzer selbst über **Passwort vergessen** auf der Login-Seite (benötigt SMTP-Konfig).

### TOTP zurücksetzen

Button erscheint nur, wenn der Benutzer 2FA aktiv hat. Confirm-Dialog → Seed wird gelöscht. Beim nächsten Login kann der User TOTP neu einrichten (ohne 2FA-Abfrage). Auf den **eigenen** User ist der Button deaktiviert — nutze dann einen zweiten Admin-Account oder Factory-Reset.

### Benutzer deaktivieren / löschen

- **Deaktivieren** (Switch `is_active` im Edit-Dialog) — Login gesperrt, Konto und Historie bleiben.
- **Löschen** — endgültig entfernt. Wenn der Benutzer noch Rollouts erstellt hat, bleiben diese historisch sichtbar mit „(gelöschter Benutzer)". Auf den eigenen Account greift der Button nicht.

## Tab: Sicherheit

Sammelt alle kryptografischen Bereiche. Sub-Tabs:

- **TLS** — Web-Zertifikat (selbstsigniert generieren / CA-Cert hochladen / entfernen).
- **SSH** — Server-SSH-Key (Provisioning) + Heartbeat-Token (Generieren / Rotieren / History).
- **Signing-Key** — Minisign-Ed25519-Paar für Delta- und Agent-Binary-Signatur. Public-Key-Anzeige, Rotate-Button, „Unsigned Delta"-Zähler mit **Jetzt signieren**.
- **Vulnerability-Scan** — syft + grype über alle Container-Images, Severity-Übersicht (raw vs. VEX-effective), Per-Image-CVE-Liste.
- **SBOMs** — Download der SBOM-Artefakte pro Scan-Lauf (syft, cyclonedx, spdx).

Detaillierte Beschreibungen aller Aktionen samt Fallstricken: [12 — Sicherheit](12-sicherheit-und-cve-scan.md).

## Tab: Alerts

Incident-Management für betriebliche Warnungen (Container-Ausfall, Disk voll, Heartbeat-Lücken, CVE-Neuheiten).

- **Active** — offene Vorfälle. Pro Zeile: Condition, Status, Timestamp, Message. **Acknowledge** (bestätigen, bleibt offen) oder **Resolve** (schließen mit optionalem Kommentar).
- **History** — geschlossene Incidents mit Auflösungsnote.
- **Config**:
  - **E-Mail-Kanal**: SMTP-Host/-Port/-From/-Auth. Test-Button versendet eine Musternachricht.
  - **Webhook-Kanal**: URL + Header. Test-Button prüft Erreichbarkeit.
  - **Schwellenwerte**: Warning/Critical-Level pro überwachter Metrik.

Ohne konfigurierten Kanal werden Incidents nur in der UI sichtbar — keine Push-Benachrichtigung.

## Tab: Lizenz

Admin-Ansicht des aktuellen Lizenzstatus + Upload/Remove eines `.7z`-Bundles. Bundles kommen vom Hersteller.

Detailbeschreibung (Zustände, Fehlercodes, Soft-Limit, `is_lager`-Semantik): [11 — Lizenzierung](11-lizenz.md).

## Tab: NTP

Einstellung der Chrony-Upstream-Server. Chrony läuft im `network`-Profil und stellt sicher, dass der Server-Host (und daraus abgeleitet alle Clients) auf der korrekten Zeit liegen.

- **Upstream-Server** — Liste von NTP-Servern (z. B. `pool.ntp.org`, interne Server)
- **Stratum-Info** — aktuelle Uhr-Qualität
- **Offset** — wie weit Server-Zeit von Referenz abweicht

Beim Speichern werden die Änderungen atomar in die Chrony-Config geschrieben und per SIGHUP reloaded — kein Container-Restart nötig.

## Tab: General (Allgemein)

Einstellungen, die woanders keinen guten Platz hatten:

- **Automatische Agent-Updates** — bei Heartbeat prüft Agent auf neue Version und installiert (an/aus)
- **Heartbeat-Intervall** — Default 60 s; kürzer = reaktiver aber mehr Traffic
- **Logs-Aufbewahrung** — wie viele Tage Log-Historie vorhalten
- **Branding** — Login-Seiten-Logo austauschen (Datei-Upload, PNG/SVG)

## Tab: Backup & Restore

Erzeugt einen Snapshot des ThinForge-Zustands (Postgres-Dump + Secrets + Konfig-Dateien) für Disaster-Recovery.

- **„Backup jetzt"** — speichert als `.tar.gz` in `/data/backups` (und zum Download anbieten)
- **„Restore aus Datei"** — hochladen, bestätigen. **Vorsicht**: überschreibt die laufende DB.
- **Automatische Backups** — Cron-Zeitplan konfigurierbar

## Tab: Factory-Reset

Reißt den gesamten ThinForge-Zustand ab: Postgres-Tabellen, Redis, Storage-Dir, Secrets. **Nicht rückgängig zu machen.** Doppelte Bestätigung erforderlich.

Einsatzfall: Test-Server zurück auf Auslieferungszustand, bevor dieser an Kunden geht.

## Nächste Schritte

- [08 — Tasks & Logs](08-tasks-logs.md) — wenn Einstellungs-Änderungen nicht so wirken wie erwartet
- [workflows/golden-image.md](workflows/golden-image.md) — nach Zertifikats-Erneuerung muss oft die Tools-ISO neu gebaut werden
