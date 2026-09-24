# 9 — Einstellungen

Im Menü **Einstellungen** sind alle administrativen Bereiche gebündelt. Das Menü ist sichtbar, aber viele Aktionen sind **Admins vorbehalten** und für Operator und Viewer gesperrt: Benutzerverwaltung, Zertifikat-Upload, Factory-Reset und — seit 2026-08-31 — auch das **Starten, Stoppen und Neustarten von Diensten** im Services-Tab.

Gesperrt heißt: der Server weist die Aktion ab. Die Schaltflächen bleiben sichtbar, ein Klick ohne die nötige Rolle erzeugt eine Fehlermeldung statt einer Wirkung (siehe [Rollenübersicht](README.md#rollen-im-system)). Ausnahme: Den Reiter **Benutzer** zeigt die Ansicht nur Admins; Operator und Viewer öffnen die Einstellungen auf **Allgemein** (seit 2026-09-15).

Die Ansicht ist in Tabs aufgeteilt; diese Anleitung behandelt sie in der Reihenfolge, in der sie im Alltag relevant werden.

> **Vertiefung in eigenen Kapiteln:** Lizenz-Verwaltung → [11 — Lizenzierung](11-lizenz.md). TLS-/SSH-/Signing-Key-/Vulnerability-Scan-Details → [12 — Sicherheit](12-sicherheit-und-cve-scan.md). VPN-Setup für Homeoffice → [13 — VPN](13-vpn.md). Eigenes Profil + 2FA → [10 — Profil & 2FA](10-profil-und-2fa.md).

## Tab: Services (Dienste)

Reiter **Dienste**: Vollansicht der Docker-Container (die Dashboard-Kachel ist eine Zusammenfassung). Gruppiert nach Profil: Core, Network, Testing, Monitoring, dazu eine Gruppe **On-Demand-Container**. Ein Schalter **Auto-Aktualisierung** und **Aktualisieren** halten die Ansicht aktuell.

Pro Container:

- **Label + Container-Name** (z. B. Backend, `thinforge-backend-1`)
- **Status** — Läuft / Gestoppt / Nicht gefunden / Pausiert / Neustart
- **Health** — Gesund / Ungesund / Startet (wenn Healthcheck definiert)
- **Laufzeit**, bei gestoppten Containern Stoppzeit und Exit-Code, bei fehlenden der `docker compose`-Befehl zum Anlegen
- **Starten / Neustarten / Stoppen** — Buttons; „Starten" nur bei nicht laufenden (bei „Nicht gefunden" gesperrt), „Stoppen" immer mit Bestätigungsdialog, bei kritischen Diensten mit Warnung. **Nur für Admins** — Liste, Status und Logs stehen dagegen jeder Rolle offen

Ein **On-Demand-Badge** (grau) kennzeichnet Container, die absichtlich nur bei Bedarf laufen (`cloning-vm`, `cloner`, `multicast-sender`, `bt-seeder`). Deren Leerlauf ist kein Fehler — die Ansicht zeigt sie als neutrales Grau statt Rot.

Welche Profile die Ansicht zeigt, legt `THINFORGE_ENABLED_PROFILES` in der `.env` des Servers fest (kommagetrennt; leer = alle ausgelieferten Profile). Wer etwa auf einem Server ohne KVM das Profil `testing` ausblenden will, trägt dort eine eigene Liste ein — `rebuild.sh` und `deploy.sh` lassen einen eigenen Wert stehen und ergänzen nur, wo die Zeile fehlt oder noch einen früheren Standard trägt. Wirksam, sobald das Backend neu erzeugt wird (z. B. über `./deploy.sh`).

**Typische Aufgaben**: Hängt ein Dienst nach einem Reboot? Hier Start klicken. Will man einen Container sauber neu initialisieren? Restart.

## Sicherheit → HTTPS / TLS

Unter-Tab **HTTPS / TLS** im Reiter **Sicherheit** (siehe unten): das serverseitige HTTPS-Zertifikat. Default nach Installation: selbstsigniert für den Hostname des Servers. **„Selbstsigniertes Zertifikat erstellen"** erzeugt ein neues (Hostname oder IP-Adresse, Gültigkeit 1–3650 Tage, zusätzliche Hostnamen/IPs kommagetrennt). Die Namen dürfen keine Leer- oder Steuerzeichen, `/`, `+` oder `\` enthalten und ein einzelner Name kein Komma — sie würden im Zertifikat zusätzliche Einträge erzeugen, der Server lehnt sie ab. Platzhalter wie `*.firma.de` und IPv6-Adressen sind erlaubt.

### Zertifikat ersetzen

- **„Eigenes Zertifikat hochladen"** → Zertifikat (`.pem`/`.crt`) und privaten Schlüssel (`.pem`/`.key`) einzeln auswählen, dann **„Zertifikat hochladen"**
- Format: PEM, ungeschützt (Key ohne Passphrase — sonst hält Caddy beim Start)
- Validierung prüft, dass Zertifikat und Schlüssel zusammenpassen
- Nach Upload: Caddy wird automatisch neu geladen (~5 s Downtime für die Web-UI)

### Zertifikats-Info

Die Karte **HTTPS-Status** zeigt CN, Typ (selbstsigniert / eigenes Zertifikat), Gültigkeit, alternative Namen (SAN), Seriennummer und SHA-1-Fingerprint. Solange das Zertifikat gültig ist, werden die verbleibenden Tage angezeigt; nach Ablauf ein roter Hinweis „Abgelaufen".

## Tab: Benutzer & Rollen

Reiter **Benutzer** (nur für Admins sichtbar): Liste aller angelegten Benutzer mit E-Mail, Rolle, Aktiv-Status und Erstelldatum.

### Neuen Benutzer anlegen

- **„Benutzer anlegen"** — Benutzername, E-Mail, Passwort (mindestens 8 Zeichen), Rolle (Vorgabe Viewer). Einen Einladungs- oder Reset-Link per E-Mail gibt es nicht.

### Rollen

| Rolle | Was er darf |
|-------|-------------|
| **Admin** | Alles — Benutzerverwaltung, TLS, Signing-Keys, Factory-Reset |
| **Operator** | Clients, Cloning, Rollouts, Tasks, Remote-Desktop |
| **Viewer** | Nur lesen: Dashboard, Listen, Berichte |

### Passwort zurücksetzen

In der Zeile des Benutzers das Symbol **„Passwort zurücksetzen"**. Dialog mit neuem Passwort (≥ 8 Zeichen) + Bestätigung. Der Server setzt das Passwort direkt, schaltet eine aktive 2FA ab und beendet alle bestehenden Sitzungen des Kontos; die Person meldet sich danach mit dem neuen Passwort an.

Bei Admin-Konten und beim eigenen Konto ist das Symbol ausgegraut; auch der Server weist die Aktion dort ab. Das Passwort eines anderen Admin-Kontos setzt eine Admin-Person über **Bearbeiten** (Stift-Symbol, Feld Passwort) — mit derselben Wirkung auf 2FA und Sitzungen. Das eigene Passwort ändert jeder im Profil ([10 — Profil & 2FA](10-profil-und-2fa.md)).

Einen Reset per E-Mail-Link gibt es derzeit nicht: **Passwort vergessen** auf der Login-Seite ist noch nicht verfügbar (siehe [10 — Profil & 2FA](10-profil-und-2fa.md#passwort-vergessen)).

### TOTP zurücksetzen

Button **„2FA zurücksetzen"** erscheint nur, wenn der Benutzer 2FA aktiv hat. Bestätigungsdialog → der Seed wird gelöscht, ebenso ein angefangener, nie bestätigter Einrichtungsversuch; alle bestehenden Sitzungen des Kontos enden dabei (seit 2026-09-15). Die Person meldet sich wieder allein mit Passwort an und kann TOTP im Profil neu einrichten. Auf den **eigenen** User ist der Button deaktiviert — die eigene 2FA schaltest du im Profil ab ([10 — Profil & 2FA](10-profil-und-2fa.md)). Bei **Admin-Konten** weist der Server die Aktion ab; die 2FA eines anderen Admin-Kontos entfällt, wenn eine Admin-Person dort über **Bearbeiten** ein neues Passwort setzt (siehe oben).

### Benutzer deaktivieren / löschen

- **Deaktivieren** (Schalter **Aktiv** im Bearbeiten-Dialog) — Login gesperrt, Konto und Historie bleiben.
- **Löschen** — endgültig entfernt. Wenn der Benutzer noch Rollouts erstellt hat, bleiben diese erhalten — der Verweis auf den Ersteller entfällt dann lediglich. Auf den eigenen Account greift der Button nicht.

Am eigenen Konto lassen sich außerdem Rolle und Aktiv-Schalter nicht ändern, damit sich niemand selbst aussperrt.

## Tab: Sicherheit

Sammelt alle kryptografischen Bereiche. Sub-Tabs:

- **HTTPS / TLS** — Web-Zertifikat (Status, selbstsigniert erstellen, eigenes hochladen; siehe oben).
- **SSH-Zugang** — Server-Schlüssel (Provisioning) + Heartbeat-Token (Generieren / Rotieren / vorherige Schlüssel und Tokens).
- **Minisign-Schlüssel** — Minisign-Ed25519-Paar für Delta- und Agent-Binary-Signatur. Public-Key-Anzeige, **Key rotieren**, Zähler unsignierter Deltas mit **Alle nachsignieren**, Signaturstatus des Agent-Binarys. Beim Rotieren signiert der alte Schlüssel den neuen; die Clients übernehmen ihn automatisch per Heartbeat.
- **Vulnerability-Scan** (nur Admins) — syft + grype über alle Container-Images, Severity-Übersicht (raw vs. VEX-effective), Per-Image-CVE-Liste.
- **SBOM-Download** (nur Admins) — Download der SBOM-Artefakte pro Scan-Lauf (syft, cyclonedx, spdx).

Detaillierte Beschreibungen aller Aktionen samt Fallstricken: [12 — Sicherheit](12-sicherheit-und-cve-scan.md).

## Tab: Benachrichtigungen

Incident-Management für Client-Warnungen: Client offline, CPU, RAM oder Festplatte über dem Schwellenwert, Client-Fehler, Garantie läuft ab, Versions-Abweichung, MAC-Adresse geändert.

- **Aktive Vorfälle** — offene Vorfälle. Pro Zeile: Client, Bedingung, Details, Status, Aufgetreten, Zahl der Benachrichtigungen. **Bestätigen** (bleibt offen) oder **Lösen** (schließen mit optionalem Hinweis) — Admin oder Operator.
- **Verlauf** — geschlossene Vorfälle mit Zeitpunkt der Lösung.
- **Konfiguration** (Speichern und Testen nur für Admins):
  - **Schwellenwerte**: CPU, RAM und Festplatte in Prozent, Garantie-Vorwarnung in Tagen, „Offline nach" und Benachrichtigungs-Cooldown in Minuten.
  - **E-Mail-Kanal** (einschaltbar): SMTP-Host, -Port, -Benutzername, -Passwort, Absender-Adresse, TLS/STARTTLS, Empfänger; ein Port außerhalb 1–65535 wird beim Speichern abgewiesen. **Testen** versendet eine Testnachricht.
  - **Webhook-Kanal** (einschaltbar): URL, HTTP-Methode, Secret (Header `X-ThinForge-Secret`), weitere HTTP-Header. **Testen** schickt einen Testaufruf. Die URL muss direkt auf den Empfänger zeigen: Weiterleitungen (HTTP 3xx) werden nicht verfolgt und gelten als Fehlschlag, damit das Webhook-Geheimnis nie an einen anderen Rechner geht.

Ohne eingeschalteten Kanal werden Incidents nur in der UI sichtbar — keine Push-Benachrichtigung.

## Tab: Remote Desktop

Vorgaben für Remote-Desktop-Sitzungen, nur für Admins:

- **Standard-Qualität** — mit welcher Voreinstellung (DSL, VDSL oder LAN) eine Sitzung startet
- **Idle-Timeout** — nach so vielen Sekunden ohne Eingabe wird eine Sitzung getrennt; erlaubt sind 30 bis 86400 Sekunden (24 Stunden)
- **Max. parallele Sitzungen / Client** — erlaubt sind 1 bis 50 Sitzungen je Gerät

Neue Werte gelten ab der nächsten Sitzung. Bis zum Update vom 2026-09-23 bedeutete 0 „unbegrenzt" — wer mit 0 sperren wollte, hob die Grenze in Wahrheit auf. Heute weist das Feld 0 ab. Eine früher gespeicherte 0 zeigt die Seite als wirksamen Wert an — beim Idle-Timeout 86400 (24 Stunden), bei den Sitzungen die Vorgabe 5 —, bis du einmal speicherst.

Lassen sich die gespeicherten Werte beim Öffnen nicht abrufen (etwa während das Backend neu startet), zeigt der Reiter einen Fehlerhinweis mit dem Grund und dem Knopf **Erneut abrufen**. In den Feldern stehen dann nur Vorgabewerte (VDSL, 900 Sekunden, 5 Sitzungen). **Speichern** bleibt deshalb gesperrt, bis ein Abruf gelingt: Speichern schickt immer alle Werte auf einmal und würde die gespeicherten sonst durch die Vorgaben ersetzen.

## Tab: Lizenz

Admin-Ansicht des aktuellen Lizenzstatus + Upload (**„Hochladen und aktivieren"**) oder **„Lizenz entfernen"** eines `.7z`-Bundles. Bundles kommen vom Hersteller.

Detailbeschreibung (Zustände, VPN-Sitzplätze, Fehlercodes): [11 — Lizenzierung](11-lizenz.md).

## Tab: General (Allgemein)

Einstellungen, die woanders keinen guten Platz hatten. Der Tab hat zwei Karten, jede mit eigenem **Speichern**.

### Karte „Allgemeine Einstellungen"

- **Sitzungsdauer** — nach welcher Inaktivität eine Anmeldung abläuft (gleitendes Zeitfenster; 1 Stunde bis 30 Tage, Standard 7 Tage)
- **Aufbewahrung des Audit-Logs** — nach wie vielen Tagen Einträge des Audit-Logs gelöscht werden (Vorgabe 365, erlaubt 30 bis 3650; außerhalb davon ist **Speichern** gesperrt, und der Server weist den Wert ab). Der Worker löscht einmal täglich und bei jedem Neustart; ein Lauf, der etwas gelöscht hat, steht selbst im Audit-Log (siehe [08 — Tasks & Logs](08-tasks-logs.md#audit-log-aufbewahrung)). Ändern dürfen nur Admins. Die Aufbewahrung kam mit dem Update vom 2026-09-15 hinzu; der erste Worker-Start danach löscht sofort alle Einträge, die älter als 365 Tage sind — vorher löschte ThinForge nie etwas aus dem Audit-Log.

### Karte „Zeitserver (NTP)"

Einen eigenen Tab „NTP" gibt es nicht — die Zeitquellen und die Zeitzone stehen in dieser Karte. Chrony läuft im `network`-Profil und stellt sicher, dass der Server-Host (und daraus abgeleitet alle Clients) auf der korrekten Zeit liegen.

- **Upstream NTP-Server** — Liste von NTP-Servern (z. B. `0.pool.ntp.org`, interne Server). Mindestens einer muss eingetragen sein, sonst ist **Speichern** gesperrt.
- **Zeitzone** — die Betriebszeitzone, siehe unten.

Speichern dürfen nur Admins.

Uhr-Qualität (Stratum) oder Abweichung (Offset) zeigt die Karte nicht an. Haben sich beim Speichern die Server geändert, schreibt ThinForge die Chrony-Config neu und startet den Chrony-Container neu; eine reine Zeitzonen-Änderung lässt Chrony unberührt. Scheitert der Neustart, wird trotzdem „gespeichert" gemeldet — die neuen Server greifen dann erst nach einem Neustart von Hand (Tab Dienste, Chrony).

### Zeitzone

Zu den NTP-Einstellungen gehört die **Betriebszeitzone** (Vorgabe `Europe/Berlin`). In ihr gelten:

- Uhrzeit und Wochentage von Aufgaben-Vorlagen,
- Beginn, Ende, Wochentage und Monatstage wiederkehrender Wartungsfenster,
- die Uhrzeit geplanter Deployments (Eingabe und Anzeige),
- „heute" bei Garantie-Alarmen und die Tages- und Wochenraster der Berichte.

Eingestellt wird sie hier im Feld **Zeitzone** (IANA-Name wie `Europe/Vienna`; unbekannte Namen weist der Server beim Speichern ab). Die Geräte übernehmen die Zone mit dem nächsten Heartbeat. Die Zeitzone des Server-Wirts selbst setzt `install-deps.sh`; das Feld ändert sie nicht. Der Setup-Assistent fragt keine Zeitzone ab — nach der Einrichtung gilt `Europe/Berlin`, bis hier eine andere gewählt wird.

Zeitumstellung: Eine Vorlage um 02:30 läuft am Tag der Umstellung auf Sommerzeit um 03:00, am Tag der Umstellung auf Winterzeit genau einmal.

Bis zum Update vom 2026-09-15 rechneten Aufgaben-Vorlagen ungewollt in UTC und liefen im Sommer zwei Stunden später als eingetragen; seitdem laufen sie zur eingetragenen Ortszeit — also früher als gewohnt. Wiederkehrende Wartungsfenster verschoben sich über die Zeitumstellung um eine Stunde und lagen nachts teils am falschen Wochentag; auch sie gelten jetzt in Ortszeit.

## Backup & Restore

Backup & Restore liegt **nicht** unter Einstellungen, sondern im Bereich **Info**, Tab **Backup & Restore**. Dort erzeugst du Sicherungen des ThinForge-Zustands für Disaster-Recovery.

- **„System-Backup erstellen"** — Datenbank, Konfiguration und Schlüssel; klein, in Sekunden fertig, als Datei zum Download
- **„Daten-Backup starten"** — Clones und Deltas; läuft im Hintergrund und kann je nach Datenmenge Stunden dauern
- **„Backup wiederherstellen"** — eine oder beide Dateien wählen, Überschreiben bestätigen und mit dem eigenen Passwort freigeben. **Vorsicht**: überschreibt die laufende Installation. Nach dem Wiederherstellen eines System-Backups starten alle Geräte wieder lokal; Deployments, Aufnahmen und Rollouts, die zum Zeitpunkt der Sicherung liefen oder geplant waren, werden dabei beendet (Hinweis „durch Wiederherstellung ungueltig" am Gerät) und müssen bei Bedarf neu angestoßen werden.

Automatische, zeitgesteuerte Backups gibt es nicht — jede Sicherung entsteht auf Knopfdruck, und abgelegte Dateien räumt ThinForge nicht selbst weg.

## Tab: Werkeinstellungen

Reißt den gesamten ThinForge-Zustand ab: Postgres-Tabellen (auch alle Benutzerkonten), Redis, Storage-Dir, Secrets. **Nicht rückgängig zu machen.** Erforderlich sind das Kontrollkästchen, das eigene Passwort und ein Bestätigungsdialog; danach führt der Setup-Assistent durch die Neueinrichtung.

Einsatzfall: Test-Server zurück auf Auslieferungszustand, bevor dieser ausgeliefert wird.

## Nächste Schritte

- [08 — Tasks & Logs](08-tasks-logs.md) — wenn Einstellungs-Änderungen nicht so wirken wie erwartet
- [workflows/golden-image.md](workflows/golden-image.md) — nach Zertifikats-Erneuerung die Cloning-VM neu starten, damit die Tools-ISO neu gebaut wird
